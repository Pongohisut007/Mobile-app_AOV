import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNumber,
  IsNumberString,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Max,
  MaxLength,
  Min,
  ValidateIf,
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

/** วัตถุดิบหนึ่งรายการของสูตร: เลือกจากคลัง (ingredientId) หรือพิมพ์ชื่อใหม่ (name) */
export class RecipeIngredientInputDto {
  // ต้องมีอย่างใดอย่างหนึ่ง ส่งมาทั้งคู่ = ใช้ ingredientId
  @ValidateIf((input: RecipeIngredientInputDto) => input.name === undefined)
  @IsUUID()
  ingredientId?: string;

  @ValidateIf(
    (input: RecipeIngredientInputDto) => input.ingredientId === undefined,
  )
  @IsString()
  @Length(1, 150)
  name?: string;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0)
  @Max(9999999)
  amount?: number | null;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  unit?: string | null;

  /** เช่น "สับหยาบ", "หั่นเต๋า" */
  @IsOptional()
  @IsString()
  @MaxLength(255)
  note?: string | null;

  @IsOptional()
  @IsBoolean()
  isOptional?: boolean;
}

export class CreateRecipeDto {
  // ไม่ถูกใช้: backend ตั้งเป็นคนที่ login เสมอ (รับไว้ให้แอปเวอร์ชันเก่าที่ยังส่งมาไม่ error)
  @IsOptional()
  @IsUUID()
  creatorId?: string;

  @IsString()
  @Length(1, 255)
  title!: string;

  // ชื่อภาษาอังกฤษ ไม่บังคับ
  @IsOptional()
  @IsString()
  @MaxLength(255)
  titleEn?: string | null;

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

  // ส่งมา = แทนรายการวัตถุดิบเดิมทั้งชุด (ลำดับในรายการ = ลำดับที่แสดง)
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => RecipeIngredientInputDto)
  ingredients?: RecipeIngredientInputDto[];
}
