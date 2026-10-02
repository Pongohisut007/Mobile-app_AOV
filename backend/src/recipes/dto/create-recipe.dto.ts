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
import { RecipeContentType } from '../entities/recipe-content.entity';
import {
  RecipeDifficulty,
  RecipeStatus,
  RecipeType,
} from '../entities/recipe.entity';

export class CreateRecipeContentDto {
  @IsEnum(RecipeContentType)
  contentType!: RecipeContentType;

  @IsOptional()
  @IsString()
  @Length(0, 255)
  title?: string | null;

  @IsOptional()
  @IsString()
  textContent?: string | null;

  @IsOptional()
  @IsString()
  mediaUrl?: string | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  durationSeconds?: number | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}

export class CreateRecipeSectionDto {
  @IsString()
  @Length(1, 255)
  title!: string;

  @IsOptional()
  @IsString()
  description?: string | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  isPreview?: boolean;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateRecipeContentDto)
  contents?: CreateRecipeContentDto[];
}

export class CreateRecipeDto {
  @IsUUID()
  creatorId!: string;

  @IsString()
  @Length(1, 255)
  title!: string;

  @IsString()
  @Length(1, 255)
  slug!: string;

  @IsOptional()
  @IsString()
  shortDescription?: string | null;

  @IsOptional()
  @IsString()
  coverImageUrl?: string | null;

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

  @IsOptional()
  @IsEnum(RecipeType)
  type?: RecipeType;

  @IsOptional()
  @IsArray()
  @IsUUID('all', { each: true })
  categoryIds?: string[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateRecipeSectionDto)
  sections?: CreateRecipeSectionDto[];
}