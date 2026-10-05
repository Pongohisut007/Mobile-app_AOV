import type { DataSource } from 'typeorm';
import { AppCacheService } from '../cache/app-cache.service';
import { ProtectedMediaService } from './protected-media.service';

describe('ProtectedMediaService', () => {
  it('protects files used in paid steps of official recipes', async () => {
    const query = jest.fn().mockResolvedValueOnce([{ '?column?': 1 }]);
    const service = new ProtectedMediaService({
      query,
    } as unknown as DataSource);

    await expect(service.isProtected('videos', 'step.mp4')).resolves.toBe(true);
    const [sql, params] = query.mock.calls[0] as [string, string[]];
    expect(sql).toContain('section.is_preview = false');
    expect(sql).toContain("recipe.type = 'official'");
    expect(params).toEqual([
      '/uploads/videos/step.mp4',
      '%/uploads/videos/step.mp4',
    ]);

    query.mockResolvedValueOnce([]);
    await expect(service.isProtected('images', 'cover.png')).resolves.toBe(
      false,
    );
  });

  it('caches the answer with recipe data', async () => {
    const getOrSet = jest.fn().mockResolvedValue(false);
    const service = new ProtectedMediaService(
      { query: jest.fn() } as unknown as DataSource,
      { getOrSet } as unknown as AppCacheService,
    );

    await service.isProtected('images', 'cover.png');
    expect(getOrSet).toHaveBeenCalledWith(
      'recipes',
      'protected-media:/uploads/images/cover.png',
      ProtectedMediaService.ttlSeconds,
      expect.any(Function),
    );
  });
});
