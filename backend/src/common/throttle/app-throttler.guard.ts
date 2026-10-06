import { Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import {
  InjectThrottlerOptions,
  InjectThrottlerStorage,
  ThrottlerGuard,
  type ThrottlerModuleOptions,
  type ThrottlerStorage,
} from '@nestjs/throttler';
import type { JwtPayload } from '../../auth/interfaces/jwt-payload.interface';

interface TrackedRequest {
  ip?: string;
  headers?: Record<string, string | string[] | undefined>;
}

/**
 * นับคำขอแยกตามผู้ใช้ (token ถูกต้อง) ไม่งั้นนับตาม IP
 * - คนหลาย ๆ คนใช้ Wi-Fi เดียวกัน (IP เดียว) จะไม่โดนจำกัดรวมกันหลัง login
 * - ต้องตรวจลายเซ็น token ก่อน ไม่งั้นแค่ส่ง token มั่ว ๆ มาก็ได้โควตาใหม่ทุกครั้ง
 * IP จริงหลัง load balancer ต้องตั้ง TRUST_PROXY ใน main.ts
 */
@Injectable()
export class AppThrottlerGuard extends ThrottlerGuard {
  constructor(
    @InjectThrottlerOptions() options: ThrottlerModuleOptions,
    @InjectThrottlerStorage() storage: ThrottlerStorage,
    reflector: Reflector,
    private readonly jwtService: JwtService,
  ) {
    super(options, storage, reflector);
  }

  protected override getTracker(req: TrackedRequest): Promise<string> {
    const userId = this.verifiedUserId(req.headers?.authorization);
    return Promise.resolve(userId ? `user:${userId}` : `ip:${req.ip ?? ''}`);
  }

  private verifiedUserId(header: string | string[] | undefined): string | null {
    if (typeof header !== 'string' || !header.startsWith('Bearer ')) {
      return null;
    }
    try {
      return this.jwtService.verify<JwtPayload>(header.slice(7).trim()).sub;
    } catch {
      return null;
    }
  }
}
