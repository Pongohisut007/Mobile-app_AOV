import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RecipesController } from './recipes.controller';
import { RecipesService } from './recipes.service';
import { RecipeContent } from './entities/recipe-content.entity';
import { RecipeSection } from './entities/recipe-section.entity';
import { Recipe } from './entities/recipe.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Recipe, RecipeSection, RecipeContent])],
  controllers: [RecipesController],
  providers: [RecipesService],
})
export class RecipesModule {}
