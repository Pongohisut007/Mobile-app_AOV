import { Injectable, NotFoundException, Optional } from '@nestjs/common';
import { CacheNamespace } from '../cache/app-cache.module';
import { AppCacheService } from '../cache/app-cache.service';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Favorite } from '../favorites/entities/favorite.entity';
import { RecipeComment } from '../recipe-comments/entities/recipe-comment.entity';
import { Review, ReviewStatus } from '../reviews/entities/review.entity';
import { Category } from './entities/category.entity';
import { RecipeStatus, RecipeType } from '../recipes/entities/recipe.entity';

@Injectable()
export class CategoriesService {
  constructor(
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
    @InjectRepository(RecipeComment)
    private readonly commentRepository: Repository<RecipeComment>,
    @Optional()
    private readonly cache?: AppCacheService,
  ) {}

  async findAll(type?: RecipeType, status?: RecipeStatus): Promise<Category[]> {
    if (!type && !status) {
      // รายการหมวดแทบไม่เปลี่ยน แต่ถูกเรียกทุกครั้งที่เปิดแอป/หน้าสร้างสูตร
      const load = () =>
        this.categoryRepository.find({ order: { sortOrder: 'ASC' } });
      return this.cache
        ? this.cache.getOrSet(CacheNamespace.categories, 'all', 600, load)
        : load();
    }

    const recipeFilter = this.recipeJoinFilter(type, status);
    const categories = await this.categoryRepository
      .createQueryBuilder('category')
      .leftJoinAndSelect(
        'category.recipes',
        'recipe',
        recipeFilter.condition,
        recipeFilter.parameters,
      )
      .leftJoinAndSelect('recipe.creator', 'creator')
      .leftJoinAndSelect('recipe.categories', 'categories')
      .orderBy('category.sortOrder', 'ASC')
      .getMany();

    return this.attachRecipeCounts(categories);
  }

  async findOne(
    id: string,
    type?: RecipeType,
    status?: RecipeStatus,
  ): Promise<Category> {
    const recipeFilter = this.recipeJoinFilter(type, status);
    const query = this.categoryRepository
      .createQueryBuilder('category')
      .leftJoinAndSelect(
        'category.recipes',
        'recipe',
        recipeFilter.condition,
        recipeFilter.parameters,
      )
      .leftJoinAndSelect('recipe.creator', 'creator')
      .leftJoinAndSelect('recipe.categories', 'categories')
      .where('category.id = :id', { id });

    const category = await query.getOne();

    if (!category) {
      throw new NotFoundException(`Category with id ${id} not found`);
    }

    const [categoryWithCounts] = await this.attachRecipeCounts([category]);
    return categoryWithCounts;
  }

  // เงื่อนไขกรองสูตรตอน join เข้ากับหมวดหมู่ (ไม่ส่งมา = ไม่กรอง)
  private recipeJoinFilter(
    type?: RecipeType,
    status?: RecipeStatus,
  ): { condition?: string; parameters?: Record<string, unknown> } {
    const conditions: string[] = [];
    const parameters: Record<string, unknown> = {};
    if (type) {
      conditions.push('recipe.type = :type');
      parameters.type = type;
    }
    if (status) {
      conditions.push('recipe.status = :status');
      parameters.status = status;
    }
    if (conditions.length === 0) return {};
    return { condition: conditions.join(' AND '), parameters };
  }

  private async attachRecipeCounts(
    categories: Category[],
  ): Promise<Category[]> {
    const recipes = categories.flatMap((category) => category.recipes ?? []);
    if (recipes.length === 0) return categories;

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
        .where('review.recipeId IN (:...recipeIds)', { recipeIds })
        .andWhere('review.status = :status', { status: ReviewStatus.PUBLISHED })
        .groupBy('review.recipeId')
        .getRawMany<{ recipeId: string; count: string }>(),
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
    const commentCounts = new Map(
      commentRows.map((row) => [row.recipeId, Number(row.count)]),
    );

    for (const recipe of recipes) {
      recipe.favoriteCount = favoriteCounts.get(recipe.id) ?? 0;
      recipe.reviewCount = reviewCounts.get(recipe.id) ?? 0;
      recipe.commentCount = commentCounts.get(recipe.id) ?? 0;
    }

    return categories;
  }

  async create(data: Partial<Category>): Promise<Category> {
    const saved = await this.categoryRepository.save(
      this.categoryRepository.create(data),
    );
    await this.invalidate();
    return saved;
  }

  async update(id: string, data: Partial<Category>): Promise<Category> {
    const category = await this.findOne(id);
    Object.assign(category, data, { id: category.id });
    const saved = await this.categoryRepository.save(category);
    await this.invalidate();
    return saved;
  }

  async remove(id: string): Promise<void> {
    const category = await this.findOne(id);
    await this.categoryRepository.remove(category);
    await this.invalidate();
  }

  // ชื่อหมวดอยู่ในข้อมูลสูตรด้วย เปลี่ยนหมวดจึงต้องล้าง cache สูตรไปพร้อมกัน
  private async invalidate(): Promise<void> {
    await Promise.all([
      this.cache?.invalidate(CacheNamespace.categories),
      this.cache?.invalidate(CacheNamespace.recipes),
    ]);
  }
}
