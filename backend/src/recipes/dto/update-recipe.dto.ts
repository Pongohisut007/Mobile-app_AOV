import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import {
  RecipeDifficulty,
  RecipeStatus,
  RecipeType,
} from '../entities/recipe.entity';
import {
  CreateRecipeDto,
  CreateRecipeSectionDto,
  PRICE_MESSAGE,
  PRICE_PATTERN,
  RECIPE_LIMITS,
  RecipeIngredientInputDto,
} from './create-recipe.dto';

// ValidationPipe ใช้ whitelist + forbidNonWhitelisted ทุก field จึงต้องมี decorator
export class UpdateRecipeDto implements Partial<CreateRecipeDto> {
  @IsOptional()
  @IsString()
  @Length(1, 255)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  titleEn?: string | null;

  @IsOptional()
  @IsString()
  @Length(1, 255)
  slug?: string;

  @IsOptional()
  @IsString()
  @MaxLength(RECIPE_LIMITS.shortDescription)
  shortDescription?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(RECIPE_LIMITS.url)
  coverImageUrl?: string | null;

  @IsOptional()
  @IsBoolean()
  showImgCommu?: boolean;

  @IsOptional()
  @IsString()
  @Matches(PRICE_PATTERN, { message: PRICE_MESSAGE })
  price?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(RECIPE_LIMITS.minutes)
  preparationMinutes?: number | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(RECIPE_LIMITS.minutes)
  cookingMinutes?: number | null;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(RECIPE_LIMITS.servings)
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
  @ArrayMaxSize(RECIPE_LIMITS.categories)
  @IsUUID('all', { each: true })
  categoryIds?: string[];

  // ถ้าส่งมา จะแทนที่ section/content เดิมทั้งหมด
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(RECIPE_LIMITS.sections)
  @ValidateNested({ each: true })
  @Type(() => CreateRecipeSectionDto)
  sections?: CreateRecipeSectionDto[];

  // ส่งมา = แทนรายการวัตถุดิบเดิมทั้งชุด (ลำดับในรายการ = ลำดับที่แสดง)
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => RecipeIngredientInputDto)
  ingredients?: RecipeIngredientInputDto[];
}
