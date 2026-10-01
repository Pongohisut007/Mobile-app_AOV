import {
  ArrayUnique,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

// ชิป "ชอบอะไรในสูตรนี้" ฝั่งแอปแปลง key เป็นข้อความไทยเอง
export const REVIEW_TAGS = [
  'tasty',
  'easy',
  'spicy_right',
  'easy_ingredients',
] as const;

export class UpsertReviewDto {
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsIn(REVIEW_TAGS, { each: true })
  tags?: string[];
}
