import { IsString, Length } from 'class-validator';

// ลบบัญชีต้องยืนยันรหัสผ่าน กันคนอื่นหยิบเครื่องที่ login ค้างไว้มากดลบ
export class DeleteAccountDto {
  @IsString()
  @Length(1, 72)
  password!: string;
}
