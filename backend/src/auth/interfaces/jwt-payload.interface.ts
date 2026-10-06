import type { UserRole } from '../../users/entities/user.entity';

export interface JwtPayload {
  // user id
  sub: string;
  email: string;
  role: UserRole;
  // token_version ตอนออก token (token ที่ออกก่อนมีฟิลด์นี้ถือเป็น 0)
  ver?: number;
  // id ของ token ใบนี้ ใช้ยกเลิกเฉพาะใบ (ออกจากระบบเครื่องเดียว)
  // token ที่ออกก่อนมีฟิลด์นี้ ยกเลิกได้ด้วย "ออกจากระบบทุกอุปกรณ์" เท่านั้น
  jti?: string;
  // เวลาหมดอายุ (วินาที) jsonwebtoken ใส่ให้เอง
  exp?: number;
}

export interface AuthUser {
  id: string;
  email: string;
  displayName: string;
  avatarUrl: string | null;
  role: UserRole;
}

export interface AuthResponse {
  accessToken: string;
  expiresIn: string;
  user: AuthUser;
}
