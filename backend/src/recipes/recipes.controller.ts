import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { UserRole } from '../users/entities/user.entity';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { SearchRecipesDto } from './dto/search-recipes.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { Recipe, RecipeStatus, RecipeType } from './entities/recipe.entity';
import { PaginatedResult, RecipesService } from './recipes.service';

@Controller('recipes')
export class RecipesController {
  constructor(private readonly recipesService: RecipesService) {}

  @Get()
  findAll(
    @Query('search') search?: string,
    @Query('category') category?: string,
    @Query('categoryId') categoryId?: string,
    @Query('creatorId') creatorId?: string,
    @Query('status') status?: RecipeStatus,
    @Query('type') type?: RecipeType,
  ): Promise<Recipe[]> {
    return this.recipesService.findAll({
      search,
      category,
      categoryId,
      creatorId,
      status,
      type,
    });
  }

  // ต้องมาก่อน @Get(':id') ไม่งั้น 'search' จะถูกจับเป็น id
  @Get('search')
  search(@Query() dto: SearchRecipesDto): Promise<PaginatedResult<Recipe>> {
    return this.recipesService.search(dto);
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

  @Post()
  create(@Body() dto: CreateRecipeDto): Promise<Recipe> {
    return this.recipesService.create(dto);
  }

  // login ไม่บังคับเหมือนเดิม แต่ถ้าจะเปลี่ยน type ต้องเป็น creator
  @UseGuards(OptionalJwtAuthGuard)
  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateRecipeDto,
    @CurrentUser('role') role?: UserRole,
  ): Promise<Recipe> {
    if (dto.type !== undefined && role !== UserRole.CREATOR) {
      throw new ForbiddenException('Only creators can change recipe type');
    }
    return this.recipesService.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.recipesService.remove(id);
  }
}
