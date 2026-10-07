import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
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

/**
 * เพดานของข้อมูลสูตร กันค่าที่ทำให้ DB error (เลขเกิน integer) หรือทำงานหนักเกินเหตุ
 * ตั้งไว้กว้างกว่าการใช้งานจริงมาก แอปปกติไม่มีทางชน
 */
export const RECIPE_LIMITS = {
  minutes: 10_000,
  servings: 1_000,
  durationSeconds: 86_400,
  sortOrder: 10_000,
  sections: 100,
  contentsPerSection: 100,
  categories: 20,
  shortDescription: 2_000,
  sectionDescription: 5_000,
  textContent: 10_000,
  url: 2_048,
} as const;

/** ไม่ติดลบ ทศนิยมไม่เกิน 2 ตำแหน่ง ตรงกับคอลัมน์ numeric(12, 2) */
export const PRICE_PATTERN = /^\d{1,10}(\.\d{1,2})?$/;
export const PRICE_MESSAGE =
  'price must be a non-negative number with at most 2 decimal places';

export class CreateRecipeContentDto {
  @IsEnum(RecipeContentType)
  contentType!: RecipeContentType;

  @IsOptional()
  @IsString()
  @Length(0, 255)
  title?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(RECIPE_LIMITS.textContent)
  textContent?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(RECIPE_LIMITS.url)
  mediaUrl?: string | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(RECIPE_LIMITS.durationSeconds)
  durationSeconds?: number | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(RECIPE_LIMITS.sortOrder)
  sortOrder?: number;
}

export class CreateRecipeSectionDto {
  @IsString()
  @Length(1, 255)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(RECIPE_LIMITS.sectionDescription)
  description?: string | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(RECIPE_LIMITS.sortOrder)
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  isPreview?: boolean;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(RECIPE_LIMITS.contentsPerSection)
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

  @IsOptional()
  @IsEnum(RecipeType)
  type?: RecipeType;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(RECIPE_LIMITS.categories)
  @IsUUID('all', { each: true })
  categoryIds?: string[];

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
