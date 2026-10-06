import { Reflector } from '@nestjs/core';
import type { JwtService } from '@nestjs/jwt';
import type { ThrottlerStorage } from '@nestjs/throttler';
import { parseTrustProxy } from '../trust-proxy';
import { AppThrottlerGuard } from './app-throttler.guard';

// @nestjs/jwt เป็น ESM ที่ jest โหลดตรง ๆ ไม่ได้ ใช้ JwtService ปลอมแทน
jest.mock('@nestjs/jwt', () => ({ JwtService: class JwtService {} }));

class TestGuard extends AppThrottlerGuard {
  tracker(req: Parameters<AppThrottlerGuard['getTracker']>[0]) {
    return this.getTracker(req);
  }
}

describe('AppThrottlerGuard', () => {
  const verify = jest.fn((token: string) => {
    if (token === 'good') return { sub: 'u1' };
    throw new Error('bad signature');
  });
  const guard = new TestGuard(
    { throttlers: [] },
    {} as ThrottlerStorage,
    new Reflector(),
    { verify } as unknown as JwtService,
  );

  it('counts signed-in users separately from their IP', async () => {
    await expect(
      guard.tracker({
        ip: '1.2.3.4',
        headers: { authorization: 'Bearer good' },
      }),
    ).resolves.toBe('user:u1');
  });

  it('falls back to the IP for guests and forged tokens', async () => {
    await expect(guard.tracker({ ip: '1.2.3.4', headers: {} })).resolves.toBe(
      'ip:1.2.3.4',
    );
    // token ปลอมต้องไม่ได้โควตาใหม่
    await expect(
      guard.tracker({
        ip: '1.2.3.4',
        headers: { authorization: 'Bearer forged' },
      }),
    ).resolves.toBe('ip:1.2.3.4');
    await expect(
      guard.tracker({ ip: '1.2.3.4', headers: { authorization: 'Basic x' } }),
    ).resolves.toBe('ip:1.2.3.4');
  });
});

describe('parseTrustProxy', () => {
  it('understands the TRUST_PROXY formats', () => {
    expect(parseTrustProxy(undefined)).toBeUndefined();
    expect(parseTrustProxy('  ')).toBeUndefined();
    expect(parseTrustProxy('true')).toBe(true);
    expect(parseTrustProxy('false')).toBe(false);
    expect(parseTrustProxy('1')).toBe(1);
    expect(parseTrustProxy('loopback, 10.0.0.0/8')).toBe(
      'loopback, 10.0.0.0/8',
    );
  });
});
