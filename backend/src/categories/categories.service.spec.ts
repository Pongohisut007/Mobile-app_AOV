/* eslint-disable security/detect-object-injection -- The query builder mock uses a fixed list of method names. */
import { NotFoundException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { Favorite } from '../favorites/entities/favorite.entity';
import { RecipeComment } from '../recipe-comments/entities/recipe-comment.entity';
import { RecipeStatus, RecipeType } from '../recipes/entities/recipe.entity';
import { Review, ReviewStatus } from '../reviews/entities/review.entity';
import { CategoriesService } from './categories.service';
import { Category } from './entities/category.entity';

function builder(rows: unknown[] = []) {
  const query: Record<string, jest.Mock> = {};
  for (const method of [
    'leftJoinAndSelect',
    'orderBy',
    'where',
    'select',
    'addSelect',
    'andWhere',
    'groupBy',
  ]) {
    query[method] = jest.fn().mockReturnValue(query);
  }
  query.getMany = jest.fn().mockResolvedValue(rows);
  query.getOne = jest.fn().mockResolvedValue(rows[0] ?? null);
  query.getRawMany = jest.fn().mockResolvedValue([]);
  return query;
}

describe('CategoriesService', () => {
  const categories = {
    find: jest.fn(),
    createQueryBuilder: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    remove: jest.fn(),
  };
  const favorites = { createQueryBuilder: jest.fn() };
  const reviews = { createQueryBuilder: jest.fn() };
  const comments = { createQueryBuilder: jest.fn() };
  let service: CategoriesService;
  let categoryQuery: ReturnType<typeof builder>;
  let favoriteQuery: ReturnType<typeof builder>;
  let reviewQuery: ReturnType<typeof builder>;
  let commentQuery: ReturnType<typeof builder>;

  beforeEach(() => {
    jest.clearAllMocks();
    categoryQuery = builder();
    favoriteQuery = builder();
    reviewQuery = builder();
    commentQuery = builder();
    categories.createQueryBuilder.mockReturnValue(categoryQuery);
    favorites.createQueryBuilder.mockReturnValue(favoriteQuery);
    reviews.createQueryBuilder.mockReturnValue(reviewQuery);
    comments.createQueryBuilder.mockReturnValue(commentQuery);
    service = new CategoriesService(
      categories as unknown as Repository<Category>,
      favorites as unknown as Repository<Favorite>,
      reviews as unknown as Repository<Review>,
      comments as unknown as Repository<RecipeComment>,
    );
  });

  it('uses the simple sorted query when no recipe filter is requested', async () => {
    categories.find.mockResolvedValue([{ id: 'cat' }]);
    expect(await service.findAll()).toEqual([{ id: 'cat' }]);
    expect(categories.find).toHaveBeenCalledWith({
      order: { sortOrder: 'ASC' },
    });
    expect(categories.createQueryBuilder).not.toHaveBeenCalled();
  });

  it('filters joined recipes and attaches counts only to those recipes', async () => {
    const shared = { id: 'r' };
    const resultRows = [
      { id: 'cat-1', recipes: [shared] },
      { id: 'cat-2', recipes: [shared, { id: 'other' }] },
    ];
    categoryQuery.getMany.mockResolvedValue(resultRows);
    favoriteQuery.getRawMany.mockResolvedValue([{ recipeId: 'r', count: '2' }]);
    reviewQuery.getRawMany.mockResolvedValue([{ recipeId: 'r', count: '3' }]);
    commentQuery.getRawMany.mockResolvedValue([
      { recipeId: 'other', count: '4' },
    ]);

    expect(
      await service.findAll(RecipeType.COMMUNITY, RecipeStatus.PUBLISHED),
    ).toEqual(resultRows);
    expect(categoryQuery.leftJoinAndSelect).toHaveBeenCalledWith(
      'category.recipes',
      'recipe',
      'recipe.type = :type AND recipe.status = :status',
      { type: RecipeType.COMMUNITY, status: RecipeStatus.PUBLISHED },
    );
    expect(favoriteQuery.where).toHaveBeenCalledWith(
      'favorite.recipeId IN (:...recipeIds)',
      { recipeIds: ['r', 'other'] },
    );
    expect(reviewQuery.andWhere).toHaveBeenCalledWith(
      'review.status = :status',
      { status: ReviewStatus.PUBLISHED },
    );
    expect(shared).toEqual({
      id: 'r',
      favoriteCount: 2,
      reviewCount: 3,
      commentCount: 0,
    });
    expect(resultRows[1].recipes[1]).toEqual({
      id: 'other',
      favoriteCount: 0,
      reviewCount: 0,
      commentCount: 4,
    });
  });

  it('finds one category with a single optional filter and handles missing IDs', async () => {
    categoryQuery.getOne
      .mockResolvedValueOnce({ id: 'cat', recipes: [] })
      .mockResolvedValueOnce(null);
    expect(await service.findOne('cat', RecipeType.OFFICIAL)).toEqual({
      id: 'cat',
      recipes: [],
    });
    expect(categoryQuery.leftJoinAndSelect).toHaveBeenCalledWith(
      'category.recipes',
      'recipe',
      'recipe.type = :type',
      { type: RecipeType.OFFICIAL },
    );
    expect(categoryQuery.where).toHaveBeenCalledWith('category.id = :id', {
      id: 'cat',
    });
    await expect(service.findOne('missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('creates, updates, and removes a category', async () => {
    categories.create.mockReturnValue({ name: 'Soup' });
    categories.save.mockImplementation((value) => Promise.resolve(value));
    expect(await service.create({ name: 'Soup' })).toEqual({ name: 'Soup' });
    categoryQuery.getOne.mockResolvedValue({
      id: 'cat',
      name: 'Old',
      recipes: [],
    });
    expect(await service.update('cat', { id: 'other', name: 'New' })).toEqual({
      id: 'cat',
      name: 'New',
      recipes: [],
    });
    await service.remove('cat');
    expect(categories.remove).toHaveBeenCalledWith(
      expect.objectContaining({ id: 'cat' }),
    );
  });
});
