import { IsOptional, IsString, Length } from 'class-validator';

// ลบบัญชีต้องยืนยันรหัสผ่าน กันคนอื่นหยิบเครื่องที่ login ค้างไว้มากดลบ
// (บัญชีที่สมัครผ่าน Google และไม่มีรหัสผ่าน ไม่ต้องส่ง service ตรวจเอง)
export class DeleteAccountDto {
  @IsOptional()
  @IsString()
  @Length(1, 72)
  password?: string;
}
