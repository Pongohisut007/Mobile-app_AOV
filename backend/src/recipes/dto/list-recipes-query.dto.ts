import { IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { OptionalPaginationQueryDto } from '../../common/pagination';
import { RecipeStatus, RecipeType } from '../entities/recipe.entity';

// GET /recipes: ตัวกรอง + แบ่งหน้าแบบไม่บังคับ
export class ListRecipesQueryDto extends OptionalPaginationQueryDto {
  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsOptional()
  @IsUUID()
  creatorId?: string;

  @IsOptional()
  @IsEnum(RecipeStatus)
  status?: RecipeStatus;

  @IsOptional()
  @IsEnum(RecipeType)
  type?: RecipeType;
}
