/* eslint-disable @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access -- Jest module mocks and asymmetric matchers are dynamically typed. */
import {
  ForbiddenException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RecipeAccessService } from '../recipe-access/recipe-access.service';
import { RecipeContentType } from '../recipes/entities/recipe-content.entity';
import { Recipe, RecipeType } from '../recipes/entities/recipe.entity';
import { RecipesService } from '../recipes/recipes.service';
import { ChatService } from './chat.service';

const mockGet = jest.fn();
const mockSet = jest.fn();
const mockDel = jest.fn();
const mockQuit = jest.fn();
const mockCreate = jest.fn();

jest.mock('ioredis', () => ({
  __esModule: true,
  default: jest.fn().mockImplementation(() => ({
    get: (...args: unknown[]) => mockGet(...args),
    set: (...args: unknown[]) => mockSet(...args),
    del: (...args: unknown[]) => mockDel(...args),
    quit: (...args: unknown[]) => mockQuit(...args),
  })),
}));

jest.mock('openai', () => ({
  __esModule: true,
  default: jest.fn().mockImplementation(() => ({
    chat: {
      completions: { create: (...args: unknown[]) => mockCreate(...args) },
    },
  })),
}));

describe('ChatService', () => {
  const recipes = { findOne: jest.fn() };
  const access = { hasActiveAccess: jest.fn() };
  const config = {
    get: jest.fn((key: string) =>
      key === 'PSU_AI_API_KEY' ? 'test-key' : undefined,
    ),
  };
  let service: ChatService;

  const recipe = {
    id: 'recipe-1',
    title: 'Soup',
    type: RecipeType.OFFICIAL,
    creatorId: 'owner',
    shortDescription: 'Warm soup',
    preparationMinutes: 5,
    cookingMinutes: 10,
    servingCount: 2,
    difficulty: 'easy',
    recipeIngredients: [
      {
        sortOrder: 2,
        amount: 1,
        unit: 'cup',
        preparationNote: 'chopped',
        isOptional: true,
        ingredient: { name: 'Carrot' },
      },
      { sortOrder: 1, amount: 2, unit: 'cups', ingredient: { name: 'Water' } },
    ],
    sections: [
      {
        title: 'Cook',
        description: 'Slowly',
        contents: [
          { contentType: RecipeContentType.TIP, textContent: 'Stir' },
          { contentType: RecipeContentType.WARNING, textContent: 'Hot' },
          { textContent: '' },
        ],
      },
    ],
  } as unknown as Recipe;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new ChatService(
      config as unknown as ConfigService,
      recipes as unknown as RecipesService,
      access as unknown as RecipeAccessService,
    );
    recipes.findOne.mockResolvedValue(recipe);
    access.hasActiveAccess.mockResolvedValue(true);
    mockGet.mockResolvedValue(null);
    mockSet.mockResolvedValue('OK');
    mockDel.mockResolvedValue(1);
    mockQuit.mockResolvedValue('OK');
    mockCreate.mockResolvedValue(
      // eslint-disable-next-line @typescript-eslint/require-await -- Async iteration is required by the streaming API.
      (async function* () {
        yield { choices: [{ delta: { content: 'Try ' } }] };
        yield { choices: [{ delta: { content: 'stirring' } }] };
      })(),
    );
  });

  it('starts an authorized session with recipe context and saves the streamed reply', async () => {
    await expect(service.chat('buyer', 'recipe-1', 'How?')).resolves.toEqual({
      message: 'Try stirring',
    });
    expect(access.hasActiveAccess).toHaveBeenCalledWith('buyer', 'recipe-1');
    expect(mockCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        stream: true,
        messages: expect.arrayContaining([
          expect.objectContaining({
            role: 'system',
            content: expect.stringContaining('ชื่อเมนู: Soup'),
          }),
          { role: 'user', content: [{ type: 'text', text: 'How?' }] },
        ]),
      }),
    );
    const saved = JSON.parse(mockSet.mock.lastCall?.[1] as string) as {
      history: unknown[];
      instructions: string;
    };
    expect(saved.instructions).toContain('Water 2 cups');
    expect(saved.instructions).toContain('เคล็ดลับ: Stir');
    expect(saved.history).toEqual([
      { role: 'user', content: 'How?' },
      { role: 'assistant', content: 'Try stirring' },
    ]);
    expect(mockSet).toHaveBeenCalledWith(
      'chat:session:buyer',
      expect.any(String),
      'EX',
      1200,
    );
  });

  it('reuses history for the same recipe and records an image placeholder', async () => {
    mockGet.mockResolvedValue(
      JSON.stringify({
        recipeId: 'recipe-1',
        instructions: 'saved instructions',
        history: [{ role: 'assistant', content: 'previous' }],
      }),
    );
    await service.chat('owner', 'recipe-1', 'Is this done?', {
      mimetype: 'image/png',
      buffer: Buffer.from('image'),
    });
    expect(recipes.findOne).not.toHaveBeenCalled();
    expect(mockCreate.mock.calls[0][0].messages).toEqual([
      { role: 'system', content: 'saved instructions' },
      { role: 'assistant', content: 'previous' },
      {
        role: 'user',
        content: [
          { type: 'text', text: 'Is this done?' },
          {
            type: 'image_url',
            image_url: { url: 'data:image/png;base64,aW1hZ2U=' },
          },
        ],
      },
    ]);
    const saved = JSON.parse(mockSet.mock.lastCall?.[1] as string) as {
      history: { content: string }[];
    };
    expect(saved.history[1].content).toBe('Is this done? [แนบรูปภาพ]');
  });

  it('rejects community recipes and unpaid official recipes', async () => {
    recipes.findOne.mockResolvedValueOnce({
      ...recipe,
      type: RecipeType.COMMUNITY,
    });
    await expect(
      service.chat('buyer', 'recipe-1', 'Hi'),
    ).rejects.toBeInstanceOf(ForbiddenException);
    access.hasActiveAccess.mockResolvedValue(false);
    await expect(
      service.chat('buyer', 'recipe-1', 'Hi'),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('does not save a reply when the AI stream fails', async () => {
    mockCreate.mockRejectedValue(new Error('upstream down'));
    await expect(
      service.chat('owner', 'recipe-1', 'Hi'),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(mockSet).toHaveBeenCalledTimes(1); // session initialization only
  });

  it('checks access, isolates history by recipe, and resets the session', async () => {
    expect(await service.canChat('owner', 'recipe-1')).toBe(true);
    recipes.findOne.mockResolvedValueOnce({
      ...recipe,
      type: RecipeType.COMMUNITY,
    });
    expect(await service.canChat('owner', 'recipe-1')).toBe(false);
    mockGet.mockResolvedValue(
      JSON.stringify({
        recipeId: 'recipe-1',
        history: [{ role: 'user', content: 'Hi' }],
      }),
    );
    expect(await service.getHistory('owner', 'recipe-1')).toEqual([
      { role: 'user', content: 'Hi' },
    ]);
    expect(await service.getHistory('owner', 'recipe-2')).toEqual([]);
    await service.reset('owner');
    await service.onModuleDestroy();
    expect(mockDel).toHaveBeenCalledWith('chat:session:owner');
    expect(mockQuit).toHaveBeenCalledTimes(1);
  });
});
