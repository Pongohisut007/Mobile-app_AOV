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
import {
  DEFAULT_PAGE_LIMIT,
  OptionalPaginationQueryDto,
  PaginatedResult,
} from '../common/pagination';
import { RecipeAccess } from './entities/recipe-access.entity';
import { RecipeAccessService } from './recipe-access.service';

@Controller('recipe-access')
export class RecipeAccessController {
  constructor(private readonly recipeAccessService: RecipeAccessService) {}

  @Get()
  findAll(): Promise<RecipeAccess[]> {
    return this.recipeAccessService.findAll();
  }

  @Get('check/:userId/:recipeId')
  hasActiveAccess(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
  ): Promise<boolean> {
    return this.recipeAccessService.hasActiveAccess(userId, recipeId);
  }

  // ส่ง page มา = แบ่งหน้า ไม่ส่ง = ทั้งหมดเป็น array แบบเดิม
  @Get('user/:userId')
  findPurchasedByUser(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query() query: OptionalPaginationQueryDto,
  ): Promise<RecipeAccess[] | PaginatedResult<RecipeAccess>> {
    if (query.page === undefined) {
      return this.recipeAccessService.findPurchasedByUser(userId);
    }
    return this.recipeAccessService.findPurchasedPageByUser(
      userId,
      query.page,
      query.limit ?? DEFAULT_PAGE_LIMIT,
    );
  }

  // แค่ id ของสูตรที่ซื้อแล้ว ใช้เช็กสิทธิ์ทั้งแอปโดยไม่ต้องโหลดรายละเอียดทุกสูตร
  @Get('user/:userId/recipe-ids')
  findPurchasedRecipeIds(
    @Param('userId', ParseUUIDPipe) userId: string,
  ): Promise<string[]> {
    return this.recipeAccessService.findPurchasedRecipeIds(userId);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string): Promise<RecipeAccess> {
    return this.recipeAccessService.findOne(id);
  }

  @Post()
  create(@Body() data: Partial<RecipeAccess>): Promise<RecipeAccess> {
    return this.recipeAccessService.create(data);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() data: Partial<RecipeAccess>,
  ): Promise<RecipeAccess> {
    return this.recipeAccessService.update(id, data);
  }

  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.recipeAccessService.remove(id);
  }
}
