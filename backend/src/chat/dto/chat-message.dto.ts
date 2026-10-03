import {
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export class ChatMessageDto {
  @IsUUID()
  recipeId!: string;

  // ไม่บังคับถ้าแนบรูปมา (ส่งรูปอย่างเดียวได้)
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(4000)
  message?: string;
}
