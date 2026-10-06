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
import { AdminOnly } from '../auth/decorators/admin-only.decorator';
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
  @Get()
  findAll(
    @Query('type') type?: RecipeType,
    @Query('status') status?: RecipeStatus,
  ): Promise<Category[]> {
    if (!type && !status) return this.categoriesService.findAll();
    return this.categoriesService.findAll(type, publishedOnly(status));
  }
  @Get(':id')
  findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('type') type?: RecipeType,
    @Query('status') status?: RecipeStatus,
  ): Promise<Category> {
    return this.categoriesService.findOne(id, type, publishedOnly(status));
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
