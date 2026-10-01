import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Put,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  BannerRatingService,
  BannerRatingSummary,
  BannerRatingView,
} from './banner-rating.service';
import { RateBannerDto } from './dto/rate-banner.dto';

@Controller('banners/:bannerId/ratings')
export class BannerRatingController {
  constructor(private readonly bannerRatingService: BannerRatingService) {}

  // ใครก็ดูคะแนนเฉลี่ยและความคิดเห็นได้ ไม่ต้องล็อกอิน
  @Get()
  getSummary(
    @Param('bannerId', ParseUUIDPipe) bannerId: string,
  ): Promise<BannerRatingSummary> {
    return this.bannerRatingService.getSummary(bannerId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  findMine(
    @Param('bannerId', ParseUUIDPipe) bannerId: string,
    @CurrentUser('id') userId: string,
  ): Promise<BannerRatingView | null> {
    return this.bannerRatingService.findMine(bannerId, userId);
  }

  // ให้คะแนนครั้งแรกหรือแก้คะแนนเดิมใช้ route เดียวกัน
  @UseGuards(JwtAuthGuard)
  @Put('me')
  rate(
    @Param('bannerId', ParseUUIDPipe) bannerId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: RateBannerDto,
  ): Promise<BannerRatingView> {
    return this.bannerRatingService.rate(bannerId, userId, dto);
  }
}
