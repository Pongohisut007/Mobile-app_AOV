import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RecipeAccessService } from '../recipe-access/recipe-access.service';
import { Recipe } from '../recipes/entities/recipe.entity';
import { ListReviewsQueryDto } from './dto/list-reviews-query.dto';
import { UpsertReviewDto } from './dto/upsert-review.dto';
import { Review, ReviewStatus } from './entities/review.entity';

// หน้าสูตรโชว์รีวิวล่าสุดแค่นี้ ที่เหลือดูในหน้ารีวิวทั้งหมด
const LATEST_REVIEWS_LIMIT = 3;

export interface ReviewView {
  id: string;
  rating: number;
  comment: string | null;
  tags: string[];
  createdAt: Date;
  user: { id: string; displayName: string; avatarUrl: string | null };
}

export interface RecipeReviewSummary {
  average: number;
  count: number;
  // จำนวนรีวิวของแต่ละดาว key คือ 1-5
  distribution: Record<1 | 2 | 3 | 4 | 5, number>;
  reviews: ReviewView[];
}

export interface ReviewPage {
  items: ReviewView[];
  total: number;
  page: number;
  limit: number;
}

export interface MyReviewResponse {
  // ให้คะแนนได้เฉพาะคนที่มีสิทธิ์เข้าถึงสูตร (ซื้อแล้ว)
  canReview: boolean;
  review: ReviewView | null;
}

@Injectable()
export class ReviewsService {
  constructor(
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
    @InjectRepository(Recipe)
    private readonly recipeRepository: Repository<Recipe>,
    private readonly recipeAccessService: RecipeAccessService,
  ) {}

  findAll(recipeId?: string): Promise<Review[]> {
    return this.reviewRepository.find({
      where: recipeId ? { recipeId } : {},
      relations: { user: true },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Review> {
    const review = await this.reviewRepository.findOne({
      where: { id },
      relations: { user: true, recipe: true },
    });
    if (!review) throw new NotFoundException(`Review with id ${id} not found`);
    return review;
  }

  // คะแนนเฉลี่ยและรีวิวล่าสุด นับเฉพาะรีวิวที่ไม่ถูกซ่อน
  async getRecipeSummary(recipeId: string): Promise<RecipeReviewSummary> {
    await this.ensureRecipeExists(recipeId);

    const rows = await this.reviewRepository
      .createQueryBuilder('review')
      .select('review.rating', 'rating')
      .addSelect('COUNT(*)', 'count')
      .where('review.recipe_id = :recipeId', { recipeId })
      .andWhere('review.status = :status', { status: ReviewStatus.PUBLISHED })
      .groupBy('review.rating')
      .getRawMany<{ rating: number | string; count: string }>();

    const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    let count = 0;
    let total = 0;
    for (const row of rows) {
      const rating = Number(row.rating) as keyof typeof distribution;
      const rowCount = Number(row.count);
      if (!(rating in distribution)) continue;
      distribution[rating] = rowCount;
      count += rowCount;
      total += rating * rowCount;
    }

    const reviews = await this.reviewRepository.find({
      where: { recipeId, status: ReviewStatus.PUBLISHED },
      relations: { user: true },
      order: { updatedAt: 'DESC' },
      take: LATEST_REVIEWS_LIMIT,
    });

    return {
      // ปัดเหลือทศนิยม 1 ตำแหน่ง เช่น 4.3
      average: count === 0 ? 0 : Math.round((total / count) * 10) / 10,
      count,
      distribution,
      reviews: reviews.map((review) => this.toView(review)),
    };
  }

  // หน้ารีวิวทั้งหมด เลื่อนโหลดทีละหน้า
  async listRecipeReviews(
    recipeId: string,
    query: ListReviewsQueryDto,
  ): Promise<ReviewPage> {
    await this.ensureRecipeExists(recipeId);

    const [reviews, total] = await this.reviewRepository.findAndCount({
      where: { recipeId, status: ReviewStatus.PUBLISHED },
      relations: { user: true },
      order: { updatedAt: 'DESC', id: 'DESC' },
      skip: (query.page - 1) * query.limit,
      take: query.limit,
    });

    return {
      items: reviews.map((review) => this.toView(review)),
      total,
      page: query.page,
      limit: query.limit,
    };
  }

  async findMine(recipeId: string, userId: string): Promise<MyReviewResponse> {
    await this.ensureRecipeExists(recipeId);

    const [canReview, review] = await Promise.all([
      this.recipeAccessService.hasActiveAccess(userId, recipeId),
      this.reviewRepository.findOne({
        where: { recipeId, userId },
        relations: { user: true },
      }),
    ]);
    return { canReview, review: review ? this.toView(review) : null };
  }

  // ให้ครั้งแรกหรือแก้รีวิวเดิม ไม่แตะ status รีวิวที่ถูกซ่อนจะยังถูกซ่อนอยู่
  async upsertMine(
    recipeId: string,
    userId: string,
    dto: UpsertReviewDto,
  ): Promise<ReviewView> {
    await this.ensureRecipeExists(recipeId);

    const canReview = await this.recipeAccessService.hasActiveAccess(
      userId,
      recipeId,
    );
    if (!canReview) {
      throw new ForbiddenException('Buy this recipe before reviewing it');
    }

    const comment = dto.comment?.trim() || null;
    const tags = dto.tags ?? [];
    await this.reviewRepository.upsert(
      { recipeId, userId, rating: dto.rating, comment, tags },
      { conflictPaths: ['userId', 'recipeId'] },
    );

    const saved = await this.reviewRepository.findOneOrFail({
      where: { recipeId, userId },
      relations: { user: true },
    });
    return this.toView(saved);
  }

  private async ensureRecipeExists(recipeId: string): Promise<void> {
    const exists = await this.recipeRepository.exists({
      where: { id: recipeId },
    });
    if (!exists) {
      throw new NotFoundException(`Recipe with id ${recipeId} not found`);
    }
  }

  // ไม่ส่ง email ของคนรีวิวออกไป
  private toView(review: Review): ReviewView {
    return {
      id: review.id,
      rating: review.rating,
      comment: review.comment,
      tags: review.tags ?? [],
      createdAt: review.updatedAt,
      user: {
        id: review.user.id,
        displayName: review.user.displayName,
        avatarUrl: review.user.avatarUrl,
      },
    };
  }
}
