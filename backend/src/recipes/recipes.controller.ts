import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { Recipe } from './entities/recipe.entity';
import { RecipesService } from './recipes.service';

@Controller('recipes')
export class RecipesController {
  constructor(private readonly recipesService: RecipesService) {}

  @Get()
  findAll(): Promise<Recipe[]> {
    return this.recipesService.findAll();
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string): Promise<Recipe> {
    return this.recipesService.findOne(id);
  }

  @Post()
  create(@Body() data: Partial<Recipe>): Promise<Recipe> {
    return this.recipesService.create(data);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() data: Partial<Recipe>,
  ): Promise<Recipe> {
    return this.recipesService.update(id, data);
  }

  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.recipesService.remove(id);
  }
}
