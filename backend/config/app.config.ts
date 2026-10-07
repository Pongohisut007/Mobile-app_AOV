import { registerAs } from '@nestjs/config';

/**
 * สภาพแวดล้อมของแอป แยกจาก NODE_ENV
 * - NODE_ENV บอก Node/ไลบรารีว่ารันแบบ production (Dockerfile ตั้ง production เสมอ)
 * - APP_ENV บอกพฤติกรรมของแอป:
 *   development = แก้ schema อัตโนมัติ (synchronize), ซื้อจำลองได้, ไม่มี SMTP พิมพ์อีเมลลง log
 *   staging     = ใช้ migration, ซื้อจำลองได้, ไม่มี SMTP พิมพ์อีเมลลง log
 *   production  = ใช้ migration, ซื้อจำลองได้ (ยังไม่มีระบบจ่ายเงินจริง), ไม่มี SMTP = error
 */
export const APP_ENVS = ['development', 'staging', 'production'] as const;
export type AppEnv = (typeof APP_ENVS)[number];

/** ไม่ได้ตั้ง APP_ENV: NODE_ENV=production ถือเป็น production นอกนั้นเป็น development */
export function resolveAppEnv(env: NodeJS.ProcessEnv = process.env): AppEnv {
  const value = env.APP_ENV?.trim();
  if (!value) {
    return env.NODE_ENV === 'production' ? 'production' : 'development';
  }
  if ((APP_ENVS as readonly string[]).includes(value)) {
    return value as AppEnv;
  }
  // พิมพ์ผิด (เช่น prod) ห้ามเดาเอง เพราะ development จะเปิด synchronize กับฐานข้อมูลจริง
  throw new Error(
    `APP_ENV must be one of ${APP_ENVS.join(', ')} (got "${value}")`,
  );
}

export default registerAs('app', () => ({ env: resolveAppEnv() }));
