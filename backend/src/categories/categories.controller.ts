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
  UseGuards,
} from '@nestjs/common';
import { AdminOnly } from '../auth/decorators/admin-only.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { UserRole } from '../users/entities/user.entity';
import { CategoriesService } from './categories.service';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';
import { Category } from './entities/category.entity';
import { RecipeStatus, RecipeType } from '../recipes/entities/recipe.entity';
import { visibleRecipeFilters } from '../recipes/recipe-permissions';

@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  // ส่ง type/status มา = แนบสูตรในหมวดมาด้วย ซึ่งต้องเป็นสูตรที่เผยแพร่แล้วเท่านั้น
  // (ไม่งั้นใช้ดู draft ของคนอื่นแทน GET /recipes ได้)
  // หมวดที่ปิดใช้งานเห็นเฉพาะ admin (ไว้เปิดกลับ) คนอื่นเหมือนไม่มีหมวดนั้น
  @UseGuards(OptionalJwtAuthGuard)
  @Get()
  findAll(
    @Query('type') type?: RecipeType,
    @Query('status') status?: RecipeStatus,
    @CurrentUser('role') role?: UserRole,
  ): Promise<Category[]> {
    const options = { includeInactive: role === UserRole.ADMIN };
    if (!type && !status) {
      return this.categoriesService.findAll(undefined, undefined, options);
    }
    return this.categoriesService.findAll(type, publishedOnly(status), options);
  }

  @UseGuards(OptionalJwtAuthGuard)
  @Get(':id')
  findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('type') type?: RecipeType,
    @Query('status') status?: RecipeStatus,
    @CurrentUser('role') role?: UserRole,
  ): Promise<Category> {
    return this.categoriesService.findOne(id, type, publishedOnly(status), {
      includeInactive: role === UserRole.ADMIN,
    });
  }

  @AdminOnly()
  @Post()
  create(@Body() data: CreateCategoryDto): Promise<Category> {
    return this.categoriesService.create(data);
  }

  @AdminOnly()
  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() data: UpdateCategoryDto,
  ): Promise<Category> {
    return this.categoriesService.update(id, data);
  }

  @AdminOnly()
  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.categoriesService.remove(id);
  }
}

/** สูตรที่แนบมากับหมวดเป็นของสาธารณะ: ไม่ระบุ = published, สถานะอื่น = 403 */
function publishedOnly(status?: RecipeStatus): RecipeStatus | undefined {
  return visibleRecipeFilters({ status }).status;
}
