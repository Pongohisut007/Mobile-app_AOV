import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { CacheNamespace } from '../cache/app-cache.module';
import { AppCacheService } from '../cache/app-cache.service';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RecipeAccessService } from '../recipe-access/recipe-access.service';
import { Recipe, RecipeType } from '../recipes/entities/recipe.entity';
import { canReadRecipe } from '../recipes/recipe-permissions';
import { User } from '../users/entities/user.entity';
import { CreateRecipeCommentDto } from './dto/create-recipe-comment.dto';
import { ListRecipeCommentsQueryDto } from './dto/list-recipe-comments-query.dto';
import { RecipeComment } from './entities/recipe-comment.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/entities/notification.entity';
import { excerpt } from '../notifications/notification-text';

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
    @Optional()
    private readonly cache?: AppCacheService,
    @Optional()
    private readonly notifications?: NotificationsService,
  ) {}

  // ยอดคอมเมนต์อยู่ในข้อมูลสูตรที่ cache ไว้ เพิ่ม/ลบคอมเมนต์ต้องล้างทั้งคู่
  private async invalidateRecipeCounts(): Promise<void> {
    await Promise.all([
      this.cache?.invalidate(CacheNamespace.comments),
      this.cache?.invalidate(CacheNamespace.recipes),
    ]);
  }

  async list(
    recipeId: string,
    query: ListRecipeCommentsQueryDto,
    viewerId?: string,
  ): Promise<RecipeCommentPage> {
    // ตรวจก่อนอ่าน cache: cache เก็บรวมทุกคน แต่สิทธิ์อ่านขึ้นกับผู้ชม
    await this.assertReadable(recipeId, viewerId);
    const load = () => this.loadList(recipeId, query);
    return this.cache
      ? this.cache.getOrSet(
          CacheNamespace.comments,
          `list:${recipeId}:${query.page}:${query.limit}`,
          60,
          load,
        )
      : load();
  }

  private async loadList(
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
    await this.invalidateRecipeCounts();
    await this.notifications?.notifyRecipeOwner({
      type: NotificationType.RECIPE_COMMENTED,
      recipeId,
      actorId: userId,
      data: { excerpt: excerpt(comment) },
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
    await this.cache?.invalidate(CacheNamespace.comments);
    return this.toView(updated);
  }

  async remove(
    recipeId: string,
    commentId: string,
    userId: string,
  ): Promise<void> {
    const comment = await this.findOwnedComment(recipeId, commentId, userId);
    await this.commentRepository.remove(comment);
    await this.invalidateRecipeCounts();
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

  /** สูตรที่ยังไม่เผยแพร่ ตอบเหมือนไม่มีสูตรนี้ (ยกเว้นเจ้าของ/คนที่ซื้อแล้ว) */
  private async assertReadable(
    recipeId: string,
    viewerId?: string,
  ): Promise<void> {
    const recipe = await this.recipeRepository.findOne({
      where: { id: recipeId },
      select: { id: true, status: true, creatorId: true },
    });
    if (
      !recipe ||
      !(await canReadRecipe(recipe, viewerId, (userId, id) =>
        this.recipeAccessService.hasActiveAccess(userId, id),
      ))
    ) {
      throw new NotFoundException(`Recipe with id ${recipeId} not found`);
    }
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
