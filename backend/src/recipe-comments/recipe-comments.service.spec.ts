import { ForbiddenException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { RecipeAccessService } from '../recipe-access/recipe-access.service';
import { Recipe } from '../recipes/entities/recipe.entity';
import { User } from '../users/entities/user.entity';
import { RecipeComment } from './entities/recipe-comment.entity';
import { RecipeCommentsService } from './recipe-comments.service';

describe('RecipeCommentsService comment ownership', () => {
  const commentsRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
    remove: jest.fn(),
  };

  const service = new RecipeCommentsService(
    commentsRepository as unknown as Repository<RecipeComment>,
    {} as Repository<Recipe>,
    {} as Repository<User>,
    {} as RecipeAccessService,
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
});
