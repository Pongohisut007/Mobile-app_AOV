import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNumberString,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Min,
  ValidateNested,
} from 'class-validator';
import {
  RecipeDifficulty,
  RecipeStatus,
  RecipeType,
} from '../entities/recipe.entity';
import { CreateRecipeDto, CreateRecipeSectionDto } from './create-recipe.dto';

// ValidationPipe ใช้ whitelist + forbidNonWhitelisted ทุก field จึงต้องมี decorator
export class UpdateRecipeDto implements Partial<CreateRecipeDto> {
  @IsOptional()
  @IsString()
  @Length(1, 255)
  title?: string;

  @IsOptional()
  @IsString()
  @Length(1, 255)
  slug?: string;

  @IsOptional()
  @IsString()
  shortDescription?: string | null;

  @IsOptional()
  @IsString()
  coverImageUrl?: string | null;

  @IsOptional()
  @IsBoolean()
  showImgCommu?: boolean;

  @IsOptional()
  @IsNumberString()
  price?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  preparationMinutes?: number | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  cookingMinutes?: number | null;

  @IsOptional()
  @IsInt()
  @Min(1)
  servingCount?: number | null;

  @IsOptional()
  @IsEnum(RecipeDifficulty)
  difficulty?: RecipeDifficulty | null;

  @IsOptional()
  @IsEnum(RecipeStatus)
  status?: RecipeStatus;

  // เปลี่ยนได้เฉพาะ user ที่เป็น creator (เช็คใน controller)
  @IsOptional()
  @IsEnum(RecipeType)
  type?: RecipeType;

  @IsOptional()
  @IsArray()
  @IsUUID('all', { each: true })
  categoryIds?: string[];

  // ถ้าส่งมา จะแทนที่ section/content เดิมทั้งหมด
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateRecipeSectionDto)
  sections?: CreateRecipeSectionDto[];
}
