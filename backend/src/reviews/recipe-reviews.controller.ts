import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { RateLimit } from '../common/throttle/rate-limits';
import { ListReviewsQueryDto } from './dto/list-reviews-query.dto';
import { UpsertReviewDto } from './dto/upsert-review.dto';
import {
  MyReviewResponse,
  RecipeReviewSummary,
  ReviewPage,
  ReviewsService,
  ReviewView,
} from './reviews.service';

@Controller('recipes/:recipeId/reviews')
export class RecipeReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  // ใครก็ดูคะแนนเฉลี่ยและรีวิวได้ ไม่ต้องล็อกอิน (สูตรที่เผยแพร่แล้ว)
  @UseGuards(OptionalJwtAuthGuard)
  @Get()
  getSummary(
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @CurrentUser('id') viewerId?: string,
  ): Promise<RecipeReviewSummary> {
    return this.reviewsService.getRecipeSummary(recipeId, viewerId);
  }

  // หน้ารีวิวทั้งหมด: ?page=1&limit=20
  @UseGuards(OptionalJwtAuthGuard)
  @Get('list')
  list(
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @Query() query: ListReviewsQueryDto,
    @CurrentUser('id') viewerId?: string,
  ): Promise<ReviewPage> {
    return this.reviewsService.listRecipeReviews(recipeId, query, viewerId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  findMine(
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @CurrentUser('id') userId: string,
  ): Promise<MyReviewResponse> {
    return this.reviewsService.findMine(recipeId, userId);
  }

  // ให้คะแนนครั้งแรกหรือแก้คะแนนเดิมใช้ route เดียวกัน ต้องซื้อสูตรแล้ว
  @UseGuards(JwtAuthGuard)
  @RateLimit('write')
  @Put('me')
  upsertMine(
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: UpsertReviewDto,
  ): Promise<ReviewView> {
    return this.reviewsService.upsertMine(recipeId, userId, dto);
  }
}
