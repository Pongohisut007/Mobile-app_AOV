import { IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export class ChatMessageDto {
  @IsUUID()
  recipeId!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(4000)
  message!: string;
}
