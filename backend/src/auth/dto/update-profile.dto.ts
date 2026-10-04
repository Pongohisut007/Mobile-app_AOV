import { Transform } from 'class-transformer';
import {
  IsOptional,
  IsString,
  Length,
  Matches,
  ValidateIf,
} from 'class-validator';

// PATCH /auth/profile: แก้ได้แค่ชื่อกับรูปโปรไฟล์ของตัวเอง (อีเมล/role/status แก้ไม่ได้)
// whitelist + forbidNonWhitelisted ทำให้ส่ง field อื่นมาแล้วโดนปฏิเสธ
export class UpdateProfileDto {
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @Length(1, 150)
  displayName?: string;

  // รับเฉพาะไฟล์ที่อัปโหลดผ่านระบบเรา (/uploads/images/<uuid>.<ext>)
  // กันการใส่ URL ภายนอก เช่น รูปติดตามผู้ใช้ ส่ง null = ลบรูป
  @ValidateIf((_, value) => value !== null && value !== undefined)
  @IsString()
  @Matches(/^\/uploads\/images\/[A-Za-z0-9-]+\.(jpg|png|webp|gif)$/, {
    message: 'avatarUrl must be an uploaded image path',
  })
  avatarUrl?: string | null;
}
