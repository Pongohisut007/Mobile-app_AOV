/* eslint-disable security/detect-object-injection, @typescript-eslint/no-unsafe-assignment -- Query builder and asymmetric matchers are Jest mocks. */
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { RecipeAccessService } from '../recipe-access/recipe-access.service';
import { Recipe } from '../recipes/entities/recipe.entity';
import { Review, ReviewStatus } from './entities/review.entity';
import { ReviewsService } from './reviews.service';

describe('ReviewsService', () => {
  const query: Record<string, jest.Mock> = {};
  for (const method of [
    'select',
    'addSelect',
    'where',
    'andWhere',
    'groupBy',
  ]) {
    query[method] = jest.fn().mockReturnValue(query);
  }
  const reviews = {
    find: jest.fn(),
    findOne: jest.fn(),
    findAndCount: jest.fn(),
    createQueryBuilder: jest.fn(),
    upsert: jest.fn(),
    findOneOrFail: jest.fn(),
  };
  const recipes = { exists: jest.fn() };
  const access = { hasActiveAccess: jest.fn() };
  const service = new ReviewsService(
    reviews as unknown as Repository<Review>,
    recipes as unknown as Repository<Recipe>,
    access as unknown as RecipeAccessService,
  );
  const review = {
    id: 'review-1',
    recipeId: 'recipe-1',
    userId: 'user-1',
    rating: 4,
    comment: 'Good',
    tags: ['easy'],
    updatedAt: new Date('2026-10-01'),
    user: {
      id: 'user-1',
      displayName: 'Cook',
      avatarUrl: null,
      email: 'private@example.com',
    },
  } as Review;

  beforeEach(() => {
    jest.clearAllMocks();
    reviews.createQueryBuilder.mockReturnValue(query);
    query.getRawMany = jest.fn().mockResolvedValue([]);
    recipes.exists.mockResolvedValue(true);
    access.hasActiveAccess.mockResolvedValue(true);
    reviews.find.mockResolvedValue([review]);
    reviews.findOne.mockResolvedValue(review);
    reviews.findOneOrFail.mockResolvedValue(review);
    reviews.findAndCount.mockResolvedValue([[review], 1]);
  });

  it('lists all reviews and finds one with its recipe', async () => {
    expect(await service.findAll('recipe-1')).toEqual([review]);
    expect(reviews.find).toHaveBeenCalledWith(
      expect.objectContaining({ where: { recipeId: 'recipe-1' } }),
    );
    expect(await service.findOne('review-1')).toBe(review);
    reviews.findOne.mockResolvedValue(null);
    await expect(service.findOne('missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('computes the published rating distribution and omits private user fields', async () => {
    query.getRawMany.mockResolvedValue([
      { rating: '5', count: '2' },
      { rating: '4', count: '1' },
      { rating: '7', count: '10' },
    ]);
    const summary = await service.getRecipeSummary('recipe-1');
    expect(query.andWhere).toHaveBeenCalledWith('review.status = :status', {
      status: ReviewStatus.PUBLISHED,
    });
    expect(summary).toEqual({
      average: 4.7,
      count: 3,
      distribution: { 1: 0, 2: 0, 3: 0, 4: 1, 5: 2 },
      reviews: [
        {
          id: 'review-1',
          rating: 4,
          comment: 'Good',
          tags: ['easy'],
          createdAt: review.updatedAt,
          user: { id: 'user-1', displayName: 'Cook', avatarUrl: null },
        },
      ],
    });
    expect(reviews.find).toHaveBeenCalledWith(
      expect.objectContaining({
        take: 3,
        where: { recipeId: 'recipe-1', status: ReviewStatus.PUBLISHED },
      }),
    );
  });

  it('returns zero ratings and paginates published reviews', async () => {
    expect((await service.getRecipeSummary('recipe-1')).average).toBe(0);
    const page = await service.listRecipeReviews('recipe-1', {
      page: 2,
      limit: 4,
    });
    expect(reviews.findAndCount).toHaveBeenCalledWith(
      expect.objectContaining({
        skip: 4,
        take: 4,
        where: { recipeId: 'recipe-1', status: ReviewStatus.PUBLISHED },
      }),
    );
    expect(page).toEqual({
      items: [expect.objectContaining({ id: 'review-1' })],
      total: 1,
      page: 2,
      limit: 4,
    });
  });

  it('reports review permission and an existing personal review', async () => {
    expect(await service.findMine('recipe-1', 'user-1')).toEqual({
      canReview: true,
      review: expect.objectContaining({ id: 'review-1' }),
    });
    reviews.findOne.mockResolvedValue(null);
    access.hasActiveAccess.mockResolvedValue(false);
    expect(await service.findMine('recipe-1', 'user-1')).toEqual({
      canReview: false,
      review: null,
    });
  });

  it('trims a personal review and keeps the existing status untouched', async () => {
    const result = await service.upsertMine('recipe-1', 'user-1', {
      rating: 4,
      comment: '  Good  ',
      tags: ['easy'],
    });
    expect(reviews.upsert).toHaveBeenCalledWith(
      {
        recipeId: 'recipe-1',
        userId: 'user-1',
        rating: 4,
        comment: 'Good',
        tags: ['easy'],
      },
      { conflictPaths: ['userId', 'recipeId'] },
    );
    expect(result.user).toEqual({
      id: 'user-1',
      displayName: 'Cook',
      avatarUrl: null,
    });
  });

  it('rejects an unpaid review and missing recipes', async () => {
    access.hasActiveAccess.mockResolvedValue(false);
    await expect(
      service.upsertMine('recipe-1', 'user-1', { rating: 5 }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(reviews.upsert).not.toHaveBeenCalled();
    recipes.exists.mockResolvedValue(false);
    await expect(service.getRecipeSummary('missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
