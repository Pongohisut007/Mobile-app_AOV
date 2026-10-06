import { Throttle } from '@nestjs/throttler';

const MINUTE = 60_000;

/**
 * เพดานจำนวนคำขอ (ต่อผู้ใช้ที่ login หรือต่อ IP ถ้ายังไม่ login)
 * ค่าเริ่มต้นทั้งระบบตั้งไว้สูง กันแค่การยิงถล่ม ส่วน endpoint ที่โดนเดา/มีค่าใช้จ่ายตั้งเข้มกว่า
 */
export const RATE_LIMITS = {
  /** ทุก endpoint ที่ไม่ได้ตั้งเฉพาะ (แอปเปิดหน้าแรกยิงหลายคำขอพร้อมกัน จึงต้องเผื่อ) */
  default: { limit: 300, ttl: MINUTE },
  /** เดารหัสผ่าน */
  login: { limit: 10, ttl: MINUTE },
  /** สร้างบัญชีขยะ */
  register: { limit: 5, ttl: 10 * MINUTE },
  google: { limit: 20, ttl: MINUTE },
  /** ส่งอีเมลรบกวนคนอื่น */
  forgotPassword: { limit: 5, ttl: 15 * MINUTE },
  /** เดารหัส 6 หลัก */
  resetPassword: { limit: 10, ttl: 15 * MINUTE },
  /** ยืนยันรหัสผ่านเดิม (เปลี่ยนรหัส/ลบบัญชี) */
  passwordCheck: { limit: 10, ttl: 15 * MINUTE },
  /** มีค่าใช้จ่าย AI ทุกครั้ง */
  chat: { limit: 20, ttl: MINUTE },
  upload: { limit: 30, ttl: MINUTE },
  /** คอมเมนต์/รีวิว/ซื้อ */
  write: { limit: 30, ttl: MINUTE },
} as const;

export type RateLimitName = Exclude<keyof typeof RATE_LIMITS, 'default'>;

/** ใช้เพดานของ [name] แทนค่าเริ่มต้น เช่น @RateLimit('login') */
export const RateLimit = (name: RateLimitName) =>
  Throttle({ default: RATE_LIMITS[name] });
