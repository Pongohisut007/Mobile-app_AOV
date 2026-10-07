import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationsModule } from '../notifications/notifications.module';
import { RecipeAccessModule } from '../recipe-access/recipe-access.module';
import { Recipe } from '../recipes/entities/recipe.entity';
import { RecipeReviewsController } from './recipe-reviews.controller';
import { ReviewsService } from './reviews.service';
import { Review } from './entities/review.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Review, Recipe]),
    RecipeAccessModule,
    NotificationsModule,
  ],
  controllers: [RecipeReviewsController],
  providers: [ReviewsService],
})
export class ReviewsModule {}
