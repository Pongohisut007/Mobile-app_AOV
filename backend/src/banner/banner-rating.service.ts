import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RateBannerDto } from './dto/rate-banner.dto';
import { BannerRating } from './entities/banner-rating.entity';
import { Banner } from './entities/banner.entity';

// แสดงความคิดเห็นล่าสุดบนหน้า event แค่นี้พอ
const LATEST_RATINGS_LIMIT = 20;

export interface BannerRatingView {
  id: string;
  rating: number;
  comment: string | null;
  createdAt: Date;
  user: { id: string; displayName: string; avatarUrl: string | null };
}

export interface BannerRatingSummary {
  average: number;
  count: number;
  ratings: BannerRatingView[];
}

@Injectable()
export class BannerRatingService {
  constructor(
    @InjectRepository(Banner)
    private readonly bannerRepository: Repository<Banner>,
    @InjectRepository(BannerRating)
    private readonly ratingRepository: Repository<BannerRating>,
  ) {}

  async getSummary(bannerId: string): Promise<BannerRatingSummary> {
    await this.ensureBannerExists(bannerId);

    const stats = await this.ratingRepository
      .createQueryBuilder('rating')
      .select('AVG(rating.rating)', 'average')
      .addSelect('COUNT(*)', 'count')
      .where('rating.bannerId = :bannerId', { bannerId })
      .getRawOne<{ average: string | null; count: string }>();

    const ratings = await this.ratingRepository.find({
      where: { bannerId },
      relations: { user: true },
      order: { updatedAt: 'DESC' },
      take: LATEST_RATINGS_LIMIT,
    });

    return {
      // ปัดเหลือทศนิยม 1 ตำแหน่ง เช่น 4.3
      average: Math.round(Number(stats?.average ?? 0) * 10) / 10,
      count: Number(stats?.count ?? 0),
      ratings: ratings.map((rating) => this.toView(rating)),
    };
  }

  // ยังไม่เคยให้คะแนน = null
  async findMine(
    bannerId: string,
    userId: string,
  ): Promise<BannerRatingView | null> {
    await this.ensureBannerExists(bannerId);

    const rating = await this.ratingRepository.findOne({
      where: { bannerId, userId },
      relations: { user: true },
    });
    return rating ? this.toView(rating) : null;
  }

  async rate(
    bannerId: string,
    userId: string,
    dto: RateBannerDto,
  ): Promise<BannerRatingView> {
    await this.ensureBannerExists(bannerId);

    const comment = dto.comment?.trim() || null;
    await this.ratingRepository.upsert(
      { bannerId, userId, rating: dto.rating, comment },
      { conflictPaths: ['userId', 'bannerId'] },
    );

    const saved = await this.ratingRepository.findOneOrFail({
      where: { bannerId, userId },
      relations: { user: true },
    });
    return this.toView(saved);
  }

  private async ensureBannerExists(bannerId: string): Promise<void> {
    const exists = await this.bannerRepository.exists({
      where: { id: bannerId },
    });
    if (!exists) {
      throw new NotFoundException(`Banner with id ${bannerId} not found`);
    }
  }

  // ไม่ส่ง email ของคนให้คะแนนออกไป
  private toView(rating: BannerRating): BannerRatingView {
    return {
      id: rating.id,
      rating: rating.rating,
      comment: rating.comment,
      createdAt: rating.updatedAt,
      user: {
        id: rating.user.id,
        displayName: rating.user.displayName,
        avatarUrl: rating.user.avatarUrl,
      },
    };
  }
}
