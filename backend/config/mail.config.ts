import { registerAs } from '@nestjs/config';

// ส่งอีเมล (ตอนนี้ใช้ส่งรหัสรีเซ็ตรหัสผ่าน) ผ่าน SMTP
// Gmail: SMTP_HOST=smtp.gmail.com SMTP_PORT=465 SMTP_USER=อีเมล SMTP_PASS=App Password 16 ตัว
// SMTP_HOST ว่าง = ไม่ส่งจริง (dev พิมพ์เนื้อหาลง log แทน, production แจ้ง error)
export default registerAs('mail', () => {
  const port = Number.parseInt(process.env.SMTP_PORT ?? '465', 10);
  return {
    host: process.env.SMTP_HOST ?? '',
    port,
    // 465 = TLS ตั้งแต่ต่อ, 587 = STARTTLS (nodemailer อัปเกรดให้เอง)
    secure: port === 465,
    user: process.env.SMTP_USER ?? '',
    pass: process.env.SMTP_PASS ?? '',
    from: process.env.MAIL_FROM ?? process.env.SMTP_USER ?? '',
  };
});
