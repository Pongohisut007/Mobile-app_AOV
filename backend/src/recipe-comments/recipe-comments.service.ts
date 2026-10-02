import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RecipeAccessService } from '../recipe-access/recipe-access.service';
import { Recipe, RecipeType } from '../recipes/entities/recipe.entity';
import { User } from '../users/entities/user.entity';
import { CreateRecipeCommentDto } from './dto/create-recipe-comment.dto';
import { ListRecipeCommentsQueryDto } from './dto/list-recipe-comments-query.dto';
import { RecipeComment } from './entities/recipe-comment.entity';

export interface RecipeCommentView {
  id: string;
  comment: string;
  createdAt: Date;
  user: { id: string; displayName: string; avatarUrl: string | null };
}

export interface RecipeCommentPage {
  items: RecipeCommentView[];
  total: number;
  page: number;
  limit: number;
}

export interface RecipeCommentPermission {
  canComment: boolean;
  userAvatarUrl: string | null;
}

@Injectable()
export class RecipeCommentsService {
  constructor(
    @InjectRepository(RecipeComment)
    private readonly commentRepository: Repository<RecipeComment>,
    @InjectRepository(Recipe)
    private readonly recipeRepository: Repository<Recipe>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly recipeAccessService: RecipeAccessService,
  ) {}

  async list(
    recipeId: string,
    query: ListRecipeCommentsQueryDto,
  ): Promise<RecipeCommentPage> {
    await this.getRecipe(recipeId);

    const [comments, total] = await this.commentRepository.findAndCount({
      where: { recipeId },
      relations: { user: true },
      order: { createdAt: 'DESC', id: 'DESC' },
      skip: (query.page - 1) * query.limit,
      take: query.limit,
    });

    return {
      items: comments.map((comment) => this.toView(comment)),
      total,
      page: query.page,
      limit: query.limit,
    };
  }

  async getPermission(
    recipeId: string,
    userId: string,
  ): Promise<RecipeCommentPermission> {
    const recipe = await this.getRecipe(recipeId);
    const user = await this.userRepository.findOne({
      where: { id: userId },
      select: { id: true, avatarUrl: true },
    });
    if (!user) throw new NotFoundException(`User with id ${userId} not found`);

    return {
      canComment:
        recipe.type === RecipeType.COMMUNITY ||
        (await this.recipeAccessService.hasActiveAccess(userId, recipeId)),
      userAvatarUrl: user.avatarUrl,
    };
  }

  async create(
    recipeId: string,
    userId: string,
    dto: CreateRecipeCommentDto,
  ): Promise<RecipeCommentView> {
    const recipe = await this.getRecipe(recipeId);

    const canComment =
      recipe.type === RecipeType.COMMUNITY ||
      (await this.recipeAccessService.hasActiveAccess(userId, recipeId));
    if (!canComment) {
      throw new ForbiddenException('Buy this recipe before commenting');
    }

    const comment = dto.comment.trim();
    if (!comment) throw new BadRequestException('Comment cannot be empty');

    const saved = await this.commentRepository.save(
      this.commentRepository.create({ recipeId, userId, comment }),
    );
    const created = await this.commentRepository.findOneOrFail({
      where: { id: saved.id },
      relations: { user: true },
    });
    return this.toView(created);
  }

  async update(
    recipeId: string,
    commentId: string,
    userId: string,
    dto: CreateRecipeCommentDto,
  ): Promise<RecipeCommentView> {
    const comment = await this.findOwnedComment(recipeId, commentId, userId);
    const text = dto.comment.trim();
    if (!text) throw new BadRequestException('Comment cannot be empty');

    comment.comment = text;
    const updated = await this.commentRepository.save(comment);
    return this.toView(updated);
  }

  async remove(
    recipeId: string,
    commentId: string,
    userId: string,
  ): Promise<void> {
    const comment = await this.findOwnedComment(recipeId, commentId, userId);
    await this.commentRepository.remove(comment);
  }

  private async findOwnedComment(
    recipeId: string,
    commentId: string,
    userId: string,
  ): Promise<RecipeComment> {
    const comment = await this.commentRepository.findOne({
      where: { id: commentId, recipeId },
      relations: { user: true },
    });
    if (!comment) {
      throw new NotFoundException(`Comment with id ${commentId} not found`);
    }
    if (comment.userId !== userId) {
      throw new ForbiddenException('You can only change your own comments');
    }
    return comment;
  }

  private async getRecipe(recipeId: string): Promise<Recipe> {
    const recipe = await this.recipeRepository.findOne({
      where: { id: recipeId },
      select: { id: true, type: true },
    });
    if (!recipe) {
      throw new NotFoundException(`Recipe with id ${recipeId} not found`);
    }
    return recipe;
  }

  private toView(comment: RecipeComment): RecipeCommentView {
    return {
      id: comment.id,
      comment: comment.comment,
      createdAt: comment.createdAt,
      user: {
        id: comment.user.id,
        displayName: comment.user.displayName,
        avatarUrl: comment.user.avatarUrl,
      },
    };
  }
}
