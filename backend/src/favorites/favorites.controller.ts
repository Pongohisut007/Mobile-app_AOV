import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import {
  DEFAULT_PAGE_LIMIT,
  OptionalPaginationQueryDto,
  PaginatedResult,
} from '../common/pagination';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateFavoriteDto } from './dto/create-favorite.dto';
import { RemoveFavoriteDto } from './dto/remove-favorite.dto';
import { Favorite } from './entities/favorite.entity';
import { FavoritesService } from './favorites.service';

// รายการโปรดเป็นของส่วนตัว userId อ่านจาก token ไม่ใช่จาก query ที่ปลอมได้
@UseGuards(JwtAuthGuard)
@Controller('favorites')
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  // ส่ง page มา = แบ่งหน้า ไม่ส่ง = ทั้งหมด (FavoriteBloc ใช้เช็กหัวใจทุกสูตร)
  @Get()
  findAll(
    @CurrentUser('id') userId: string,
    @Query() query: OptionalPaginationQueryDto,
  ): Promise<Favorite[] | PaginatedResult<Favorite>> {
    if (query.page === undefined) return this.favoritesService.findAll(userId);
    return this.favoritesService.findPage(
      userId,
      query.page,
      query.limit ?? DEFAULT_PAGE_LIMIT,
    );
  }

  // ลบด้วย recipeId ต้องมาก่อน :id ไม่งั้น route จะชนกัน
  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  removeByRecipe(
    @CurrentUser('id') userId: string,
    @Query() query: RemoveFavoriteDto,
  ): Promise<void> {
    return this.favoritesService.removeByRecipe(userId, query.recipeId);
  }

  @Get(':id')
  findOne(
    @CurrentUser('id') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<Favorite> {
    return this.favoritesService.findOne(id, userId);
  }

  @Post()
  create(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateFavoriteDto,
  ): Promise<Favorite> {
    return this.favoritesService.create(userId, dto.recipeId);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @CurrentUser('id') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.favoritesService.remove(id, userId);
  }
}
