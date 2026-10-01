import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BannerRatingController } from './banner-rating.controller';
import { BannerRatingService } from './banner-rating.service';
import { BannerController } from './banner.controller';
import { BannerService } from './banner.service';
import { BannerRating } from './entities/banner-rating.entity';
import { Banner } from './entities/banner.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Banner, BannerRating])],
  controllers: [BannerController, BannerRatingController],
  providers: [BannerService, BannerRatingService],
})
export class BannerModule {}
