import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Repository } from 'typeorm';
import { RecipeAccessService } from '../recipe-access/recipe-access.service';
import { Recipe } from '../recipes/entities/recipe.entity';
import { RecipeType } from '../recipes/entities/recipe.entity';
import { User } from '../users/entities/user.entity';
import { RecipeComment } from './entities/recipe-comment.entity';
import { RecipeCommentsService } from './recipe-comments.service';

describe('RecipeCommentsService comment ownership', () => {
  const commentsRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
    remove: jest.fn(),
    findAndCount: jest.fn(),
    create: jest.fn(),
    findOneOrFail: jest.fn(),
  };
  const recipesRepository = { findOne: jest.fn() };
  const usersRepository = { findOne: jest.fn() };
  const access = { hasActiveAccess: jest.fn() };

  const service = new RecipeCommentsService(
    commentsRepository as unknown as Repository<RecipeComment>,
    recipesRepository as unknown as Repository<Recipe>,
    usersRepository as unknown as Repository<User>,
    access as unknown as RecipeAccessService,
  );

  const comment = {
    id: 'comment-id',
    recipeId: 'recipe-id',
    userId: 'owner-id',
    comment: 'Original comment',
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    user: {
      id: 'owner-id',
      displayName: 'Owner',
      avatarUrl: null,
    },
  } as RecipeComment;

  beforeEach(() => {
    jest.clearAllMocks();
    commentsRepository.findOne.mockResolvedValue({
      ...comment,
      user: comment.user,
    });
    commentsRepository.save.mockImplementation((value: RecipeComment) =>
      Promise.resolve(value),
    );
    commentsRepository.remove.mockResolvedValue(comment);
    commentsRepository.create.mockImplementation(
      (value: RecipeComment) => value,
    );
    commentsRepository.findOneOrFail.mockResolvedValue(comment);
    commentsRepository.findAndCount.mockResolvedValue([[comment], 1]);
    recipesRepository.findOne.mockResolvedValue({
      id: 'recipe-id',
      type: RecipeType.COMMUNITY,
    });
    usersRepository.findOne.mockResolvedValue({
      id: 'owner-id',
      avatarUrl: 'avatar.png',
    });
    access.hasActiveAccess.mockResolvedValue(true);
  });

  it('allows the owner to edit a comment', async () => {
    const result = await service.update('recipe-id', 'comment-id', 'owner-id', {
      comment: '  Updated comment  ',
    });

    expect(result.comment).toBe('Updated comment');
    expect(commentsRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({ comment: 'Updated comment' }),
    );
  });

  it('rejects another user editing the comment', async () => {
    await expect(
      service.update('recipe-id', 'comment-id', 'other-id', {
        comment: 'Unauthorized edit',
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(commentsRepository.save).not.toHaveBeenCalled();
  });

  it('allows the owner to delete a comment', async () => {
    await service.remove('recipe-id', 'comment-id', 'owner-id');

    expect(commentsRepository.remove).toHaveBeenCalledWith(
      expect.objectContaining({ id: 'comment-id' }),
    );
  });

  it('rejects another user deleting the comment', async () => {
    await expect(
      service.remove('recipe-id', 'comment-id', 'other-id'),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(commentsRepository.remove).not.toHaveBeenCalled();
  });

  it('lists a page of comments with public author fields', async () => {
    recipesRepository.findOne.mockResolvedValue({
      id: 'recipe-id',
      status: 'published',
      creatorId: 'creator-id',
    });
    const result = await service.list('recipe-id', { page: 2, limit: 5 });
    expect(commentsRepository.findAndCount).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { recipeId: 'recipe-id' },
        skip: 5,
        take: 5,
        order: { createdAt: 'DESC', id: 'DESC' },
      }),
    );
    expect(result).toEqual({
      items: [
        {
          id: 'comment-id',
          comment: 'Original comment',
          createdAt: comment.createdAt,
          user: { id: 'owner-id', displayName: 'Owner', avatarUrl: null },
        },
      ],
      total: 1,
      page: 2,
      limit: 5,
    });
  });

  it('returns permission for community and purchased official recipes', async () => {
    expect(await service.getPermission('recipe-id', 'owner-id')).toEqual({
      canComment: true,
      userAvatarUrl: 'avatar.png',
    });
    expect(access.hasActiveAccess).not.toHaveBeenCalled();
    recipesRepository.findOne.mockResolvedValue({
      id: 'recipe-id',
      type: RecipeType.OFFICIAL,
    });
    expect(await service.getPermission('recipe-id', 'owner-id')).toEqual({
      canComment: true,
      userAvatarUrl: 'avatar.png',
    });
    expect(access.hasActiveAccess).toHaveBeenCalledWith(
      'owner-id',
      'recipe-id',
    );
  });

  it('creates a trimmed comment for an authorized user', async () => {
    commentsRepository.save.mockResolvedValueOnce(comment);
    const result = await service.create('recipe-id', 'owner-id', {
      comment: '  Nice recipe  ',
    });
    expect(commentsRepository.create).toHaveBeenCalledWith({
      recipeId: 'recipe-id',
      userId: 'owner-id',
      comment: 'Nice recipe',
    });
    expect(commentsRepository.findOneOrFail).toHaveBeenCalledWith({
      where: { id: 'comment-id' },
      relations: { user: true },
    });
    expect(result.id).toBe('comment-id');
  });

  it('rejects empty text and users without recipe access', async () => {
    await expect(
      service.create('recipe-id', 'owner-id', { comment: '   ' }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.update('recipe-id', 'comment-id', 'owner-id', { comment: '   ' }),
    ).rejects.toBeInstanceOf(BadRequestException);
    recipesRepository.findOne.mockResolvedValue({
      id: 'recipe-id',
      type: RecipeType.OFFICIAL,
    });
    access.hasActiveAccess.mockResolvedValue(false);
    await expect(
      service.create('recipe-id', 'owner-id', { comment: 'Hello' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(commentsRepository.save).not.toHaveBeenCalled();
  });

  it('reports missing recipes, users, and comments', async () => {
    recipesRepository.findOne.mockResolvedValue(null);
    await expect(
      service.list('missing', { page: 1, limit: 5 }),
    ).rejects.toBeInstanceOf(NotFoundException);
    recipesRepository.findOne.mockResolvedValue({
      id: 'recipe-id',
      type: RecipeType.COMMUNITY,
    });
    usersRepository.findOne.mockResolvedValue(null);
    await expect(
      service.getPermission('recipe-id', 'missing'),
    ).rejects.toBeInstanceOf(NotFoundException);
    commentsRepository.findOne.mockResolvedValue(null);
    await expect(
      service.remove('recipe-id', 'missing', 'owner-id'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
