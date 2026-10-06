import { IsEmail, IsString, Length } from 'class-validator';

// สมัครแล้วเป็นผู้ใช้ทั่วไปเสมอ: creator (ขายสูตรได้) และ admin ต้องตั้งจากหลังบ้าน
// (เดิมส่ง role: 'creator' มาเองได้ ใครก็เปิดร้านขายสูตรได้โดยไม่ผ่านการอนุมัติ)
export class RegisterDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(8, 72)
  password!: string;

  @IsString()
  @Length(1, 150)
  displayName!: string;
}
