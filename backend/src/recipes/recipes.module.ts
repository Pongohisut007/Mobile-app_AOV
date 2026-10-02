import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Category } from '../categories/entities/category.entity';
import { Favorite } from '../favorites/entities/favorite.entity';
import { RecipeComment } from '../recipe-comments/entities/recipe-comment.entity';
import { Review } from '../reviews/entities/review.entity';
import { RecipesController } from './recipes.controller';
import { RecipesService } from './recipes.service';
import { RecipeContent } from './entities/recipe-content.entity';
import { RecipeSection } from './entities/recipe-section.entity';
import { Recipe } from './entities/recipe.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Recipe,
      RecipeSection,
      RecipeContent,
      Category,
      Favorite,
      Review,
      RecipeComment,
    ]),
  ],
  controllers: [RecipesController],
  providers: [RecipesService],
  exports: [RecipesService],
})
export class RecipesModule {}
