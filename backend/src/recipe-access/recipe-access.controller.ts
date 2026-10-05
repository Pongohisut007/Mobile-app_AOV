import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  DEFAULT_PAGE_LIMIT,
  OptionalPaginationQueryDto,
  PaginatedResult,
} from '../common/pagination';
import { RecipeAccess } from './entities/recipe-access.entity';
import { RecipeAccessService } from './recipe-access.service';

/**
 * สิทธิ์ดูสูตรของคนที่ login อยู่เท่านั้น (id มาจาก token ไม่ใช่จาก URL)
 * สิทธิ์ถูกสร้างตอนซื้อผ่าน /iap ไม่มี endpoint ให้สร้าง/แก้/ลบเอง
 */
@UseGuards(JwtAuthGuard)
@Controller('recipe-access/me')
export class RecipeAccessController {
  constructor(private readonly recipeAccessService: RecipeAccessService) {}

  // ส่ง page มา = แบ่งหน้า ไม่ส่ง = ทั้งหมดเป็น array แบบเดิม
  @Get()
  findPurchased(
    @CurrentUser('id') userId: string,
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
  @Get('recipe-ids')
  findPurchasedRecipeIds(@CurrentUser('id') userId: string): Promise<string[]> {
    return this.recipeAccessService.findPurchasedRecipeIds(userId);
  }

  @Get('check/:recipeId')
  hasActiveAccess(
    @CurrentUser('id') userId: string,
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
  ): Promise<boolean> {
    return this.recipeAccessService.hasActiveAccess(userId, recipeId);
  }
}
