import { NotFoundException } from '@nestjs/common';
import { QueryFailedError, Repository } from 'typeorm';
import { AppCacheService } from '../cache/app-cache.service';
import { Favorite } from './entities/favorite.entity';
import { FavoritesService } from './favorites.service';

describe('FavoritesService', () => {
  const favorite = { id: 'f1', userId: 'u1', recipeId: 'r1' } as Favorite;
  let repository: Record<string, jest.Mock>;
  let cache: { invalidate: jest.Mock };
  let service: FavoritesService;

  beforeEach(() => {
    repository = {
      find: jest.fn().mockResolvedValue([favorite]),
      findAndCount: jest.fn().mockResolvedValue([[favorite], 21]),
      findOne: jest.fn().mockResolvedValue(null),
      findOneOrFail: jest.fn().mockResolvedValue(favorite),
      create: jest.fn((value: Partial<Favorite>) => value),
      save: jest.fn().mockResolvedValue(favorite),
      remove: jest.fn(),
    };
    cache = { invalidate: jest.fn() };
    service = new FavoritesService(
      repository as unknown as Repository<Favorite>,
      cache as unknown as AppCacheService,
    );
  });

  it('lists favorites newest first', async () => {
    await expect(service.findAll('u1')).resolves.toEqual([favorite]);
    expect(repository.find).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId: 'u1' } }),
    );
  });

  it('paginates favorites', async () => {
    const page = await service.findPage('u1', 2, 10);

    expect(repository.findAndCount).toHaveBeenCalledWith(
      expect.objectContaining({ skip: 10, take: 10 }),
    );
    expect(page).toEqual({
      data: [favorite],
      total: 21,
      page: 2,
      limit: 10,
      totalPages: 3,
    });
  });

  it('hides favorites that belong to someone else', async () => {
    await expect(service.findOne('f1', 'other')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('creates a favorite and refreshes recipe counts', async () => {
    await expect(service.create('u1', 'r1')).resolves.toBe(favorite);
    expect(cache.invalidate).toHaveBeenCalled();
  });

  it('returns the existing favorite instead of saving a duplicate', async () => {
    repository.findOne.mockResolvedValue(favorite);
    await expect(service.create('u1', 'r1')).resolves.toBe(favorite);
    expect(repository.save).not.toHaveBeenCalled();
  });

  it('handles a duplicate created at the same time', async () => {
    repository.save.mockRejectedValue(
      new QueryFailedError(
        'INSERT',
        [],
        Object.assign(new Error('dup'), { code: '23505' }),
      ),
    );
    await expect(service.create('u1', 'r1')).resolves.toBe(favorite);
    expect(repository.findOneOrFail).toHaveBeenCalled();
  });

  it('rethrows other save errors', async () => {
    repository.save.mockRejectedValue(new Error('db down'));
    await expect(service.create('u1', 'r1')).rejects.toThrow('db down');
  });

  it('removes by id or by recipe', async () => {
    repository.findOne.mockResolvedValue(favorite);
    await service.remove('f1', 'u1');
    await service.removeByRecipe('u1', 'r1');

    expect(repository.remove).toHaveBeenCalledTimes(2);
    expect(cache.invalidate).toHaveBeenCalledTimes(2);
  });

  it('reports a missing favorite when removing by recipe', async () => {
    await expect(service.removeByRecipe('u1', 'r1')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('works without a cache', async () => {
    const plain = new FavoritesService(
      repository as unknown as Repository<Favorite>,
    );
    await expect(plain.create('u1', 'r1')).resolves.toBe(favorite);
  });
});
