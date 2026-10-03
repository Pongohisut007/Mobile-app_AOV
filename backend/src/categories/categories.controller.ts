import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { Category } from './entities/category.entity';
import {
  RecipeStatus,
  RecipeType,
} from '../recipes/entities/recipe.entity';

@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Get()
  findAll(
    @Query('type') type?: RecipeType,
    @Query('status') status?: RecipeStatus,
  ): Promise<Category[]> {
    return this.categoriesService.findAll(type, status);
  }
  @Get(':id')
  findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('type') type?: RecipeType,
    @Query('status') status?: RecipeStatus,
  ): Promise<Category> {
    return this.categoriesService.findOne(id, type, status);
  }

  @Post()
  create(@Body() data: Partial<Category>): Promise<Category> {
    return this.categoriesService.create(data);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() data: Partial<Category>,
  ): Promise<Category> {
    return this.categoriesService.update(id, data);
  }

  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.categoriesService.remove(id);
  }
}
