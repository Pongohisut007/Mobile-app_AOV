import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RecipeAccessModule } from '../recipe-access/recipe-access.module';
import { Recipe } from '../recipes/entities/recipe.entity';
import { RecipeReviewsController } from './recipe-reviews.controller';
import { ReviewsController } from './reviews.controller';
import { ReviewsService } from './reviews.service';
import { Review } from './entities/review.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Review, Recipe]), RecipeAccessModule],
  controllers: [ReviewsController, RecipeReviewsController],
  providers: [ReviewsService],
})
export class ReviewsModule {}
