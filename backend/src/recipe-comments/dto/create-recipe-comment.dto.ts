import { IsString, MaxLength, MinLength } from 'class-validator';

export class CreateRecipeCommentDto {
  @IsString()
  @MinLength(1)
  @MaxLength(1000)
  comment!: string;
}
