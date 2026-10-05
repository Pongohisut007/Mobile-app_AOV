/* eslint-disable security/detect-object-injection, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-assignment -- Test query builders and transaction callbacks are Jest mocks. */
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { Category } from '../categories/entities/category.entity';
import { Favorite } from '../favorites/entities/favorite.entity';
import { RecipeAccessService } from '../recipe-access/recipe-access.service';
import { RecipeComment } from '../recipe-comments/entities/recipe-comment.entity';
import { Review, ReviewStatus } from '../reviews/entities/review.entity';
import { UserRole } from '../users/entities/user.entity';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { RecipeSort } from './dto/list-recipes-query.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { RecipeSection } from './entities/recipe-section.entity';
import { Recipe, RecipeStatus, RecipeType } from './entities/recipe.entity';
import { MediaSigner } from '../uploads/media-signer.service';
import { RecipesService } from './recipes.service';

function queryBuilder() {
  const query: Record<string, jest.Mock> = {};
  for (const method of [
    'leftJoinAndSelect',
    'orderBy',
    'addOrderBy',
    'andWhere',
    'select',
    'addSelect',
    'setParameters',
    'offset',
    'limit',
    'where',
    'from',
    'innerJoin',
    'groupBy',
  ]) {
    query[method] = jest.fn().mockReturnValue(query);
  }
  query.subQuery = jest.fn().mockReturnValue(query);
  query.getQuery = jest.fn().mockReturnValue('(SELECT filtered.id)');
  query.getMany = jest.fn().mockResolvedValue([]);
  query.getCount = jest.fn().mockResolvedValue(0);
  query.getRawMany = jest.fn().mockResolvedValue([]);
  return query;
}

