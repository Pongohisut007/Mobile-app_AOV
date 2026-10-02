import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Favorite } from '../favorites/entities/favorite.entity';
import { Review, ReviewStatus } from '../reviews/entities/review.entity';
import { Category } from './entities/category.entity';
import { RecipeType } from '../recipes/entities/recipe.entity';

@Injectable()
export class CategoriesService {
  constructor(
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
  ) {}

  async findAll(type?: RecipeType): Promise<Category[]> {
    if (!type) {
      return this.categoryRepository.find({ order: { sortOrder: 'ASC' } });
    }

    const categories = await this.categoryRepository
      .createQueryBuilder('category')
      .leftJoinAndSelect('category.recipes', 'recipe', 'recipe.type = :type', {
        type,
      })
      .leftJoinAndSelect('recipe.creator', 'creator')
      .leftJoinAndSelect('recipe.categories', 'categories')
      .orderBy('category.sortOrder', 'ASC')
      .getMany();

    return this.attachRecipeCounts(categories);
  }

  async findOne(id: string, type?: RecipeType): Promise<Category> {
    const query = this.categoryRepository
      .createQueryBuilder('category')
      .leftJoinAndSelect(
        'category.recipes',
        'recipe',
        type ? 'recipe.type = :type' : undefined,
        type ? { type } : undefined,
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

  private async attachRecipeCounts(
    categories: Category[],
  ): Promise<Category[]> {
    const recipes = categories.flatMap((category) => category.recipes ?? []);
    if (recipes.length === 0) return categories;

    const recipeIds = [...new Set(recipes.map((recipe) => recipe.id))];
    const [favoriteRows, reviewRows] = await Promise.all([
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
    ]);

    const favoriteCounts = new Map(
      favoriteRows.map((row) => [row.recipeId, Number(row.count)]),
    );
    const reviewCounts = new Map(
      reviewRows.map((row) => [row.recipeId, Number(row.count)]),
    );

    for (const recipe of recipes) {
      recipe.favoriteCount = favoriteCounts.get(recipe.id) ?? 0;
      recipe.reviewCount = reviewCounts.get(recipe.id) ?? 0;
    }

    return categories;
  }

  create(data: Partial<Category>): Promise<Category> {
    return this.categoryRepository.save(this.categoryRepository.create(data));
  }

  async update(id: string, data: Partial<Category>): Promise<Category> {
    const category = await this.findOne(id);
    Object.assign(category, data, { id: category.id });
    return this.categoryRepository.save(category);
  }

  async remove(id: string): Promise<void> {
    const category = await this.findOne(id);
    await this.categoryRepository.remove(category);
  }
}
