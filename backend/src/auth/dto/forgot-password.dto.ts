import { IsEmail, IsIn, IsOptional } from 'class-validator';

export class ForgotPasswordDto {
  @IsEmail()
  email!: string;

  /** ภาษาของอีเมลที่ส่ง (ตามภาษาที่ผู้ใช้เลือกในแอป) */
  @IsOptional()
  @IsIn(['th', 'en'])
  language?: 'th' | 'en';
}
