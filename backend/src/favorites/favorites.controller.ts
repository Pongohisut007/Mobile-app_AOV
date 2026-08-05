import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { Favorite } from './entities/favorite.entity';
import { FavoritesService } from './favorites.service';

@Controller('favorites')
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Get()
  findAll(@Query('userId') userId?: string): Promise<Favorite[]> {
    return this.favoritesService.findAll(userId);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string): Promise<Favorite> {
    return this.favoritesService.findOne(id);
  }

  @Post()
  create(@Body() data: Partial<Favorite>): Promise<Favorite> {
    return this.favoritesService.create(data);
  }

  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.favoritesService.remove(id);
  }
}
