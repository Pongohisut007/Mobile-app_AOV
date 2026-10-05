import {
  BadRequestException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { AppCacheService } from '../cache/app-cache.service';
import { CacheNamespace } from '../cache/app-cache.module';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository, SelectQueryBuilder } from 'typeorm';
import { Category } from '../categories/entities/category.entity';
import { PaginatedResult, toPaginated } from '../common/pagination';
import { Favorite } from '../favorites/entities/favorite.entity';
import { RecipeAccessService } from '../recipe-access/recipe-access.service';
import { RecipeComment } from '../recipe-comments/entities/recipe-comment.entity';
import { Review, ReviewStatus } from '../reviews/entities/review.entity';
import { UserStatus } from '../users/entities/user.entity';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { RecipeSort } from './dto/list-recipes-query.dto';
import { SearchRecipesDto } from './dto/search-recipes.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { RecipeContent } from './entities/recipe-content.entity';
import { RecipeSection } from './entities/recipe-section.entity';
import { Recipe, RecipeStatus, RecipeType } from './entities/recipe.entity';

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
    recipe.canViewFullRecipe = await this.canViewFullRecipe(recipe, userId);
    if (recipe.canViewFullRecipe) return recipe;

    recipe.sections = recipe.sections.filter((section) => section.isPreview);
    return recipe;
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
    const { categoryIds, sections = [], ...recipeData } = dto;
    const categories = await this.resolveCategories(categoryIds);

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

        return recipeRepository.findOneOrFail({
          where: { id: recipe.id },
          relations: {
            creator: true,
            categories: true,
            sections: { contents: true },
          },
        });
      },
    );
    await this.invalidateRecipes();
    return created;
  }

  async update(id: string, dto: UpdateRecipeDto): Promise<Recipe> {
    const { categoryIds, sections, ...recipeData } = dto;
    const categories = categoryIds
      ? await this.resolveCategories(categoryIds)
      : undefined;

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

      Object.assign(recipe, recipeData, { id: recipe.id });
      if (categories) recipe.categories = categories;
      if (recipe.status === RecipeStatus.PUBLISHED && !recipe.publishedAt) {
        recipe.publishedAt = new Date();
      }
      await recipeRepository.save(recipe);

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
    return this.findOne(id);
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

  async remove(id: string): Promise<void> {
    const recipe = await this.findOne(id);
    await this.recipeRepository.remove(recipe);
    // คอมเมนต์/รีวิวของสูตรที่ลบไปแล้วต้องไม่ค้างใน cache
    await Promise.all([
      this.invalidateRecipes(),
      this.cache?.invalidate(CacheNamespace.comments),
      this.cache?.invalidate(CacheNamespace.reviews),
    ]);
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
