import { registerAs } from '@nestjs/config';

// เข้าสู่ระบบด้วย Google: client ID ที่ยอมรับใน ID token (aud)
// ใส่ได้หลายตัวคั่นด้วยจุลภาค เช่น web client (ที่แอป Android ใช้เป็น serverClientId) และ iOS client
// ว่าง = ปิดการเข้าสู่ระบบด้วย Google
export default registerAs('google', () => ({
  clientIds: (process.env.GOOGLE_CLIENT_IDS ?? '')
    .split(',')
    .map((id) => id.trim())
    .filter((id) => id.length > 0),
}));
