import { ConfigService } from '@nestjs/config';
import { AppCacheService } from './app-cache.service';

// Redis ปลอมที่คุมได้ว่าพร้อมไหม/เก็บอะไรไว้
class FakeRedis {
  static last: FakeRedis | undefined;
  status = 'ready';
  store = new Map<string, string>();
  failing = false;
  handlers = new Map<string, (error: Error) => void>();

  constructor() {
    FakeRedis.last = this;
  }

  on(event: string, handler: (error: Error) => void) {
    this.handlers.set(event, handler);
    return this;
  }

  get = jest.fn((key: string) => this.run(() => this.store.get(key) ?? null));
  set = jest.fn((key: string, value: string) =>
    this.run(() => {
      this.store.set(key, value);
      return 'OK';
    }),
  );
  incr = jest.fn((key: string) =>
    this.run(() => {
      const next = Number(this.store.get(key) ?? 0) + 1;
      this.store.set(key, String(next));
      return next;
    }),
  );
  exists = jest.fn((key: string) =>
    this.run(() => (this.store.has(key) ? 1 : 0)),
  );
  quit = jest.fn(() => Promise.resolve('OK'));

  private run<T>(fn: () => T): Promise<T> {
    return this.failing
      ? Promise.reject(new Error('redis down'))
      : Promise.resolve(fn());
  }
}

jest.mock('ioredis', () => ({
  __esModule: true,
  default: jest.fn().mockImplementation(() => new FakeRedis()),
}));

function createService(url: string | undefined = 'redis://test') {
  const config = { get: jest.fn().mockReturnValue(url) };
  return new AppCacheService(config as unknown as ConfigService);
}

describe('AppCacheService', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('loads once, then serves copies from memory', async () => {
    const service = createService();
    FakeRedis.last!.status = 'connecting';
    const loader = jest.fn().mockResolvedValue({ items: [1, 2] });

    const first = await service.getOrSet<{ items: number[] }>(
      'recipes',
      'k',
      60,
      loader,
    );
    first.items.push(3);
    const second = await service.getOrSet('recipes', 'k', 60, loader);

    expect(loader).toHaveBeenCalledTimes(1);
    // แก้ค่าที่ได้ไปแล้วต้องไม่กระทบของใน cache
    expect(second).toEqual({ items: [1, 2] });
  });

  it('reloads after the memory entry expires', async () => {
    const service = createService();
    FakeRedis.last!.status = 'end';
    const now = jest.spyOn(Date, 'now').mockReturnValue(1_000);
    const loader = jest
      .fn()
      .mockResolvedValueOnce('old')
      .mockResolvedValueOnce('new');

    await service.getOrSet('ns', 'k', 10, loader);
    now.mockReturnValue(1_000 + 11_000);

    await expect(service.getOrSet('ns', 'k', 10, loader)).resolves.toBe('new');
    expect(loader).toHaveBeenCalledTimes(2);
  });

  it('invalidates only the given namespace', async () => {
    const service = createService();
    FakeRedis.last!.status = 'end';
    const recipes = jest.fn().mockResolvedValue('r');
    const categories = jest.fn().mockResolvedValue('c');

    await service.getOrSet('recipes', 'k', 60, recipes);
    await service.getOrSet('categories', 'k', 60, categories);
    await service.invalidate('recipes');
    await service.getOrSet('recipes', 'k', 60, recipes);
    await service.getOrSet('categories', 'k', 60, categories);

    expect(recipes).toHaveBeenCalledTimes(2);
    expect(categories).toHaveBeenCalledTimes(1);
  });

  it('drops the least recently used entries beyond the memory limit', async () => {
    const service = createService();
    FakeRedis.last!.status = 'end';
    const loader = jest.fn((value: number) => Promise.resolve(value));

    for (let i = 0; i <= 500; i++) {
      await service.getOrSet('ns', `k${i}`, 60, () => loader(i));
    }
    // k0 ถูกทิ้งไปแล้ว ต้องโหลดใหม่ ส่วน k500 ยังอยู่
    await service.getOrSet('ns', 'k0', 60, () => loader(0));
    await service.getOrSet('ns', 'k500', 60, () => loader(500));

    expect(loader).toHaveBeenCalledTimes(502);
  });

  it('shares values and versions through Redis when it is ready', async () => {
    const service = createService();
    const redis = FakeRedis.last!;
    redis.store.set('cache:ver:recipes', '3');
    redis.store.set('cache:recipes:v3:k', JSON.stringify({ from: 'redis' }));
    const loader = jest.fn();

    await expect(service.getOrSet('recipes', 'k', 60, loader)).resolves.toEqual(
      { from: 'redis' },
    );
    expect(loader).not.toHaveBeenCalled();

    await service.getOrSet('recipes', 'other', 30, () =>
      Promise.resolve('fresh'),
    );
    expect(redis.set).toHaveBeenCalledWith(
      'cache:recipes:v3:other',
      '"fresh"',
      'EX',
      30,
    );

    await service.invalidate('recipes');
    expect(redis.store.get('cache:ver:recipes')).toBe('4');
  });

  it('keeps working from memory when Redis calls fail', async () => {
    const service = createService();
    const redis = FakeRedis.last!;
    redis.failing = true;
    const loader = jest.fn().mockResolvedValue('value');

    await expect(service.getOrSet('ns', 'k', 60, loader)).resolves.toBe(
      'value',
    );
    await service.invalidate('ns');
    await service.getOrSet('ns', 'k', 60, loader);

    // invalidate ขยับ version ใน RAM เอง key เดิมจึงไม่ถูกใช้
    expect(loader).toHaveBeenCalledTimes(2);
  });

  it('logs Redis connection errors instead of crashing', () => {
    createService();
    const handler = FakeRedis.last!.handlers.get('error');
    expect(() => handler?.(new Error('ECONNREFUSED'))).not.toThrow();
  });

  it('closes the Redis connection on shutdown', async () => {
    const service = createService();
    await service.onModuleDestroy();
    expect(FakeRedis.last!.quit).toHaveBeenCalled();
  });

  it('works without Redis when no URL is configured', async () => {
    const service = createService('');
    const loader = jest.fn().mockResolvedValue(1);

    await service.getOrSet('ns', 'k', 60, loader);
    await service.getOrSet('ns', 'k', 60, loader);
    await service.invalidate('ns');
    await service.onModuleDestroy();

    expect(loader).toHaveBeenCalledTimes(1);
  });

  it('remembers flags until they expire, in memory and in Redis', async () => {
    const service = createService();
    await service.setFlag('revoked:a', 60);
    expect(await service.hasFlag('revoked:a')).toBe(true);
    expect(FakeRedis.last!.set).toHaveBeenCalledWith(
      'flag:revoked:a',
      '1',
      'EX',
      60,
    );

    // อีกเครื่องเห็นจาก Redis แม้ RAM ของตัวเองไม่มี
    const other = createService();
    FakeRedis.last!.store.set('flag:revoked:b', '1');
    expect(await other.hasFlag('revoked:b')).toBe(true);
    expect(await other.hasFlag('revoked:c')).toBe(false);

    // หมดอายุไปแล้ว ไม่ต้องจด
    await service.setFlag('revoked:d', 0);
    expect(await service.hasFlag('revoked:d')).toBe(false);
  });
});
