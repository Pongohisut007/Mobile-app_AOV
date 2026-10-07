import {
  BadRequestException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { AppCacheService } from '../cache/app-cache.service';
import { CacheNamespace } from '../cache/app-cache.module';
import { InjectRepository } from '@nestjs/typeorm';
import { In, QueryFailedError, Repository, SelectQueryBuilder } from 'typeorm';
import { CartItem } from '../cart/entities/cart-item.entity';
import { Category } from '../categories/entities/category.entity';
import { PaginatedResult, toPaginated } from '../common/pagination';
import { Favorite } from '../favorites/entities/favorite.entity';
import { RecipeAccessService } from '../recipe-access/recipe-access.service';
import { RecipeComment } from '../recipe-comments/entities/recipe-comment.entity';
import { Review, ReviewStatus } from '../reviews/entities/review.entity';
import type { AuthUser } from '../auth/interfaces/jwt-payload.interface';
import { UserRole, UserStatus } from '../users/entities/user.entity';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { RecipeSort } from './dto/list-recipes-query.dto';
import { SearchRecipesDto } from './dto/search-recipes.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { RecipeContent } from './entities/recipe-content.entity';
import { RecipeSection } from './entities/recipe-section.entity';
import { Recipe, RecipeStatus, RecipeType } from './entities/recipe.entity';
import { assertCanManageRecipe } from './recipe-permissions';
import {
  hideIngredientAmounts,
  replaceRecipeIngredients,
} from './recipe-ingredients';
import { MediaSigner } from '../uploads/media-signer.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/entities/notification.entity';

const FOREIGN_KEY_VIOLATION = '23503';

function isForeignKeyViolation(error: unknown): boolean {
  return (
    error instanceof QueryFailedError &&
    (error.driverError as { code?: string })?.code === FOREIGN_KEY_VIOLATION
  );
}

export interface FindRecipesOptions {
  search?: string;
  category?: string;
  categoryId?: string;
  creatorId?: string;
  status?: RecipeStatus;
  type?: RecipeType;
}

//system search
export type { PaginatedResult };

// กัน % _ \ ในคำค้นหาไม่ให้กลายเป็น wildcard ของ LIKE
function escapeLikeTerm(term: string): string {
  return term.replace(/[\\%_]/g, (char) => `\\${char}`);
}

@Injectable()
export class RecipesService {
  constructor(
    @InjectRepository(Recipe)
    private readonly recipeRepository: Repository<Recipe>,

    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,

    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,

    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,

    @InjectRepository(RecipeComment)
    private readonly commentRepository: Repository<RecipeComment>,

    private readonly recipeAccessService: RecipeAccessService,

    @Optional()
    private readonly cache?: AppCacheService,

    @Optional()
    private readonly mediaSigner?: MediaSigner,

    @Optional()
    private readonly notifications?: NotificationsService,
  ) {}

  // อายุ cache: รายการสั้นไว้ก่อน เพราะยอดหัวใจ/คอมเมนต์เปลี่ยนบ่อย
  // (ทุกการแก้ไขที่เกี่ยวข้องล้าง cache ทันทีอยู่แล้ว TTL เป็นแค่ตัวกันพลาด)
  private static readonly listTtlSeconds = 60;
  private static readonly detailTtlSeconds = 120;

  findAll(options: FindRecipesOptions = {}): Promise<Recipe[]> {
    return this.cached(
      stableKey('all', options),
      RecipesService.listTtlSeconds,
      () => this.loadAll(options),
    );
  }

  private async loadAll(options: FindRecipesOptions): Promise<Recipe[]> {
    const query = this.recipeRepository
      .createQueryBuilder('recipe')
      .leftJoinAndSelect('recipe.creator', 'creator')
      .leftJoinAndSelect('recipe.categories', 'category')
      .orderBy('recipe.createdAt', 'DESC');

    //system search
    this.applyFilters(query, options);

    return this.attachRecipeCounts(await query.getMany());
  }

  // น้ำหนักของค่าเฉลี่ยทั้งระบบตอนจัดอันดับตามคะแนน
  // = นับเหมือนทุกสูตรมีรีวิวคะแนนกลางๆ ติดตัวอยู่ 5 อัน
  // สูตรที่ได้ 5 ดาวแค่ 1 รีวิวจะได้ไม่แซงสูตรที่ได้ 4.8 จาก 50 รีวิว
  private static readonly ratingPriorWeight = 5;

  // เหมือน findAll แต่แบ่งหน้า ค่าเริ่มต้นเรียงจากเผยแพร่ล่าสุด (ฉบับร่างใช้วันที่สร้าง)
  findPage(
    options: FindRecipesOptions,
    page: number,
    limit: number,
    sort: RecipeSort = RecipeSort.LATEST,
  ): Promise<PaginatedResult<Recipe>> {
    return this.cached(
      stableKey('page', { ...options, page, limit, sort }),
      RecipesService.listTtlSeconds,
      () => this.loadPage(options, page, limit, sort),
    );
  }

  private async loadPage(
    options: FindRecipesOptions,
    page: number,
    limit: number,
    sort: RecipeSort,
  ): Promise<PaginatedResult<Recipe>> {
    // หา id ของหน้านี้ก่อน แล้วค่อยโหลด relation
    // เพราะถ้า limit บน query ที่ join categories แถวจะถูกนับซ้ำ
    const idQuery = this.recipeRepository.createQueryBuilder('recipe');
    this.applyFilters(idQuery, options);

    const total = await idQuery.getCount();
    if (total === 0) return toPaginated([], total, page, limit);

    idQuery
      .select('recipe.id', 'id')
      .addSelect('COALESCE(recipe.published_at, recipe.created_at)', 'sort_at');
    if (sort === RecipeSort.RATING) {
      this.orderByRating(idQuery);
    } else {
      idQuery.orderBy('sort_at', 'DESC');
    }

    const rows = await idQuery
      // วันที่เท่ากันต้องเรียงคงที่ ไม่งั้นข้ามหน้าแล้วสูตรซ้ำ/หาย
      .addOrderBy('recipe.id', 'ASC')
      .offset((page - 1) * limit)
      .limit(limit)
      .getRawMany<{ id: string }>();

    const ids = rows.map((row) => row.id);
    const recipes = await this.recipeRepository.find({
      where: { id: In(ids) },
      relations: { creator: true, categories: true },
    });

    // find() ไม่การันตีลำดับ จึงเรียงกลับตามลำดับที่หามาได้
    const byId = new Map(recipes.map((recipe) => [recipe.id, recipe]));
    const data = ids
      .map((id) => byId.get(id))
      .filter((recipe): recipe is Recipe => recipe !== undefined);

    return toPaginated(await this.attachRecipeCounts(data), total, page, limit);
  }

  // ค้นหาตามชื่ออาหาร พร้อมแบ่งหน้าและเรียงตามความใกล้เคียง
  search(dto: SearchRecipesDto): Promise<PaginatedResult<Recipe>> {
    return this.cached(
      stableKey('search', { ...dto }),
      RecipesService.listTtlSeconds,
      () => this.loadSearch(dto),
    );
  }

  private async loadSearch(
    dto: SearchRecipesDto,
  ): Promise<PaginatedResult<Recipe>> {
    const { q, page, limit, ...filters } = dto;

    // แยกเป็น 2 ขั้น: หา id ที่ตรงก่อน แล้วค่อยโหลด relation
    // เพราะถ้า limit ตรงๆ บน query ที่ join categories แถวจะถูกนับซ้ำ
    const idQuery = this.recipeRepository.createQueryBuilder('recipe');
    this.applyFilters(idQuery, { ...filters, search: q });

    const total = await idQuery.getCount();
    if (total === 0) return toPaginated([], total, page, limit);

    const term = escapeLikeTerm(q);
    const rows = await idQuery
      .select('recipe.id', 'id')
      // ชื่อตรงเป๊ะมาก่อน ตามด้วยชื่อที่ขึ้นต้นด้วยคำค้นหา แล้วค่อยที่เหลือ
      .addSelect(
        `CASE
           WHEN recipe.title ILIKE :exactTerm ESCAPE '\\'
             OR recipe.titleEn ILIKE :exactTerm ESCAPE '\\' THEN 0
           WHEN recipe.title ILIKE :prefixTerm ESCAPE '\\'
             OR recipe.titleEn ILIKE :prefixTerm ESCAPE '\\' THEN 1
           ELSE 2
         END`,
        'relevance',
      )
      .setParameters({ exactTerm: term, prefixTerm: `${term}%` })
      .orderBy('relevance', 'ASC')
      .addOrderBy('recipe.title', 'ASC')
      .addOrderBy('recipe.createdAt', 'DESC')
      .offset((page - 1) * limit)
      .limit(limit)
      .getRawMany<{ id: string }>();

    const ids = rows.map((row) => row.id);
    const recipes = await this.recipeRepository.find({
      where: { id: In(ids) },
      relations: { creator: true, categories: true },
    });

    // find() ไม่การันตีลำดับ จึงเรียงกลับตามลำดับความใกล้เคียงที่หามาได้
    const byId = new Map(recipes.map((recipe) => [recipe.id, recipe]));
    const data = ids
      .map((id) => byId.get(id))
      .filter((recipe): recipe is Recipe => recipe !== undefined);

    return toPaginated(await this.attachRecipeCounts(data), total, page, limit);
  }

  // Bayesian average: (C × ค่าเฉลี่ยทั้งระบบ + ผลรวมดาว) / (C + จำนวนรีวิว)
  // สูตรที่ยังไม่มีรีวิวไปต่อท้าย เรียงกันเองตามวันที่เผยแพร่ล่าสุด
  private orderByRating(query: SelectQueryBuilder<Recipe>): void {
    const weight = RecipesService.ratingPriorWeight;
    const recipeReviews = `FROM reviews rv
      WHERE rv.recipe_id = recipe.id AND rv.status = :publishedReview`;
    query
      .addSelect(`EXISTS (SELECT 1 ${recipeReviews})`, 'has_reviews')
      .addSelect(
        `(SELECT (${weight} * COALESCE(
             (SELECT AVG(g.rating) FROM reviews g WHERE g.status = :publishedReview),
             3
           ) + COALESCE(SUM(rv.rating), 0)) / (${weight} + COUNT(rv.id))
          ${recipeReviews})`,
        'rating_score',
      )
      .setParameters({ publishedReview: ReviewStatus.PUBLISHED })
      .orderBy('has_reviews', 'DESC')
      .addOrderBy('rating_score', 'DESC')
      .addOrderBy('sort_at', 'DESC');
  }

  private applyFilters(
    query: SelectQueryBuilder<Recipe>,
    options: FindRecipesOptions,
  ): void {
    if (options.search) {
      const search = `%${escapeLikeTerm(options.search)}%`;
      // ค้นได้ทั้งชื่อไทยและชื่ออังกฤษ
      const titleMatch =
        "recipe.title ILIKE :search ESCAPE '\\' OR recipe.titleEn ILIKE :search ESCAPE '\\'";
      if (options.type === RecipeType.COMMUNITY) {
        query.andWhere(
          `(${titleMatch} OR recipe.shortDescription ILIKE :search ESCAPE '\\')`,
          { search },
        );
      } else {
        query.andWhere(`(${titleMatch})`, { search });
      }
    }

    if (options.category) {
      // กรองด้วย subquery เพื่อให้ recipe ที่ผ่านการกรองยังโหลด categories มาครบทุกอัน
      // (ถ้าใส่เงื่อนไขลงใน join ตรงๆ จะเหลือแต่ category ที่ตรงกับที่กรอง)
      query.andWhere(
        'recipe.id IN ' +
          query
            .subQuery()
            .select('filtered.id')
            .from(Recipe, 'filtered')
            .innerJoin('filtered.categories', 'filteredCategory')
            .where('filteredCategory.slug = :category')
            .andWhere('filteredCategory.isActive = true')
            .getQuery(),
        { category: options.category },
      );
    }

    // system search
    if (options.categoryId) {
      // ใช้ alias คนละชุดกับ options.category กันชนกันเวลากรองพร้อมกัน
      query.andWhere(
        'recipe.id IN ' +
          query
            .subQuery()
            .select('filteredById.id')
            .from(Recipe, 'filteredById')
            .innerJoin('filteredById.categories', 'filteredCategoryById')
            .where('filteredCategoryById.id = :categoryId')
            .andWhere('filteredCategoryById.isActive = true')
            .getQuery(),
        { categoryId: options.categoryId },
      );
    }

    if (options.creatorId) {
      query.andWhere('recipe.creator_id = :creatorId', {
        creatorId: options.creatorId,
      });
    }

    if (options.status) {
      query.andWhere('recipe.status = :status', { status: options.status });
    } else {
      // สูตรที่เจ้าของลบไปแล้ว (เก็บไว้ให้คนที่ซื้อ) ไม่โผล่แม้แต่ในรายการของเจ้าของเอง
      query.andWhere('recipe.status != :archived', {
        archived: RecipeStatus.ARCHIVED,
      });
    }

    if (options.type) {
      query.andWhere('recipe.type = :type', { type: options.type });
    }

    // สูตรของบัญชีที่ลบ/ถูกระงับไม่โผล่ในรายการไหนเลย
    // (ผู้ซื้อยังเปิดได้จากหน้า Purchased และ GET /recipes/:id)
    query.andWhere(
      'recipe.creator_id IN (SELECT id FROM users WHERE status = :activeStatus)',
      { activeStatus: UserStatus.ACTIVE },
    );
  }

  async findOne(id: string): Promise<Recipe> {
    const recipe = await this.recipeRepository.findOne({
      where: { id },
      relations: {
        creator: true,
        categories: true,
        recipeIngredients: { ingredient: true },
        sections: { contents: true },
      },
    });
    if (!recipe) throw new NotFoundException(`Recipe with id ${id} not found`);

    recipe.sections.sort((left, right) => left.sortOrder - right.sortOrder);
    for (const section of recipe.sections) {
      section.contents.sort((left, right) => left.sortOrder - right.sortOrder);
    }
    recipe.recipeIngredients?.sort(
      (left, right) => left.sortOrder - right.sortOrder,
    );

    const [recipeWithCounts] = await this.attachRecipeCounts([recipe]);
    return recipeWithCounts;
  }

  /**
   * สำหรับ GET /recipes/:id
   * สูตร official ที่ยังไม่ซื้อ จะเห็นเฉพาะ section ที่เป็น preview
   */
  async findOneForViewer(id: string, userId?: string): Promise<Recipe> {
    // cache เฉพาะข้อมูลสูตรที่เหมือนกันทุกคน สิทธิ์ดูสูตรเต็มคำนวณใหม่ทุกครั้งตามผู้ชม
    // (cache คืน object ใหม่ทุกครั้ง ตัด section ด้านล่างได้โดยไม่กระทบของใน cache)
    const recipe = await this.cached(
      `detail:${id}`,
      RecipesService.detailTtlSeconds,
      () => this.findOne(id),
    );
    // สูตรที่ยังไม่เผยแพร่ (draft/ซ่อน) เห็นได้แค่เจ้าของและคนที่ซื้อไปแล้ว
    // ตอบเหมือนไม่มีสูตรนี้ คนอื่นจะได้ไม่รู้ว่ามี id นี้อยู่
    if (
      recipe.status !== RecipeStatus.PUBLISHED &&
      !(await this.isOwnerOrBuyer(recipe, userId))
    ) {
      throw new NotFoundException(`Recipe with id ${id} not found`);
    }

    recipe.canViewFullRecipe = await this.canViewFullRecipe(recipe, userId);
    if (recipe.canViewFullRecipe) return this.signPaidMedia(recipe);

    recipe.sections = recipe.sections.filter((section) => section.isPreview);
    // ยังไม่ซื้อ: เห็นชื่อวัตถุดิบไว้ตัดสินใจ แต่ปริมาณ/หน่วย/หมายเหตุ เป็นส่วนที่ขาย
    recipe.recipeIngredients = hideIngredientAmounts(
      recipe.recipeIngredients ?? [],
    );
    return recipe;
  }

  /**
   * ไฟล์ในขั้นตอนที่ต้องซื้อ (ไม่ใช่ตัวอย่าง) ของสูตร official
   * แนบลายเซ็นชั่วคราวให้คนที่มีสิทธิ์ดู /uploads จะไม่ยอมเปิดถ้าไม่มีลายเซ็น
   */
  private signPaidMedia(recipe: Recipe): Recipe {
    const signer = this.mediaSigner;
    if (!signer || recipe.type !== RecipeType.OFFICIAL) return recipe;
    for (const section of recipe.sections) {
      if (section.isPreview) continue;
      for (const content of section.contents) {
        if (content.mediaUrl) content.mediaUrl = signer.sign(content.mediaUrl);
      }
    }
    return recipe;
  }

  /** ลิงก์ที่แอปส่งกลับมาตอนแก้สูตรอาจติดลายเซ็นมาด้วย เก็บเป็น path เปล่าเสมอ */
  private static withoutSignedMedia<
    T extends { sections?: { contents?: { mediaUrl?: string | null }[] }[] },
  >(dto: T): T {
    for (const section of dto.sections ?? []) {
      for (const content of section.contents ?? []) {
        if (content.mediaUrl) {
          content.mediaUrl = MediaSigner.stripQuery(content.mediaUrl);
        }
      }
    }
    return dto;
  }

  private async isOwnerOrBuyer(
    recipe: Recipe,
    userId?: string,
  ): Promise<boolean> {
    if (!userId) return false;
    return (
      recipe.creatorId === userId ||
      this.recipeAccessService.hasActiveAccess(userId, recipe.id)
    );
  }

  /** แก้/ลบได้เฉพาะเจ้าของสูตร (หรือ admin) ไม่มีสูตรนี้ = 404 */
  async assertCanManage(
    id: string,
    user: Pick<AuthUser, 'id' | 'role'>,
  ): Promise<void> {
    const recipe = await this.recipeRepository.findOne({
      where: { id },
      select: { id: true, creatorId: true, status: true },
    });
    // ลบไปแล้ว (เก็บไว้ให้ผู้ซื้อ) เจ้าของแก้/ลบซ้ำไม่ได้ เหลือแต่ admin
    const archivedForOwner =
      recipe?.status === RecipeStatus.ARCHIVED && user.role !== UserRole.ADMIN;
    if (!recipe || archivedForOwner) {
      throw new NotFoundException(`Recipe with id ${id} not found`);
    }
    assertCanManageRecipe(recipe, user);
  }

  private async canViewFullRecipe(
    recipe: Recipe,
    userId?: string,
  ): Promise<boolean> {
    if (recipe.type === RecipeType.COMMUNITY) return true;
    if (!userId) return false;
    return (
      recipe.creatorId === userId ||
      this.recipeAccessService.hasActiveAccess(userId, recipe.id)
    );
  }

  private async attachRecipeCounts(recipes: Recipe[]): Promise<Recipe[]> {
    if (recipes.length === 0) return recipes;

    const recipeIds = [...new Set(recipes.map((recipe) => recipe.id))];
    const [favoriteRows, reviewRows, commentRows] = await Promise.all([
      this.favoriteRepository
        .createQueryBuilder('favorite')
        .select('favorite.recipeId', 'recipeId')
        .addSelect('COUNT(*)', 'count')
        .where('favorite.recipeId IN (:...recipeIds)', { recipeIds })
        .groupBy('favorite.recipeId')
        .getRawMany<{ recipeId: string; count: string }>(),
      this.reviewRepository
        .createQueryBuilder('review')
        .select('review.recipeId', 'recipeId')
        .addSelect('COUNT(*)', 'count')
        .addSelect('AVG(review.rating)', 'average')
        .where('review.recipeId IN (:...recipeIds)', { recipeIds })
        .andWhere('review.status = :status', { status: ReviewStatus.PUBLISHED })
        .groupBy('review.recipeId')
        .getRawMany<{ recipeId: string; count: string; average: string }>(),
      this.commentRepository
        .createQueryBuilder('comment')
        .select('comment.recipeId', 'recipeId')
        .addSelect('COUNT(*)', 'count')
        .where('comment.recipeId IN (:...recipeIds)', { recipeIds })
        .groupBy('comment.recipeId')
        .getRawMany<{ recipeId: string; count: string }>(),
    ]);

    const favoriteCounts = new Map(
      favoriteRows.map((row) => [row.recipeId, Number(row.count)]),
    );
    const reviewCounts = new Map(
      reviewRows.map((row) => [row.recipeId, Number(row.count)]),
    );
    // ค่าเฉลี่ยดาวจริง (ไม่ถ่วงน้ำหนัก) ปัดทศนิยม 1 ตำแหน่งไว้โชว์บนการ์ด
    const reviewAverages = new Map(
      reviewRows.map((row) => [
        row.recipeId,
        Math.round(Number(row.average) * 10) / 10,
      ]),
    );
    const commentCounts = new Map(
      commentRows.map((row) => [row.recipeId, Number(row.count)]),
    );

    for (const recipe of recipes) {
      recipe.favoriteCount = favoriteCounts.get(recipe.id) ?? 0;
      recipe.reviewCount = reviewCounts.get(recipe.id) ?? 0;
      // ยังไม่มีรีวิว = null แยกจากได้คะแนนต่ำ
      recipe.averageRating = reviewAverages.get(recipe.id) ?? null;
      recipe.commentCount = commentCounts.get(recipe.id) ?? 0;
    }

    return recipes;
  }

  async create(dto: CreateRecipeDto): Promise<Recipe> {
    const {
      categoryIds,
      sections = [],
      ingredients = [],
      ...recipeData
    } = RecipesService.withoutSignedMedia(dto);
    const categories = await this.resolveCategories(categoryIds);
    RecipesService.assertActiveCategories(categories);

    const created = await this.recipeRepository.manager.transaction(
      async (manager) => {
        const recipeRepository = manager.getRepository(Recipe);
        const sectionRepository = manager.getRepository(RecipeSection);
        const contentRepository = manager.getRepository(RecipeContent);
        const recipe = recipeRepository.create(recipeData);
        recipe.categories = categories;
        if (recipe.status === RecipeStatus.PUBLISHED && !recipe.publishedAt) {
          recipe.publishedAt = new Date();
        }

        await recipeRepository.save(recipe);

        for (const [sectionIndex, sectionData] of sections.entries()) {
          const { contents = [], ...sectionFields } = sectionData;
          const section = await sectionRepository.save(
            sectionRepository.create({
              ...sectionFields,
              recipeId: recipe.id,
              sortOrder: sectionData.sortOrder ?? sectionIndex,
            }),
          );

          if (contents.length > 0) {
            await contentRepository.save(
              contents.map((content, contentIndex) =>
                contentRepository.create({
                  ...content,
                  sectionId: section.id,
                  sortOrder: content.sortOrder ?? contentIndex,
                }),
              ),
            );
          }
        }

        if (ingredients.length > 0) {
          await replaceRecipeIngredients(manager, recipe.id, ingredients);
        }

        return recipeRepository.findOneOrFail({
          where: { id: recipe.id },
          relations: {
            creator: true,
            categories: true,
            recipeIngredients: { ingredient: true },
            sections: { contents: true },
          },
        });
      },
    );
    await this.invalidateRecipes();
    return created;
  }

  /** [moderatorId] = admin ที่แก้ (ใช้แจ้งเจ้าของเมื่อสูตรถูกซ่อน/ไม่ผ่านการตรวจ) */
  async update(
    id: string,
    dto: UpdateRecipeDto,
    moderatorId?: string,
  ): Promise<Recipe> {
    const { categoryIds, sections, ingredients, ...recipeData } =
      RecipesService.withoutSignedMedia(dto);
    const categories = categoryIds
      ? await this.resolveCategories(categoryIds)
      : undefined;

    let previousStatus: RecipeStatus | undefined;
    await this.recipeRepository.manager.transaction(async (manager) => {
      const recipeRepository = manager.getRepository(Recipe);
      const sectionRepository = manager.getRepository(RecipeSection);
      const contentRepository = manager.getRepository(RecipeContent);

      // โหลดเฉพาะ categories ไม่โหลด sections เพื่อไม่ให้ save ไปยุ่งกับ section เดิม
      const recipe = await recipeRepository.findOne({
        where: { id },
        relations: { categories: true },
      });
      if (!recipe) {
        throw new NotFoundException(`Recipe with id ${id} not found`);
      }
      // publish แล้วห้ามเปลี่ยน type
      if (
        recipeData.type !== undefined &&
        recipeData.type !== recipe.type &&
        recipe.status === RecipeStatus.PUBLISHED
      ) {
        throw new BadRequestException(
          'Cannot change type of a published recipe',
        );
      }

      previousStatus = recipe.status;
      Object.assign(recipe, recipeData, { id: recipe.id });
      if (categories) {
        recipe.categories = RecipesService.mergeCategories(
          recipe.categories,
          categories,
        );
      }
      if (recipe.status === RecipeStatus.PUBLISHED && !recipe.publishedAt) {
        recipe.publishedAt = new Date();
      }
      await recipeRepository.save(recipe);

      // ไม่ส่งมา = คงวัตถุดิบเดิมไว้
      if (ingredients) {
        await replaceRecipeIngredients(manager, recipe.id, ingredients);
      }

      if (!sections) return;

      // content ถูกลบตามด้วย onDelete: CASCADE
      await sectionRepository.delete({ recipeId: recipe.id });
      for (const [sectionIndex, sectionData] of sections.entries()) {
        const { contents = [], ...sectionFields } = sectionData;
        const section = await sectionRepository.save(
          sectionRepository.create({
            ...sectionFields,
            recipeId: recipe.id,
            sortOrder: sectionData.sortOrder ?? sectionIndex,
          }),
        );

        if (contents.length > 0) {
          await contentRepository.save(
            contents.map((content, contentIndex) =>
              contentRepository.create({
                ...content,
                sectionId: section.id,
                sortOrder: content.sortOrder ?? contentIndex,
              }),
            ),
          );
        }
      }
    });

    await this.invalidateRecipes();
    await this.notifyModeration(id, previousStatus, dto.status, moderatorId);
    return this.findOne(id);
  }

  /** admin เพิ่งซ่อน/ปฏิเสธสูตร: บอกเจ้าของ (สถานะเดิมอยู่แล้ว = ไม่แจ้งซ้ำ) */
  private async notifyModeration(
    recipeId: string,
    previous: RecipeStatus | undefined,
    next: RecipeStatus | undefined,
    moderatorId: string | undefined,
  ): Promise<void> {
    if (!moderatorId || next === previous) return;
    if (next !== RecipeStatus.HIDDEN && next !== RecipeStatus.REJECTED) return;
    await this.notifications?.notifyRecipeOwner({
      type: NotificationType.RECIPE_MODERATED,
      recipeId,
      // ข้อความแจ้งเป็น "ทีมงาน" ไม่เปิดเผยว่า admin คนไหน
      actorId: null,
      data: {
        status: next === RecipeStatus.HIDDEN ? 'hidden' : 'rejected',
      },
    });
  }

  /** สูตรใหม่ใส่หมวดที่ admin ปิดใช้งานไม่ได้ */
  private static assertActiveCategories(categories: Category[]): void {
    const inactive = categories.filter(
      (category) => category.isActive === false,
    );
    if (inactive.length > 0) {
      throw new BadRequestException(
        `Categories are no longer available: ${inactive.map((c) => c.name).join(', ')}`,
      );
    }
  }

  /**
   * หมวดหลังแก้สูตร = ที่ส่งมา + หมวดที่ปิดใช้งานซึ่งสูตรมีอยู่เดิม
   * แอปไม่เห็นหมวดที่ปิด (จึงไม่ได้ส่งกลับมา) ถ้าแทนทั้งชุดตรง ๆ สูตรจะหลุดจากหมวดนั้นถาวร
   * เพิ่มหมวดที่ปิดเข้าไปใหม่ไม่ได้
   */
  private static mergeCategories(
    current: Category[],
    requested: Category[],
  ): Category[] {
    const currentIds = new Set(current.map((category) => category.id));
    RecipesService.assertActiveCategories(
      requested.filter((category) => !currentIds.has(category.id)),
    );
    const requestedIds = new Set(requested.map((category) => category.id));
    const keptHidden = current.filter(
      (category) =>
        category.isActive === false && !requestedIds.has(category.id),
    );
    return [...requested, ...keptHidden];
  }

  // แปลง categoryIds -> Category entity จริง และเช็คว่ามีครบทุก id
  private async resolveCategories(categoryIds?: string[]): Promise<Category[]> {
    if (!categoryIds?.length) return [];

    const uniqueIds = [...new Set(categoryIds)];
    const categories = await this.categoryRepository.findBy({
      id: In(uniqueIds),
    });

    if (categories.length !== uniqueIds.length) {
      const found = new Set(categories.map((category) => category.id));
      const missing = uniqueIds.filter((id) => !found.has(id));
      throw new NotFoundException(
        `Categories not found: ${missing.join(', ')}`,
      );
    }

    return categories;
  }

  /**
   * ลบสูตร คืนว่าลบจริงหรือเก็บไว้
   * สูตรที่เคยมีคนสั่งซื้อ (order_items ผูกแบบ RESTRICT) ลบจริงไม่ได้ จึงเปลี่ยนเป็น archived แทน
   * ไม่เช็กก่อนลบ แต่ลองลบแล้วดู error ของ foreign key กันกรณีมีออเดอร์เข้ามาพอดีระหว่างเช็ก
   */
  async remove(id: string): Promise<'deleted' | 'archived'> {
    const exists = await this.recipeRepository.exists({ where: { id } });
    if (!exists) throw new NotFoundException(`Recipe with id ${id} not found`);

    let result: 'deleted' | 'archived' = 'deleted';
    try {
      // ขั้นตอน/วัตถุดิบ/ตะกร้า/หัวใจ/คอมเมนต์ ฯลฯ ลบตามด้วย onDelete: CASCADE
      await this.recipeRepository.delete({ id });
    } catch (error) {
      if (!isForeignKeyViolation(error)) throw error;
      await this.archive(id);
      result = 'archived';
    }
    // คอมเมนต์/รีวิวของสูตรที่ลบไปแล้วต้องไม่ค้างใน cache
    await Promise.all([
      this.invalidateRecipes(),
      this.cache?.invalidate(CacheNamespace.comments),
      this.cache?.invalidate(CacheNamespace.reviews),
    ]);
    return result;
  }

  /** เก็บสูตรที่มีคนซื้อแล้ว: ปิดการขาย เอาออกจากตะกร้าทุกคน และหัวใจของคนที่ไม่ได้ซื้อ */
  private async archive(id: string): Promise<void> {
    await this.recipeRepository.manager.transaction(async (manager) => {
      await manager.update(Recipe, { id }, { status: RecipeStatus.ARCHIVED });
      await manager.delete(CartItem, { recipeId: id });
      // คนที่ซื้อแล้วยังเห็นสูตร หัวใจของเขาจึงเก็บไว้ คนอื่นเปิดไม่ได้แล้วจึงเอาออก
      await manager
        .createQueryBuilder()
        .delete()
        .from(Favorite)
        .where('recipe_id = :id', { id })
        .andWhere(
          'user_id NOT IN (SELECT user_id FROM recipe_access WHERE recipe_id = :id)',
        )
        .execute();
    });
  }

  // ---- cache ----

  /** สูตร/ยอดหัวใจ/รีวิว/คอมเมนต์เปลี่ยน: ทิ้ง cache รายการและรายละเอียดสูตรทั้งหมด */
  async invalidateRecipes(): Promise<void> {
    await this.cache?.invalidate(CacheNamespace.recipes);
  }

  // ไม่มี cache (เช่นในเทสต์) ก็เรียก loader ตรง ๆ
  private cached<T>(
    key: string,
    ttlSeconds: number,
    loader: () => Promise<T>,
  ): Promise<T> {
    return this.cache
      ? this.cache.getOrSet(CacheNamespace.recipes, key, ttlSeconds, loader)
      : loader();
  }
}

// key คงที่ไม่ขึ้นกับลำดับ field และไม่นับค่าที่ไม่ได้ส่งมา
function stableKey(prefix: string, value: object): string {
  const entries = Object.entries(value)
    .filter(([, field]) => field !== undefined && field !== '')
    .sort(([left], [right]) => left.localeCompare(right));
  return `${prefix}:${JSON.stringify(entries)}`;
}
