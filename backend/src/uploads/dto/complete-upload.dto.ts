import { IsEnum, IsString, Matches } from 'class-validator';
import { UploadKind } from '../uploads.service';

export class CompleteUploadDto {
  @IsEnum(UploadKind)
  kind!: UploadKind;

  @IsString()
  @Matches(
    /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|png|webp|gif|mp4|webm|mov)$/i,
  )
  filename!: string;
}
