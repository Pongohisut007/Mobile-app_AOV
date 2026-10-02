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

  @Get()
  list(
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @Query() query: ListRecipeCommentsQueryDto,
  ): Promise<RecipeCommentPage> {
    return this.commentsService.list(recipeId, query);
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
  @Post()
  create(
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CreateRecipeCommentDto,
  ): Promise<RecipeCommentView> {
    return this.commentsService.create(recipeId, userId, dto);
  }

  @UseGuards(JwtAuthGuard)
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
