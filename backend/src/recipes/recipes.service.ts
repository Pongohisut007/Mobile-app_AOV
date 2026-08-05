import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Recipe } from './entities/recipe.entity';

@Injectable()
export class RecipesService {
  constructor(
    @InjectRepository(Recipe)
    private readonly recipeRepository: Repository<Recipe>,
  ) {}

  findAll(): Promise<Recipe[]> {
    return this.recipeRepository.find({
      relations: { creator: true, categories: true },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Recipe> {
    const recipe = await this.recipeRepository.findOne({
      where: { id },
      relations: {
        creator: true,
        categories: true,
        recipeIngredients: { ingredient: true },
      },
    });
    if (!recipe) throw new NotFoundException(`Recipe with id ${id} not found`);
    return recipe;
  }

  create(data: Partial<Recipe>): Promise<Recipe> {
    return this.recipeRepository.save(this.recipeRepository.create(data));
  }

  async update(id: string, data: Partial<Recipe>): Promise<Recipe> {
    const recipe = await this.findOne(id);
    Object.assign(recipe, data, { id: recipe.id });
    return this.recipeRepository.save(recipe);
  }

  async remove(id: string): Promise<void> {
    const recipe = await this.findOne(id);
    await this.recipeRepository.remove(recipe);
  }
}
