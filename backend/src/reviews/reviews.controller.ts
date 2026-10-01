import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { Review } from './entities/review.entity';
import { ReviewsService } from './reviews.service';

// อ่านอย่างเดียว การให้/แก้คะแนนย้ายไปที่ /recipes/:recipeId/reviews/me
// ซึ่งอ่าน user จาก token แทนการรับ userId จาก body
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Get()
  findAll(@Query('recipeId') recipeId?: string): Promise<Review[]> {
    return this.reviewsService.findAll(recipeId);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string): Promise<Review> {
    return this.reviewsService.findOne(id);
  }
}
