import { IsEmail, IsString, Length, Matches } from 'class-validator';

export class ResetPasswordDto {
  @IsEmail()
  email!: string;

  @Matches(/^\d{6}$/, { message: 'รหัสยืนยันต้องเป็นตัวเลข 6 หลัก' })
  code!: string;

  // กติกาเดียวกับตอนสมัคร (bcrypt ใช้ได้แค่ 72 byte แรก)
  @IsString()
  @Length(8, 72)
  newPassword!: string;
}
