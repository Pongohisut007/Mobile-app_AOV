import { registerAs } from '@nestjs/config';

// ส่ง push ผ่าน Firebase Cloud Messaging
// FIREBASE_SERVICE_ACCOUNT_JSON = เนื้อไฟล์ service account (JSON ตรง ๆ หรือเข้ารหัส base64)
// จาก Firebase Console → Project settings → Service accounts → Generate new private key
// ว่าง = ไม่ส่ง push (กล่องแจ้งเตือนในแอปยังทำงานปกติ)
export default registerAs('firebase', () => ({
  serviceAccountJson: process.env.FIREBASE_SERVICE_ACCOUNT_JSON ?? '',
}));
