import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  ParseIntPipe,
} from '@nestjs/common';
import { FoodService } from './foods_service';
import { Food } from './foods_entity';

@Controller('foods')
export class FoodController {
  constructor(private readonly foodService: FoodService) {}

  @Get()
  findAll(): Promise<Food[]> {
    return this.foodService.findAll();
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number): Promise<Food> {
    return this.foodService.findOne(id);
  }

  @Post()
  create(@Body() body: Partial<Food>): Promise<Food> {
    return this.foodService.create(body);
  }

  @Put(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: Partial<Food>,
  ): Promise<Food> {
    return this.foodService.update(id, body);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.foodService.remove(id);
  }
}