describe('RecipesService', () => {
  let service: RecipesService;
  let recipeQuery: ReturnType<typeof queryBuilder>;
  let favoriteQuery: ReturnType<typeof queryBuilder>;
  let reviewQuery: ReturnType<typeof queryBuilder>;
  let commentQuery: ReturnType<typeof queryBuilder>;
  const recipeRepository = {
    createQueryBuilder: jest.fn(),
    find: jest.fn(),
    findOne: jest.fn(),
    remove: jest.fn(),
    manager: { transaction: jest.fn() },
  };
  const categoryRepository = { findBy: jest.fn() };
  const favoriteRepository = { createQueryBuilder: jest.fn() };
  const reviewRepository = { createQueryBuilder: jest.fn() };
  const commentRepository = { createQueryBuilder: jest.fn() };
  const access = { hasActiveAccess: jest.fn() };

  beforeEach(() => {
    jest.clearAllMocks();
    recipeQuery = queryBuilder();
    favoriteQuery = queryBuilder();
    reviewQuery = queryBuilder();
    commentQuery = queryBuilder();
    recipeRepository.createQueryBuilder.mockReturnValue(recipeQuery);
    favoriteRepository.createQueryBuilder.mockReturnValue(favoriteQuery);
    reviewRepository.createQueryBuilder.mockReturnValue(reviewQuery);
    commentRepository.createQueryBuilder.mockReturnValue(commentQuery);
    service = new RecipesService(
      recipeRepository as unknown as Repository<Recipe>,
      categoryRepository as unknown as Repository<Category>,
      favoriteRepository as unknown as Repository<Favorite>,
      reviewRepository as unknown as Repository<Review>,
      commentRepository as unknown as Repository<RecipeComment>,
      access as unknown as RecipeAccessService,
    );
  });

  it('filters community recipes and attaches only published review counts', async () => {
    const recipes = [{ id: 'a' }, { id: 'b' }] as Recipe[];
    recipeQuery.getMany.mockResolvedValue(recipes);
    favoriteQuery.getRawMany.mockResolvedValue([{ recipeId: 'a', count: '2' }]);
    reviewQuery.getRawMany.mockResolvedValue([
      { recipeId: 'a', count: '3', average: '4.3333333333333333' },
    ]);
    commentQuery.getRawMany.mockResolvedValue([{ recipeId: 'b', count: '4' }]);

    const result = await service.findAll({
      search: '10%_\\',
      category: 'thai',
      categoryId: 'cat-1',
      creatorId: 'owner',
      status: RecipeStatus.PUBLISHED,
      type: RecipeType.COMMUNITY,
    });

    expect(recipeQuery.andWhere).toHaveBeenCalledWith(
      expect.stringContaining('recipe.shortDescription ILIKE'),
      { search: '%10\\%\\_\\\\%' },
    );
    expect(recipeQuery.where).toHaveBeenCalledWith(
      'filteredCategory.slug = :category',
    );
    expect(recipeQuery.where).toHaveBeenCalledWith(
      'filteredCategoryById.id = :categoryId',
    );
    expect(recipeQuery.andWhere).toHaveBeenCalledWith(
      expect.stringContaining('recipe.id IN'),
      { category: 'thai' },
    );
    expect(recipeQuery.andWhere).toHaveBeenCalledWith(
      expect.stringContaining('recipe.id IN'),
      { categoryId: 'cat-1' },
    );
    expect(recipeQuery.andWhere).toHaveBeenCalledWith(
      'recipe.creator_id = :creatorId',
      { creatorId: 'owner' },
    );
    expect(recipeQuery.andWhere).toHaveBeenCalledWith(
      'recipe.status = :status',
      { status: RecipeStatus.PUBLISHED },
    );
    expect(reviewQuery.andWhere).toHaveBeenCalledWith(
      'review.status = :status',
      { status: ReviewStatus.PUBLISHED },
    );
    expect(result).toEqual([
      expect.objectContaining({
        id: 'a',
        favoriteCount: 2,
        reviewCount: 3,
        averageRating: 4.3,
        commentCount: 0,
      }),
      expect.objectContaining({
        id: 'b',
        favoriteCount: 0,
        reviewCount: 0,
        averageRating: null,
        commentCount: 4,
      }),
    ]);
  });

  it('returns an empty search page without loading relations', async () => {
    const result = await service.search({
      q: 'soup',
      page: 2,
      limit: 5,
    });
    expect(result).toEqual({
      data: [],
      total: 0,
      page: 2,
      limit: 5,
      totalPages: 0,
    });
    expect(recipeRepository.find).not.toHaveBeenCalled();
  });

  it('orders search results by relevance IDs and escapes wildcard characters', async () => {
    recipeQuery.getCount.mockResolvedValue(3);
    recipeQuery.getRawMany.mockResolvedValue([
      { id: 'b' },
      { id: 'a' },
      { id: 'missing' },
    ]);
    recipeRepository.find.mockResolvedValue([{ id: 'a' }, { id: 'b' }]);
    const result = await service.search({
      q: '50%',
      page: 2,
      limit: 2,
    });
    expect(recipeQuery.setParameters).toHaveBeenCalledWith({
      exactTerm: '50\\%',
      prefixTerm: '50\\%%',
    });
    expect(recipeQuery.offset).toHaveBeenCalledWith(2);
    expect(result).toEqual({
      data: [
        expect.objectContaining({
          id: 'b',
          favoriteCount: 0,
          reviewCount: 0,
          commentCount: 0,
        }),
        expect.objectContaining({ id: 'a' }),
      ],
      total: 3,
      page: 2,
      limit: 2,
      totalPages: 2,
    });
  });

  it('orders a page by newest first unless rating sort is requested', async () => {
    recipeQuery.getCount.mockResolvedValue(1);
    recipeQuery.getRawMany.mockResolvedValue([{ id: 'a' }]);
    recipeRepository.find.mockResolvedValue([{ id: 'a' }]);

    await service.findPage({ type: RecipeType.OFFICIAL }, 1, 6);

    expect(recipeQuery.orderBy).toHaveBeenCalledWith('sort_at', 'DESC');
    expect(recipeQuery.orderBy).not.toHaveBeenCalledWith('has_reviews', 'DESC');
  });

  it('ranks rated recipes by weighted average with unrated ones last', async () => {
    recipeQuery.getCount.mockResolvedValue(2);
    recipeQuery.getRawMany.mockResolvedValue([{ id: 'b' }, { id: 'a' }]);
    recipeRepository.find.mockResolvedValue([{ id: 'a' }, { id: 'b' }]);

    const result = await service.findPage(
      { type: RecipeType.OFFICIAL },
      1,
      6,
      RecipeSort.RATING,
    );

    expect(recipeQuery.setParameters).toHaveBeenCalledWith({
      publishedReview: ReviewStatus.PUBLISHED,
    });
    expect(recipeQuery.orderBy).toHaveBeenCalledWith('has_reviews', 'DESC');
    const orderCalls = recipeQuery.addOrderBy.mock.calls.map(
      ([column]) => column as string,
    );
    expect(orderCalls).toEqual(['rating_score', 'sort_at', 'recipe.id']);
    expect(result.data.map((recipe) => recipe.id)).toEqual(['b', 'a']);
  });

  it('sorts sections and content, and hides non-preview content for unpaid viewers', async () => {
    const recipe = {
      id: 'r',
      type: RecipeType.OFFICIAL,
      status: RecipeStatus.PUBLISHED,
      creatorId: 'owner',
      sections: [
        {
          sortOrder: 2,
          isPreview: false,
          contents: [{ sortOrder: 2 }, { sortOrder: 1 }],
        },
        {
          sortOrder: 1,
          isPreview: true,
          contents: [{ sortOrder: 3 }, { sortOrder: 1 }],
        },
      ],
    } as Recipe;
    recipeRepository.findOne.mockResolvedValue(recipe);
    access.hasActiveAccess.mockResolvedValue(false);
    const result = await service.findOneForViewer('r', 'viewer');
    expect(result.canViewFullRecipe).toBe(false);
    expect(result.sections).toHaveLength(1);
    expect(
      result.sections[0].contents.map((content) => content.sortOrder),
    ).toEqual([1, 3]);
    expect(recipeRepository.findOne).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'r' } }),
    );
    recipeRepository.findOne.mockResolvedValue(null);
    await expect(service.findOne('missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('allows community recipes and the creator to view all sections', async () => {
    recipeRepository.findOne.mockResolvedValue({
      id: 'r',
      type: RecipeType.COMMUNITY,
      status: RecipeStatus.PUBLISHED,
      sections: [],
    });
    expect((await service.findOneForViewer('r')).canViewFullRecipe).toBe(true);
    recipeRepository.findOne.mockResolvedValue({
      id: 'r',
      type: RecipeType.OFFICIAL,
      status: RecipeStatus.PUBLISHED,
      creatorId: 'owner',
      sections: [],
    });
    expect(
      (await service.findOneForViewer('r', 'owner')).canViewFullRecipe,
    ).toBe(true);
    expect(access.hasActiveAccess).not.toHaveBeenCalled();
  });

  it('signs paid step media for viewers who can see the full recipe', async () => {
    const signer = { sign: jest.fn((url: string) => `${url}?sig=1`) };
    const signing = new RecipesService(
      recipeRepository as unknown as Repository<Recipe>,
      categoryRepository as unknown as Repository<Category>,
      favoriteRepository as unknown as Repository<Favorite>,
      reviewRepository as unknown as Repository<Review>,
      commentRepository as unknown as Repository<RecipeComment>,
      access as unknown as RecipeAccessService,
      undefined,
      signer as unknown as MediaSigner,
    );
    const recipe = () => ({
      id: 'r',
      type: RecipeType.OFFICIAL,
      status: RecipeStatus.PUBLISHED,
      creatorId: 'owner',
      sections: [
        {
          sortOrder: 1,
          isPreview: true,
          contents: [{ sortOrder: 1, mediaUrl: '/uploads/images/free.png' }],
        },
        {
          sortOrder: 2,
          isPreview: false,
          contents: [{ sortOrder: 1, mediaUrl: '/uploads/videos/paid.mp4' }],
        },
      ],
    });

    recipeRepository.findOne.mockResolvedValue(recipe());
    access.hasActiveAccess.mockResolvedValue(true);
    const bought = await signing.findOneForViewer('r', 'buyer');
    expect(bought.sections[0].contents[0].mediaUrl).toBe(
      '/uploads/images/free.png',
    );
    expect(bought.sections[1].contents[0].mediaUrl).toBe(
      '/uploads/videos/paid.mp4?sig=1',
    );

    // ยังไม่ซื้อ: ไม่เห็นขั้นตอนที่ต้องซื้อ และไม่ได้ลิงก์ที่เซ็นแล้ว
    recipeRepository.findOne.mockResolvedValue(recipe());
    access.hasActiveAccess.mockResolvedValue(false);
    signer.sign.mockClear();
    const preview = await signing.findOneForViewer('r', 'stranger');
    expect(preview.sections).toHaveLength(1);
    expect(signer.sign).not.toHaveBeenCalled();
  });

  it('shows unpublished recipes only to the owner and buyers', async () => {
    recipeRepository.findOne.mockResolvedValue({
      id: 'r',
      type: RecipeType.COMMUNITY,
      status: RecipeStatus.DRAFT,
      creatorId: 'owner',
      sections: [],
    });
    access.hasActiveAccess.mockResolvedValue(false);

    await expect(service.findOneForViewer('r')).rejects.toBeInstanceOf(
      NotFoundException,
    );
    await expect(
      service.findOneForViewer('r', 'stranger'),
    ).rejects.toBeInstanceOf(NotFoundException);
    await expect(service.findOneForViewer('r', 'owner')).resolves.toEqual(
      expect.objectContaining({ id: 'r' }),
    );

    // ซื้อไปแล้ว แต่เจ้าของซ่อนสูตรทีหลัง ยังเปิดได้
    access.hasActiveAccess.mockResolvedValue(true);
    await expect(service.findOneForViewer('r', 'buyer')).resolves.toEqual(
      expect.objectContaining({ id: 'r' }),
    );
  });

  it('lets only the owner or an admin manage a recipe', async () => {
    recipeRepository.findOne.mockResolvedValue({ id: 'r', creatorId: 'owner' });

    await expect(
      service.assertCanManage('r', { id: 'owner', role: UserRole.USER }),
    ).resolves.toBeUndefined();
    await expect(
      service.assertCanManage('r', { id: 'admin', role: UserRole.ADMIN }),
    ).resolves.toBeUndefined();
    await expect(
      service.assertCanManage('r', { id: 'other', role: UserRole.CREATOR }),
    ).rejects.toBeInstanceOf(ForbiddenException);

    recipeRepository.findOne.mockResolvedValue(null);
    await expect(
      service.assertCanManage('missing', { id: 'owner', role: UserRole.USER }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('creates recipe sections and contents in one transaction', async () => {
    const recipeRepo = {
      create: jest.fn((value) => ({ id: 'r', ...value })),
      save: jest.fn(),
      findOneOrFail: jest.fn().mockResolvedValue({ id: 'r' }),
    };
    const sectionRepo = {
      create: jest.fn((value) => value),
      save: jest
        .fn()
        .mockImplementation((value) => Promise.resolve({ id: 's', ...value })),
    };
    const contentRepo = { create: jest.fn((value) => value), save: jest.fn() };
    const manager = {
      getRepository: jest.fn((entity) =>
        entity === Recipe
          ? recipeRepo
          : entity === RecipeSection
            ? sectionRepo
            : contentRepo,
      ),
    };
    recipeRepository.manager.transaction.mockImplementation((callback) =>
      callback(manager),
    );
    categoryRepository.findBy.mockResolvedValue([{ id: 'cat' }]);
    const result = await service.create({
      title: 'Soup',
      status: RecipeStatus.PUBLISHED,
      categoryIds: ['cat', 'cat'],
      sections: [
        {
          title: 'Prepare',
          contents: [
            {
              textContent: 'Chop',
              mediaUrl: '/uploads/videos/a.mp4?exp=1&sig=old',
            },
          ],
        },
      ],
    } as CreateRecipeDto);
    // ลิงก์ที่เซ็นมาจากหน้าแก้ไข เก็บลงฐานข้อมูลเป็น path เปล่า
    expect(contentRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ mediaUrl: '/uploads/videos/a.mp4' }),
    );
    expect(result).toEqual({ id: 'r' });
    expect(categoryRepository.findBy).toHaveBeenCalledTimes(1);
    expect(recipeRepo.save).toHaveBeenCalledWith(
      expect.objectContaining({
        categories: [{ id: 'cat' }],
        publishedAt: expect.any(Date),
      }),
    );
    expect(sectionRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ recipeId: 'r', sortOrder: 0 }),
    );
    expect(contentRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ sectionId: 's', sortOrder: 0 }),
    );
  });

  it('rejects unknown category IDs before starting a transaction', async () => {
    categoryRepository.findBy.mockResolvedValue([{ id: 'known' }]);
    await expect(
      service.create({ categoryIds: ['known', 'missing'] } as CreateRecipeDto),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(recipeRepository.manager.transaction).not.toHaveBeenCalled();
  });

  it('updates without replacing sections when they are omitted', async () => {
    const existing = {
      id: 'r',
      status: RecipeStatus.DRAFT,
      categories: [],
    } as unknown as Recipe;
    const recipeRepo = {
      findOne: jest.fn().mockResolvedValue(existing),
      save: jest.fn(),
    };
    const sectionRepo = { delete: jest.fn() };
    const manager = {
      getRepository: jest.fn((entity) =>
        entity === Recipe ? recipeRepo : sectionRepo,
      ),
    };
    recipeRepository.manager.transaction.mockImplementation((callback) =>
      callback(manager),
    );
    recipeRepository.findOne.mockResolvedValue({ ...existing, sections: [] });
    await service.update('r', {
      title: 'Updated',
      status: RecipeStatus.PUBLISHED,
    });
    expect(recipeRepo.save).toHaveBeenCalledWith(
      expect.objectContaining({
        id: 'r',
        title: 'Updated',
        publishedAt: expect.any(Date),
      }),
    );
    expect(sectionRepo.delete).not.toHaveBeenCalled();
  });

  it('replaces sections when explicitly supplied and preserves the recipe ID', async () => {
    const recipeRepo = {
      findOne: jest.fn().mockResolvedValue({
        id: 'r',
        status: RecipeStatus.DRAFT,
        categories: [],
      }),
      save: jest.fn(),
    };
    const sectionRepo = {
      delete: jest.fn(),
      create: jest.fn((value: unknown) => value),
      save: jest.fn().mockResolvedValue({ id: 'section-1' }),
    };
    const contentRepo = {
      create: jest.fn((value: unknown) => value),
      save: jest.fn(),
    };
    const manager = {
      getRepository: jest.fn((entity: unknown) =>
        entity === Recipe
          ? recipeRepo
          : entity === RecipeSection
            ? sectionRepo
            : contentRepo,
      ),
    };
    recipeRepository.manager.transaction.mockImplementation((callback) =>
      callback(manager),
    );
    recipeRepository.findOne.mockResolvedValue({ id: 'r', sections: [] });
    categoryRepository.findBy.mockResolvedValue([{ id: 'cat' }]);

    await service.update('r', {
      id: 'different',
      categoryIds: ['cat'],
      sections: [{ title: 'New section', contents: [{ textContent: 'Stir' }] }],
    } as unknown as UpdateRecipeDto);

    expect(recipeRepo.save).toHaveBeenCalledWith(
      expect.objectContaining({ id: 'r', categories: [{ id: 'cat' }] }),
    );
    expect(sectionRepo.delete).toHaveBeenCalledWith({ recipeId: 'r' });
    expect(sectionRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ recipeId: 'r', sortOrder: 0 }),
    );
    expect(contentRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ sectionId: 'section-1', sortOrder: 0 }),
    );
  });

  it('does not save when the recipe to update is missing', async () => {
    const recipeRepo = {
      findOne: jest.fn().mockResolvedValue(null),
      save: jest.fn(),
    };
    recipeRepository.manager.transaction.mockImplementation((callback) =>
      callback({ getRepository: () => recipeRepo }),
    );
    await expect(service.update('missing', {})).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(recipeRepo.save).not.toHaveBeenCalled();
  });
});
