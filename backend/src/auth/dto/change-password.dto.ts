import { IsOptional, IsString, Length } from 'class-validator';

export class ChangePasswordDto {
  // ไม่ต้องส่งถ้ายังไม่เคยมีรหัสผ่าน (สมัครผ่าน Google แล้วมาตั้งรหัสครั้งแรก)
  @IsOptional()
  @IsString()
  @Length(1, 72)
  currentPassword?: string;

  // กติกาเดียวกับตอนสมัคร (bcrypt ใช้ได้แค่ 72 byte แรก)
  @IsString()
  @Length(8, 72)
  newPassword!: string;
}
