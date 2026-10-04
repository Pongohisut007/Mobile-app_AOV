import {
  ExecutionContext,
  INestApplication,
  NotFoundException,
  UnauthorizedException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import type { Request } from 'express';
import request from 'supertest';
import type { App } from 'supertest/types';
import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from './auth/guards/optional-jwt-auth.guard';
import { CategoriesController } from './categories/categories.controller';
import { CategoriesService } from './categories/categories.service';
import { ChatController } from './chat/chat.controller';
import { ChatService } from './chat/chat.service';
import { RecipeCommentsController } from './recipe-comments/recipe-comments.controller';
import { RecipeCommentsService } from './recipe-comments/recipe-comments.service';
import { RecipesController } from './recipes/recipes.controller';
import { RecipesService } from './recipes/recipes.service';
import { RecipeReviewsController } from './reviews/recipe-reviews.controller';
import { ReviewsService } from './reviews/reviews.service';

// Authentication is supplied by the test guard below, so Passport does not
// need to initialize its strategy or load its ESM runtime in Jest.
jest.mock('@nestjs/passport', () => ({
  AuthGuard: () =>
    class {
      canActivate() {
        return true;
      }
    },
}));

const recipeId = '7d87b810-4274-4b3f-92bb-83013ba857d9';
const userId = 'ab08b474-6b8d-4e80-a7b9-aaea927f6261';
const commentId = '80ee684b-b7e5-48b2-baf3-07a619c0d51a';

// Replace authentication only; routes, interceptors, parameter decorators and
// the production ValidationPipe configuration all run normally.
function authenticate(context: ExecutionContext, required: boolean): boolean {
  const incoming = context.switchToHttp().getRequest<Request>();
  if (incoming.headers.authorization === 'Bearer test-user') {
    incoming.user = { id: userId };
  } else if (required) {
    throw new UnauthorizedException();
  }
  return true;
}

describe('Recipe API HTTP contracts', () => {
  let app: INestApplication<App>;
  const recipes = {
    findAll: jest.fn().mockResolvedValue([]),
    search: jest.fn().mockResolvedValue({ data: [], total: 0 }),
    findOneForViewer: jest.fn().mockResolvedValue({ id: recipeId }),
    create: jest.fn().mockResolvedValue({ id: recipeId }),
    update: jest.fn().mockResolvedValue({ id: recipeId }),
    remove: jest.fn().mockResolvedValue(undefined),
  };
  const comments = {
    list: jest.fn().mockResolvedValue({ items: [], total: 0 }),
    getPermission: jest
      .fn()
      .mockResolvedValue({ canComment: true, userAvatarUrl: null }),
    create: jest.fn().mockResolvedValue({ id: commentId, comment: 'Nice' }),
    update: jest.fn().mockResolvedValue({ id: commentId, comment: 'Updated' }),
    remove: jest.fn().mockResolvedValue(undefined),
  };
  const reviews = {
    getRecipeSummary: jest.fn().mockResolvedValue({ average: 0, count: 0 }),
    listRecipeReviews: jest.fn().mockResolvedValue({ items: [], total: 0 }),
    findMine: jest.fn().mockResolvedValue({ canReview: true, review: null }),
    upsertMine: jest.fn().mockResolvedValue({ rating: 5 }),
  };
  const chat = {
    chat: jest.fn().mockResolvedValue({ message: 'Stir slowly' }),
    canChat: jest.fn().mockResolvedValue(true),
    getHistory: jest
      .fn()
      .mockResolvedValue([{ role: 'user', content: 'How?' }]),
    reset: jest.fn().mockResolvedValue(undefined),
  };
  const categories = {
    findAll: jest.fn().mockResolvedValue([]),
    findOne: jest.fn().mockResolvedValue({ id: recipeId }),
    create: jest.fn().mockResolvedValue({ id: recipeId }),
    update: jest.fn().mockResolvedValue({ id: recipeId }),
    remove: jest.fn().mockResolvedValue(undefined),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [
        RecipesController,
        RecipeCommentsController,
        RecipeReviewsController,
        ChatController,
        CategoriesController,
      ],
      providers: [
        { provide: RecipesService, useValue: recipes },
        { provide: RecipeCommentsService, useValue: comments },
        { provide: ReviewsService, useValue: reviews },
        { provide: ChatService, useValue: chat },
        { provide: CategoriesService, useValue: categories },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({
        canActivate: (context: ExecutionContext) => authenticate(context, true),
      })
      .overrideGuard(OptionalJwtAuthGuard)
      .useValue({
        canActivate: (context: ExecutionContext) =>
          authenticate(context, false),
      })
      .compile();
    app = module.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
  });

  beforeEach(() => jest.clearAllMocks());
  afterAll(async () => app.close());

  it('routes /recipes/search ahead of the UUID route and transforms query values', async () => {
    await request(app.getHttpServer())
      .get('/recipes/search')
      .query({
        q: '  soup  ',
        page: '2',
        limit: '5',
        type: 'community',
        categoryId: recipeId,
      })
      .expect(200);
    expect(recipes.search).toHaveBeenCalledWith(
      expect.objectContaining({
        q: 'soup',
        page: 2,
        limit: 5,
        type: 'community',
        categoryId: recipeId,
      }),
    );
    expect(recipes.findOneForViewer).not.toHaveBeenCalled();
  });

  it.each([
    { q: ' ' },
    { q: 'soup', page: '0' },
    { q: 'soup', limit: '51' },
    { q: 'soup', type: 'invalid' },
    { q: 'soup', categoryId: 'invalid' },
  ])(
    'rejects invalid search query %j before calling the service',
    async (query) => {
      await request(app.getHttpServer())
        .get('/recipes/search')
        .query(query)
        .expect(400);
      expect(recipes.search).not.toHaveBeenCalled();
    },
  );

  it('keeps recipe browsing public and supplies the viewer identity when logged in', async () => {
    await request(app.getHttpServer()).get(`/recipes/${recipeId}`).expect(200);
    expect(recipes.findOneForViewer).toHaveBeenLastCalledWith(
      recipeId,
      undefined,
    );
    await request(app.getHttpServer())
      .get(`/recipes/${recipeId}`)
      .set('Authorization', 'Bearer test-user')
      .expect(200);
    expect(recipes.findOneForViewer).toHaveBeenLastCalledWith(recipeId, userId);
  });

  it('forwards all recipe listing filters', async () => {
    await request(app.getHttpServer())
      .get('/recipes')
      .query({
        search: 'soup',
        category: 'thai',
        categoryId: recipeId,
        creatorId: userId,
        status: 'published',
        type: 'community',
      })
      .expect(200);
    expect(recipes.findAll).toHaveBeenCalledWith({
      search: 'soup',
      category: 'thai',
      categoryId: recipeId,
      creatorId: userId,
      status: 'published',
      type: 'community',
    });
  });

  it('accepts nested recipe sections and validates their content', async () => {
    const body = {
      creatorId: userId,
      title: 'Soup',
      slug: 'soup',
      sections: [
        {
          title: 'Cook',
          isPreview: true,
          contents: [{ contentType: 'text', textContent: 'Stir' }],
        },
      ],
    };
    await request(app.getHttpServer())
      .post('/recipes')
      .send(body)
      .expect(201)
      .expect({ id: recipeId });
    expect(recipes.create).toHaveBeenCalledWith(expect.objectContaining(body));
    recipes.create.mockClear();
    await request(app.getHttpServer())
      .post('/recipes')
      .send({
        ...body,
        sections: [{ title: 'Cook', contents: [{ contentType: 'invalid' }] }],
      })
      .expect(400);
    expect(recipes.create).not.toHaveBeenCalled();
  });

  it('accepts partial edits while forbidding unexpected or invalid nested fields', async () => {
    await request(app.getHttpServer())
      .patch(`/recipes/${recipeId}`)
      .send({
        showImgCommu: true,
        sections: [
          {
            title: 'Tip',
            contents: [{ contentType: 'tip', textContent: 'Use fresh herbs' }],
          },
        ],
      })
      .expect(200);
    expect(recipes.update).toHaveBeenCalledWith(
      recipeId,
      expect.objectContaining({ showImgCommu: true }),
    );
    recipes.update.mockClear();
    for (const body of [
      { price: 'free' },
      { creatorId: userId },
      { sections: [{ title: '', contents: [] }] },
    ]) {
      await request(app.getHttpServer())
        .patch(`/recipes/${recipeId}`)
        .send(body)
        .expect(400);
    }
    expect(recipes.update).not.toHaveBeenCalled();
  });

  it('validates recipe IDs and maps missing recipes to HTTP 404', async () => {
    await request(app.getHttpServer()).get('/recipes/not-a-uuid').expect(400);
    expect(recipes.findOneForViewer).not.toHaveBeenCalled();
    recipes.findOneForViewer.mockRejectedValueOnce(
      new NotFoundException('missing'),
    );
    await request(app.getHttpServer()).get(`/recipes/${recipeId}`).expect(404);
    await request(app.getHttpServer())
      .delete(`/recipes/${recipeId}`)
      .expect(200);
    expect(recipes.remove).toHaveBeenCalledWith(recipeId);
  });

  it('uses comment pagination defaults and transforms explicit pagination', async () => {
    await request(app.getHttpServer())
      .get(`/recipes/${recipeId}/comments`)
      .expect(200);
    expect(comments.list).toHaveBeenLastCalledWith(
      recipeId,
      expect.objectContaining({ page: 1, limit: 3 }),
    );
    await request(app.getHttpServer())
      .get(`/recipes/${recipeId}/comments?page=2&limit=5`)
      .expect(200);
    expect(comments.list).toHaveBeenLastCalledWith(
      recipeId,
      expect.objectContaining({ page: 2, limit: 5 }),
    );
    await request(app.getHttpServer())
      .get(`/recipes/${recipeId}/comments?limit=51`)
      .expect(400);
  });

  it('requires authentication for comment mutation and scopes edits to the signed-in user', async () => {
    await request(app.getHttpServer())
      .post(`/recipes/${recipeId}/comments`)
      .send({ comment: 'Nice' })
      .expect(401);
    expect(comments.create).not.toHaveBeenCalled();
    await request(app.getHttpServer())
      .post(`/recipes/${recipeId}/comments`)
      .set('Authorization', 'Bearer test-user')
      .send({ comment: 'Nice' })
      .expect(201);
    expect(comments.create).toHaveBeenCalledWith(
      recipeId,
      userId,
      expect.objectContaining({ comment: 'Nice' }),
    );
    await request(app.getHttpServer())
      .patch(`/recipes/${recipeId}/comments/${commentId}`)
      .set('Authorization', 'Bearer test-user')
      .send({ comment: 'Updated' })
      .expect(200);
    expect(comments.update).toHaveBeenCalledWith(
      recipeId,
      commentId,
      userId,
      expect.objectContaining({ comment: 'Updated' }),
    );
    await request(app.getHttpServer())
      .delete(`/recipes/${recipeId}/comments/${commentId}`)
      .set('Authorization', 'Bearer test-user')
      .expect(200);
    expect(comments.remove).toHaveBeenCalledWith(recipeId, commentId, userId);
  });

  it('rejects empty comments and malformed comment IDs', async () => {
    await request(app.getHttpServer())
      .post(`/recipes/${recipeId}/comments`)
      .set('Authorization', 'Bearer test-user')
      .send({ comment: '' })
      .expect(400);
    await request(app.getHttpServer())
      .delete(`/recipes/${recipeId}/comments/invalid`)
      .set('Authorization', 'Bearer test-user')
      .expect(400);
    expect(comments.create).not.toHaveBeenCalled();
    expect(comments.remove).not.toHaveBeenCalled();
    await request(app.getHttpServer())
      .get(`/recipes/${recipeId}/comments/me`)
      .set('Authorization', 'Bearer test-user')
      .expect(200)
      .expect({ canComment: true, userAvatarUrl: null });
    expect(comments.getPermission).toHaveBeenCalledWith(recipeId, userId);
  });

  it('serves public review summaries and paginated reviews with numeric defaults', async () => {
    await request(app.getHttpServer())
      .get(`/recipes/${recipeId}/reviews`)
      .expect(200)
      .expect({ average: 0, count: 0 });
    await request(app.getHttpServer())
      .get(`/recipes/${recipeId}/reviews/list`)
      .expect(200);
    expect(reviews.listRecipeReviews).toHaveBeenLastCalledWith(
      recipeId,
      expect.objectContaining({ page: 1, limit: 20 }),
    );
    await request(app.getHttpServer())
      .get(`/recipes/${recipeId}/reviews/list?page=3&limit=4`)
      .expect(200);
    expect(reviews.listRecipeReviews).toHaveBeenLastCalledWith(
      recipeId,
      expect.objectContaining({ page: 3, limit: 4 }),
    );
    await request(app.getHttpServer())
      .get(`/recipes/${recipeId}/reviews/list?page=-1`)
      .expect(400);
  });

  it('scopes personal reviews to the signed-in user', async () => {
    await request(app.getHttpServer())
      .get(`/recipes/${recipeId}/reviews/me`)
      .expect(401);
    await request(app.getHttpServer())
      .get(`/recipes/${recipeId}/reviews/me`)
      .set('Authorization', 'Bearer test-user')
      .expect(200);
    expect(reviews.findMine).toHaveBeenCalledWith(recipeId, userId);
    await request(app.getHttpServer())
      .put(`/recipes/${recipeId}/reviews/me`)
      .set('Authorization', 'Bearer test-user')
      .send({ rating: 5, tags: ['tasty'], comment: 'Great' })
      .expect(200);
    expect(reviews.upsertMine).toHaveBeenCalledWith(
      recipeId,
      userId,
      expect.objectContaining({ rating: 5, tags: ['tasty'], comment: 'Great' }),
    );
  });

  it.each([
    { rating: 0 },
    { rating: 6 },
    { rating: 3.5 },
    { rating: 5, tags: ['unknown'] },
    { rating: 5, tags: ['tasty', 'tasty'] },
  ])('rejects invalid review %j', async (body) => {
    await request(app.getHttpServer())
      .put(`/recipes/${recipeId}/reviews/me`)
      .set('Authorization', 'Bearer test-user')
      .send(body)
      .expect(400);
    expect(reviews.upsertMine).not.toHaveBeenCalled();
  });

  it('accepts text and image-only chat requests', async () => {
    await request(app.getHttpServer())
      .post('/chat')
      .set('Authorization', 'Bearer test-user')
      .send({ recipeId, message: 'How?' })
      .expect(201)
      .expect({ message: 'Stir slowly' });
    expect(chat.chat).toHaveBeenLastCalledWith(
      userId,
      recipeId,
      'How?',
      undefined,
    );
    await request(app.getHttpServer())
      .post('/chat')
      .set('Authorization', 'Bearer test-user')
      .field('recipeId', recipeId)
      .attach('image', Buffer.from('image'), {
        filename: 'soup.png',
        contentType: 'image/png',
      })
      .expect(201);
    expect(chat.chat).toHaveBeenLastCalledWith(
      userId,
      recipeId,
      undefined,
      expect.objectContaining({
        mimetype: 'image/png',
        buffer: Buffer.from('image'),
      }),
    );
  });

  it('rejects chat requests without content, invalid images, and oversized attachments', async () => {
    await request(app.getHttpServer())
      .post('/chat')
      .set('Authorization', 'Bearer test-user')
      .send({ recipeId })
      .expect(400);
    await request(app.getHttpServer())
      .post('/chat')
      .set('Authorization', 'Bearer test-user')
      .field('recipeId', recipeId)
      .attach('image', Buffer.from('file'), {
        filename: 'file.txt',
        contentType: 'text/plain',
      })
      .expect(400);
    await request(app.getHttpServer())
      .post('/chat')
      .set('Authorization', 'Bearer test-user')
      .field('recipeId', recipeId)
      .attach('image', Buffer.alloc(5 * 1024 * 1024 + 1), {
        filename: 'big.png',
        contentType: 'image/png',
      })
      .expect(413);
    expect(chat.chat).not.toHaveBeenCalled();
  });

  it('returns chat permission and history and resets only the current user session', async () => {
    await request(app.getHttpServer())
      .get(`/chat/recipes/${recipeId}/permission`)
      .set('Authorization', 'Bearer test-user')
      .expect(200)
      .expect({ canChat: true });
    await request(app.getHttpServer())
      .get(`/chat/recipes/${recipeId}/history`)
      .set('Authorization', 'Bearer test-user')
      .expect(200)
      .expect({ messages: [{ role: 'user', content: 'How?' }] });
    await request(app.getHttpServer())
      .delete('/chat')
      .set('Authorization', 'Bearer test-user')
      .expect(200)
      .expect({ success: true });
    expect(chat.canChat).toHaveBeenCalledWith(userId, recipeId);
    expect(chat.getHistory).toHaveBeenCalledWith(userId, recipeId);
    expect(chat.reset).toHaveBeenCalledWith(userId);
  });

  it('passes category type/status filters through both list and detail routes', async () => {
    await request(app.getHttpServer())
      .get('/categories?type=community&status=published')
      .expect(200);
    expect(categories.findAll).toHaveBeenCalledWith('community', 'published');
    await request(app.getHttpServer())
      .get(`/categories/${recipeId}?type=official&status=draft`)
      .expect(200);
    expect(categories.findOne).toHaveBeenCalledWith(
      recipeId,
      'official',
      'draft',
    );
  });
});
