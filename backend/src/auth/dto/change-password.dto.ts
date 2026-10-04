import { IsString, Length } from 'class-validator';

export class ChangePasswordDto {
  @IsString()
  @Length(1, 72)
  currentPassword!: string;

  // กติกาเดียวกับตอนสมัคร (bcrypt ใช้ได้แค่ 72 byte แรก)
  @IsString()
  @Length(8, 72)
  newPassword!: string;
}
