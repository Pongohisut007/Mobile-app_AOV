import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

interface MemoryEntry {
  // เก็บเป็น JSON string แล้ว parse ทุกครั้งที่อ่าน
  // ผู้เรียกจะได้ object ใหม่เสมอ แก้ค่าที่ได้ไปก็ไม่ทำให้ของใน cache เพี้ยน
  json: string;
  expiresAt: number;
}

// จำกัดจำนวน key ใน RAM (เกินแล้วทิ้งอันที่ไม่ได้ใช้นานสุด)
const MAX_MEMORY_ENTRIES = 500;

/**
 * cache ผล query 2 ชั้น
 * 1. RAM ของ process นี้ (เร็วสุด)
 * 2. Redis (อยู่รอดตอน restart และแชร์ได้ถ้ามีหลาย instance)
 *
 * ล้างทีละ namespace ด้วยการเพิ่มเลข version (ไม่ต้อง SCAN ลบ key ใน Redis)
 * Redis ล่ม/ต่อไม่ได้ = ใช้แค่ RAM ต่อไป request ไม่ค้าง
 */
@Injectable()
export class AppCacheService implements OnModuleDestroy {
  private readonly logger = new Logger(AppCacheService.name);
  private readonly memory = new Map<string, MemoryEntry>();
  private readonly versions = new Map<string, number>();
  private readonly redis: Redis | null;

  constructor(config: ConfigService) {
    // ค่าเริ่มต้นเดียวกับ ChatService
    const url = config.get<string>('REDIS_URL') ?? 'redis://localhost:6379';
    this.redis = url
      ? new Redis(url, {
          // ต่อไม่ได้ให้ล้มทันที ไม่ต่อคิวรอจน request ค้าง
          enableOfflineQueue: false,
          maxRetriesPerRequest: 1,
          retryStrategy: (times) => Math.min(times * 1000, 30_000),
        })
      : null;
    // ไม่งั้น ioredis จะโยน unhandled error ตอนต่อไม่ได้
    this.redis?.on('error', (error: Error) =>
      this.logger.debug(`Redis unavailable: ${error.message}`),
    );
  }

  async onModuleDestroy() {
    await this.redis?.quit().catch(() => undefined);
  }

  /** อ่านจาก cache ถ้าไม่มีก็เรียก loader แล้วเก็บไว้ */
  async getOrSet<T>(
    namespace: string,
    key: string,
    ttlSeconds: number,
    loader: () => Promise<T>,
  ): Promise<T> {
    const version = await this.version(namespace);
    const fullKey = `cache:${namespace}:v${version}:${key}`;

    const fromMemory = this.memory.get(fullKey);
    if (fromMemory && fromMemory.expiresAt > Date.now()) {
      // ย้ายไปท้าย Map = ใช้ล่าสุด (ทำ LRU)
      this.memory.delete(fullKey);
      this.memory.set(fullKey, fromMemory);
      return JSON.parse(fromMemory.json) as T;
    }

    const fromRedis = await this.redisCall((redis) => redis.get(fullKey));
    if (fromRedis) {
      this.remember(fullKey, fromRedis, ttlSeconds);
      return JSON.parse(fromRedis) as T;
    }

    const value = await loader();
    const json = JSON.stringify(value);
    this.remember(fullKey, json, ttlSeconds);
    await this.redisCall((redis) => redis.set(fullKey, json, 'EX', ttlSeconds));
    // คืน copy เหมือนตอนอ่านจาก cache ผู้เรียกทุกครั้งได้ข้อมูลหน้าตาเดียวกัน
    return JSON.parse(json) as T;
  }

  /** ข้อมูลใน namespace นี้เปลี่ยน: ทิ้ง cache ทั้งหมดของมัน */
  async invalidate(namespace: string): Promise<void> {
    const prefix = `cache:${namespace}:`;
    for (const key of this.memory.keys()) {
      if (key.startsWith(prefix)) this.memory.delete(key);
    }
    const next = await this.redisCall((redis) =>
      redis.incr(this.versionKey(namespace)),
    );
    // Redis ไม่ว่าง ก็ขยับ version ใน RAM เองให้ key เก่าไม่ถูกใช้
    this.versions.set(
      namespace,
      next ?? (this.versions.get(namespace) ?? 0) + 1,
    );
  }

  private async version(namespace: string): Promise<number> {
    const known = this.versions.get(namespace);
    if (known !== undefined) return known;
    const stored = await this.redisCall((redis) =>
      redis.get(this.versionKey(namespace)),
    );
    const version = stored ? Number(stored) : 0;
    this.versions.set(namespace, version);
    return version;
  }

  private versionKey(namespace: string): string {
    return `cache:ver:${namespace}`;
  }

  private remember(key: string, json: string, ttlSeconds: number): void {
    this.memory.delete(key);
    this.memory.set(key, { json, expiresAt: Date.now() + ttlSeconds * 1000 });
    while (this.memory.size > MAX_MEMORY_ENTRIES) {
      const oldest = this.memory.keys().next().value as string | undefined;
      if (oldest === undefined) break;
      this.memory.delete(oldest);
    }
  }

  // Redis ไม่พร้อม/error = คืน null ให้ทำงานต่อด้วย RAM อย่างเดียว
  private async redisCall<T>(
    call: (redis: Redis) => Promise<T>,
  ): Promise<T | null> {
    if (!this.redis || this.redis.status !== 'ready') return null;
    try {
      return await call(this.redis);
    } catch (error: unknown) {
      this.logger.debug(`Redis cache skipped: ${String(error)}`);
      return null;
    }
  }
}
