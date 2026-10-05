/* eslint-disable security/detect-object-injection -- query builders are Jest mocks. */
import { NotFoundException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { RecipeAccess } from './entities/recipe-access.entity';
import { RecipeAccessService } from './recipe-access.service';

function queryBuilder() {
  const query: Record<string, jest.Mock> = {};
  for (const method of [
    'where',
    'andWhere',
    'leftJoinAndSelect',
    'orderBy',
    'addOrderBy',
    'select',
    'addSelect',
    'offset',
    'limit',
  ]) {
    query[method] = jest.fn().mockReturnValue(query);
  }
  query.getMany = jest.fn().mockResolvedValue([]);
  query.getCount = jest.fn().mockResolvedValue(0);
  query.getRawMany = jest.fn().mockResolvedValue([]);
  return query;
}

describe('RecipeAccessService', () => {
  const access = { id: 'a1', userId: 'u1', recipeId: 'r1' } as RecipeAccess;
  let query: ReturnType<typeof queryBuilder>;
  let repository: Record<string, jest.Mock>;
  let service: RecipeAccessService;

  beforeEach(() => {
    query = queryBuilder();
    repository = {
      find: jest.fn().mockResolvedValue([access]),
      findOne: jest.fn().mockResolvedValue({ ...access }),
      exists: jest.fn().mockResolvedValue(false),
      create: jest.fn((value: Partial<RecipeAccess>) => value),
      save: jest.fn((value: RecipeAccess) => Promise.resolve(value)),
      remove: jest.fn(),
      createQueryBuilder: jest.fn().mockReturnValue(query),
    };
    service = new RecipeAccessService(
      repository as unknown as Repository<RecipeAccess>,
    );
  });

  it('lists all accesses and the purchased recipes of a user', async () => {
    await expect(service.findAll()).resolves.toEqual([access]);
    query.getMany.mockResolvedValue([access]);
    await expect(service.findPurchasedByUser('u1')).resolves.toEqual([access]);
    expect(query.where).toHaveBeenCalledWith('access.user_id = :userId', {
      userId: 'u1',
    });
  });

  it('returns an empty page without loading relations', async () => {
    await expect(service.findPurchasedPageByUser('u1', 1, 20)).resolves.toEqual(
      { data: [], total: 0, page: 1, limit: 20, totalPages: 0 },
    );
    expect(repository.find).not.toHaveBeenCalled();
  });

  it('keeps the purchase order when loading a page', async () => {
    query.getCount.mockResolvedValue(3);
    query.getRawMany.mockResolvedValue([
      { id: 'b' },
      { id: 'a' },
      { id: 'gone' },
    ]);
    repository.find.mockResolvedValue([{ id: 'a' }, { id: 'b' }]);

    const page = await service.findPurchasedPageByUser('u1', 2, 3);

    expect(query.offset).toHaveBeenCalledWith(3);
    expect(page.data.map((item) => item.id)).toEqual(['b', 'a']);
    expect(page.total).toBe(3);
  });

  it('returns only the ids of purchased recipes', async () => {
    query.getRawMany.mockResolvedValue([
      { recipeId: 'r1' },
      { recipeId: 'r2' },
    ]);
    await expect(service.findPurchasedRecipeIds('u1')).resolves.toEqual([
      'r1',
      'r2',
    ]);
  });

  it('checks permanent access first, then unexpired access', async () => {
    repository.exists.mockResolvedValueOnce(true);
    await expect(service.hasActiveAccess('u1', 'r1')).resolves.toBe(true);
    expect(repository.exists).toHaveBeenCalledTimes(1);

    repository.exists.mockResolvedValueOnce(false).mockResolvedValueOnce(true);
    await expect(service.hasActiveAccess('u1', 'r1')).resolves.toBe(true);

    repository.exists.mockResolvedValue(false);
    await expect(service.hasActiveAccess('u1', 'r1')).resolves.toBe(false);
  });

  it('creates, updates and removes accesses', async () => {
    await service.create({ userId: 'u1', recipeId: 'r1' });
    expect(repository.save).toHaveBeenCalledWith({
      userId: 'u1',
      recipeId: 'r1',
    });

    const updated = await service.update('a1', { recipeId: 'r2', id: 'hack' });
    expect(updated).toMatchObject({ id: 'a1', recipeId: 'r2' });

    await service.remove('a1');
    expect(repository.remove).toHaveBeenCalled();
  });

  it('throws when an access is missing', async () => {
    repository.findOne.mockResolvedValue(null);
    await expect(service.findOne('nope')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
