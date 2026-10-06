import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { RateLimit } from '../common/throttle/rate-limits';
import { CreateRecipeCommentDto } from './dto/create-recipe-comment.dto';
import { ListRecipeCommentsQueryDto } from './dto/list-recipe-comments-query.dto';
import {
  RecipeCommentPage,
  RecipeCommentPermission,
  RecipeCommentsService,
  RecipeCommentView,
} from './recipe-comments.service';

@Controller('recipes/:recipeId/comments')
export class RecipeCommentsController {
  constructor(private readonly commentsService: RecipeCommentsService) {}

  // login ไม่บังคับ: สูตรที่ยังไม่เผยแพร่ เจ้าของ/คนที่ซื้อแล้วต้องแนบ token มา
  @UseGuards(OptionalJwtAuthGuard)
  @Get()
  list(
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @Query() query: ListRecipeCommentsQueryDto,
    @CurrentUser('id') viewerId?: string,
  ): Promise<RecipeCommentPage> {
    return this.commentsService.list(recipeId, query, viewerId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  getPermission(
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @CurrentUser('id') userId: string,
  ): Promise<RecipeCommentPermission> {
    return this.commentsService.getPermission(recipeId, userId);
  }

  @UseGuards(JwtAuthGuard)
  @RateLimit('write')
  @Post()
  create(
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CreateRecipeCommentDto,
  ): Promise<RecipeCommentView> {
    return this.commentsService.create(recipeId, userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @RateLimit('write')
  @Patch(':commentId')
  update(
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @Param('commentId', ParseUUIDPipe) commentId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CreateRecipeCommentDto,
  ): Promise<RecipeCommentView> {
    return this.commentsService.update(recipeId, commentId, userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':commentId')
  remove(
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @Param('commentId', ParseUUIDPipe) commentId: string,
    @CurrentUser('id') userId: string,
  ): Promise<void> {
    return this.commentsService.remove(recipeId, commentId, userId);
  }
}
