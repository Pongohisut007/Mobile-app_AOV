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
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import type { AuthUser } from '../auth/interfaces/jwt-payload.interface';
import { DEFAULT_PAGE_LIMIT } from '../common/pagination';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { ListRecipesQueryDto } from './dto/list-recipes-query.dto';
import { SearchRecipesDto } from './dto/search-recipes.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { Recipe } from './entities/recipe.entity';
import {
  assertRecipeFieldsAllowed,
  visibleRecipeFilters,
} from './recipe-permissions';
import { PaginatedResult, RecipesService } from './recipes.service';

@Controller('recipes')
export class RecipesController {
  constructor(private readonly recipesService: RecipesService) {}

  // ส่ง page มา = แบ่งหน้า ({ data, total, page, limit, totalPages })
  // ไม่ส่ง = คืนทั้งหมดเป็น array แบบเดิม
  // คนทั่วไปเห็นเฉพาะสูตรที่เผยแพร่ draft ดูได้เฉพาะเจ้าของ (แนบ token มา)
  @UseGuards(OptionalJwtAuthGuard)
  @Get()
  findAll(
    @Query() query: ListRecipesQueryDto,
    @CurrentUser('id') viewerId?: string,
  ): Promise<Recipe[] | PaginatedResult<Recipe>> {
    const { page, limit, sort, ...filters } = query;
    const options = visibleRecipeFilters(filters, viewerId);
    if (page === undefined) return this.recipesService.findAll(options);
    return this.recipesService.findPage(
      options,
      page,
      limit ?? DEFAULT_PAGE_LIMIT,
      sort,
    );
  }

  // ต้องมาก่อน @Get(':id') ไม่งั้น 'search' จะถูกจับเป็น id
  @UseGuards(OptionalJwtAuthGuard)
  @Get('search')
  search(
    @Query() dto: SearchRecipesDto,
    @CurrentUser('id') viewerId?: string,
  ): Promise<PaginatedResult<Recipe>> {
    return this.recipesService.search(visibleRecipeFilters(dto, viewerId));
  }

  // login ไม่บังคับ: ถ้าแนบ token มาและซื้อสูตรแล้ว จะได้ขั้นตอนครบ
  @UseGuards(OptionalJwtAuthGuard)
  @Get(':id')
  findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') userId?: string,
  ): Promise<Recipe> {
    return this.recipesService.findOneForViewer(id, userId);
  }

  // เจ้าของสูตรคือคนที่ login เสมอ (creatorId ที่ส่งมาใน body ไม่ถูกใช้)
  @UseGuards(JwtAuthGuard)
  @Post()
  create(
    @Body() dto: CreateRecipeDto,
    @CurrentUser() user: AuthUser,
  ): Promise<Recipe> {
    assertRecipeFieldsAllowed(dto, user, { changingType: false });
    return this.recipesService.create({ ...dto, creatorId: user.id });
  }

  // แก้ได้เฉพาะเจ้าของ (หรือ admin) และเปลี่ยน type ได้เฉพาะ creator
  @UseGuards(JwtAuthGuard)
  @Patch(':id')
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateRecipeDto,
    @CurrentUser() user: AuthUser,
  ): Promise<Recipe> {
    assertRecipeFieldsAllowed(dto, user, { changingType: true });
    await this.recipesService.assertCanManage(id, user);
    return this.recipesService.update(id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  async remove(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthUser,
  ): Promise<void> {
    await this.recipesService.assertCanManage(id, user);
    return this.recipesService.remove(id);
  }
}
