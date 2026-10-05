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
import { AdminOnly } from '../auth/decorators/admin-only.decorator';
import { CreateIngredientDto, UpdateIngredientDto } from './dto/ingredient.dto';
import { Ingredient } from './entities/ingredient.entity';
import { IngredientsService } from './ingredients.service';

@Controller('ingredients')
export class IngredientsController {
  constructor(private readonly ingredientsService: IngredientsService) {}

  @Get()
  findAll(): Promise<Ingredient[]> {
    return this.ingredientsService.findAll();
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string): Promise<Ingredient> {
    return this.ingredientsService.findOne(id);
  }

  @AdminOnly()
  @Post()
  create(@Body() data: CreateIngredientDto): Promise<Ingredient> {
    return this.ingredientsService.create(data);
  }

  @AdminOnly()
  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() data: UpdateIngredientDto,
  ): Promise<Ingredient> {
    return this.ingredientsService.update(id, data);
  }

  @AdminOnly()
  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.ingredientsService.remove(id);
  }
}
