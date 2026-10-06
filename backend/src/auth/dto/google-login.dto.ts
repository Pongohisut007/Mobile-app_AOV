import { IsString, Length } from 'class-validator';

// ID token ที่แอปได้จาก Google Sign-In (JWT ยาวราว 1-2 KB)
export class GoogleLoginDto {
  @IsString()
  @Length(1, 4096)
  idToken!: string;
}
