import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import type { AuthUser } from '../interfaces/jwt-payload.interface';

// เหมือน JwtAuthGuard แต่ไม่บังคับ login: ไม่มี token (หรือ token ไม่ถูกต้อง) ก็ผ่าน แค่ไม่มี user
@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  handleRequest<TUser = AuthUser>(_err: unknown, user: TUser | false) {
    return (user || null) as TUser;
  }
}
