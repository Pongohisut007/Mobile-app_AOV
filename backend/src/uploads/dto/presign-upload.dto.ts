import { IsEnum, IsInt, IsString, Min } from 'class-validator';
import { UploadKind } from '../uploads.service';

export class PresignUploadDto {
  @IsEnum(UploadKind)
  kind!: UploadKind;

  @IsString()
  mimeType!: string;

  @IsInt()
  @Min(1)
  size!: number;
}
