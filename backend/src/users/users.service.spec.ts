/* eslint-disable security/detect-object-injection, @typescript-eslint/no-unsafe-member-access -- repositories and query builders are Jest mocks. */
import { NotFoundException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { AppCacheService } from '../cache/app-cache.service';
import { Favorite } from '../favorites/entities/favorite.entity';
import { RecipeAccess } from '../recipe-access/entities/recipe-access.entity';
import { Recipe, RecipeStatus } from '../recipes/entities/recipe.entity';
import { Review } from '../reviews/entities/review.entity';
import {
  IdentityProvider,
  UserIdentity,
} from './entities/user-identity.entity';
import { DeviceToken } from '../notifications/entities/device-token.entity';
import { NotificationSettings } from '../notifications/entities/notification-settings.entity';
import { Notification } from '../notifications/entities/notification.entity';
import { User, UserRole, UserStatus } from './entities/user.entity';
import { UsersService } from './users.service';

function queryBuilder(result: Record<string, unknown> = {}) {
  const query: Record<string, jest.Mock> = {};
  for (const method of [
    'where',
    'andWhere',
    'innerJoin',
    'select',
    'delete',
    'from',
  ]) {
    query[method] = jest.fn().mockReturnValue(query);
  }
  query.getCount = jest.fn().mockResolvedValue(result.count ?? 0);
  query.getRawOne = jest.fn().mockResolvedValue(result.raw);
  query.execute = jest.fn().mockResolvedValue({});
  return query;
}

const user = {
  id: 'u1',
  email: 'cook@example.com',
  displayName: 'Cook',
  avatarUrl: 'a.png',
  role: UserRole.USER,
  status: UserStatus.ACTIVE,
} as User;

describe('UsersService', () => {
  let userRepository: Record<string, jest.Mock | object>;
  let recipeRepository: { count: jest.Mock };
  let favoriteRepository: { count: jest.Mock };
  let accessQuery: ReturnType<typeof queryBuilder>;
  let reviewQuery: ReturnType<typeof queryBuilder>;
  let manager: Record<string, jest.Mock>;
  let cache: { invalidate: jest.Mock };
  let identityRepository: Record<string, jest.Mock>;
  let service: UsersService;

  beforeEach(() => {
    const txQuery = queryBuilder();
    manager = {
      createQueryBuilder: jest.fn().mockReturnValue(txQuery),
      delete: jest.fn(),
      update: jest.fn(),
      increment: jest.fn(),
      create: jest.fn((_entity: unknown, value: object) => value),
      save: jest.fn((value: object) =>
        Promise.resolve({ id: 'new', ...value }),
      ),
    };
    identityRepository = {
      findOne: jest.fn().mockResolvedValue(null),
      create: jest.fn((value: object) => value),
      save: jest.fn(),
    };
    userRepository = {
      find: jest.fn().mockResolvedValue([user]),
      // คืน object ใหม่ทุกครั้งเหมือนอ่านจาก DB จริง
      findOne: jest.fn(() => Promise.resolve({ ...user })),
      update: jest.fn(),
      increment: jest.fn(),
      save: jest.fn((value: User) => Promise.resolve({ ...value, id: 'u1' })),
      create: jest.fn((value: Partial<User>) => value),
      remove: jest.fn(),
      // COUNT จาก postgres กลับมาเป็น string
      query: jest.fn().mockResolvedValue([
        {
          reviewCount: '12',
          salesCount: '58',
          officialSavedCount: '40',
          communitySavedCount: '7',
          commentsReceivedCount: '3',
          reviewsWrittenCount: '5',
        },
      ]),
      manager: {
        transaction: jest.fn((run: (m: typeof manager) => Promise<void>) =>
          run(manager),
        ),
        delete: jest.fn(),
      },
    };
    recipeRepository = { count: jest.fn().mockResolvedValue(2) };
    favoriteRepository = { count: jest.fn().mockResolvedValue(3) };
    accessQuery = queryBuilder({ count: 4 });
    reviewQuery = queryBuilder({ raw: { rating: '4.26' } });
    cache = { invalidate: jest.fn() };
    service = new UsersService(
      userRepository as unknown as Repository<User>,
      recipeRepository as unknown as Repository<Recipe>,
      favoriteRepository as unknown as Repository<Favorite>,
      {
        createQueryBuilder: jest.fn().mockReturnValue(accessQuery),
      } as unknown as Repository<RecipeAccess>,
      {
        createQueryBuilder: jest.fn().mockReturnValue(reviewQuery),
      } as unknown as Repository<Review>,
      identityRepository as unknown as Repository<UserIdentity>,
      cache as unknown as AppCacheService,
    );
  });

  it('lists users newest first', async () => {
    await expect(service.findAll()).resolves.toEqual([user]);
    expect(userRepository.find).toHaveBeenCalledWith({
      order: { createdAt: 'DESC' },
    });
  });

  it('throws when a user is missing', async () => {
    (userRepository.findOne as jest.Mock).mockResolvedValue(null);
    await expect(service.findOne('nope')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('looks up emails case-insensitively', async () => {
    await service.findByEmail('Cook@Example.COM');
    await service.findByEmailWithPassword('Cook@Example.COM');
    await service.findById('u1');
    await service.findByIdWithPassword('u1');

    const calls = (userRepository.findOne as jest.Mock).mock.calls;
    expect(calls[0][0]).toEqual({ where: { email: 'cook@example.com' } });
    expect(calls[1][0].where).toEqual({ email: 'cook@example.com' });
    expect(calls[1][0].select.passwordHash).toBe(true);
    expect(calls[3][0].select).toEqual({ id: true, passwordHash: true });
  });

  it('changing the password also signs out other devices', async () => {
    await service.updatePasswordHash('u1', 'hash');

    expect(userRepository.update).toHaveBeenCalledWith(
      { id: 'u1' },
      { passwordHash: 'hash' },
    );
    expect(userRepository.increment).toHaveBeenCalledWith(
      { id: 'u1' },
      'tokenVersion',
      1,
    );
    // เครื่องที่หลุดจากระบบไม่ได้รับ push ของบัญชีนี้อีก
    const { delete: removeDevices } = userRepository.manager as {
      delete: jest.Mock;
    };
    expect(removeDevices).toHaveBeenCalledWith(DeviceToken, { userId: 'u1' });
  });

  it('deleting an account anonymises the user and clears caches', async () => {
    await service.deleteOwnAccount('u1', 'random-hash');

    expect(manager.update).toHaveBeenCalledWith(
      User,
      { id: 'u1' },
      expect.objectContaining({
        email: 'deleted+u1@deleted.invalid',
        avatarUrl: null,
        passwordHash: 'random-hash',
        status: UserStatus.DISABLED,
      }),
    );
    expect(manager.increment).toHaveBeenCalledWith(
      User,
      { id: 'u1' },
      'tokenVersion',
      1,
    );
    expect(manager.createQueryBuilder).toHaveBeenCalledTimes(2);
    for (const entity of [DeviceToken, Notification, NotificationSettings]) {
      expect(manager.delete).toHaveBeenCalledWith(entity, { userId: 'u1' });
    }
    expect(cache.invalidate).toHaveBeenCalledTimes(3);
  });

  it('builds the profile with counts and a rounded rating', async () => {
    const profile = await service.findProfile('u1');

    expect(profile).toEqual(
      expect.objectContaining({
        id: 'u1',
        recipeCount: 2,
        draftCount: 2,
        savedCount: 3,
        purchasedCount: 4,
        rating: 4.3,
      }),
    );
    expect(recipeRepository.count).toHaveBeenCalledWith({
      where: { creatorId: 'u1', status: RecipeStatus.DRAFT },
    });
  });

  it('includes activity counts as numbers', async () => {
    const profile = await service.findProfile('u1');

    expect(profile).toEqual(
      expect.objectContaining({
        reviewCount: 12,
        salesCount: 58,
        officialSavedCount: 40,
        communitySavedCount: 7,
        commentsReceivedCount: 3,
        reviewsWrittenCount: 5,
      }),
    );
    const [sql, params] = (userRepository.query as jest.Mock).mock.calls[0] as [
      string,
      unknown[],
    ];
    // นับเฉพาะจากคนอื่น ไม่นับเจ้าของสูตรเอง
    expect(sql).toContain('t.user_id <> $1');
    expect(params).toEqual([
      'u1',
      'published',
      'published',
      'purchase',
      'official',
      'community',
    ]);
  });

  it('treats missing activity rows as zero', async () => {
    (userRepository.query as jest.Mock).mockResolvedValue([]);
    await expect(service.findProfile('u1')).resolves.toEqual(
      expect.objectContaining({ salesCount: 0, reviewsWrittenCount: 0 }),
    );
  });

  it('reports a zero rating when there are no reviews', async () => {
    reviewQuery.getRawOne.mockResolvedValue(undefined);
    await expect(service.findProfile('u1')).resolves.toEqual(
      expect.objectContaining({ rating: 0 }),
    );

    reviewQuery.getRawOne.mockResolvedValue({ rating: 'not-a-number' });
    await expect(service.findProfile('u1')).resolves.toEqual(
      expect.objectContaining({ rating: 0 }),
    );
  });

  it('creates users with a lowercase email', async () => {
    await service.create({
      email: 'New@Example.com',
      passwordHash: 'h',
      displayName: 'New',
    });
    expect(userRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({ email: 'new@example.com' }),
    );
  });

  it('updates only the profile fields that were sent', async () => {
    await service.updateOwnProfile('u1', { displayName: 'Chef' });
    let saved = (userRepository.save as jest.Mock).mock.calls[0][0] as User;
    expect(saved).toMatchObject({ displayName: 'Chef', avatarUrl: 'a.png' });

    await service.updateOwnProfile('u1', { avatarUrl: null });
    saved = (userRepository.save as jest.Mock).mock.calls[1][0] as User;
    expect(saved).toMatchObject({ displayName: 'Cook', avatarUrl: null });
    expect(cache.invalidate).toHaveBeenCalledTimes(6);
  });

  it('finds users by their linked Google account', async () => {
    await expect(
      service.findByIdentity(IdentityProvider.GOOGLE, 'g-1'),
    ).resolves.toBeNull();

    identityRepository.findOne.mockResolvedValue({ user });
    await expect(
      service.findByIdentity(IdentityProvider.GOOGLE, 'g-1'),
    ).resolves.toBe(user);
    expect(identityRepository.findOne).toHaveBeenCalledWith({
      where: { provider: IdentityProvider.GOOGLE, providerUserId: 'g-1' },
      relations: { user: true },
    });
  });

  it('links a Google account to an existing user', async () => {
    await service.linkIdentity(
      'u1',
      IdentityProvider.GOOGLE,
      'g-1',
      'cook@example.com',
    );
    expect(identityRepository.save).toHaveBeenCalledWith({
      userId: 'u1',
      provider: IdentityProvider.GOOGLE,
      providerUserId: 'g-1',
      email: 'cook@example.com',
    });
  });

  it('creates a password-less user together with the Google link', async () => {
    await service.createWithIdentity(
      { email: 'New@Gmail.com', displayName: 'New', avatarUrl: 'p.png' },
      IdentityProvider.GOOGLE,
      'g-2',
    );

    expect(manager.create).toHaveBeenCalledWith(
      User,
      expect.objectContaining({ email: 'new@gmail.com', passwordHash: null }),
    );
    expect(manager.create).toHaveBeenCalledWith(
      UserIdentity,
      expect.objectContaining({ userId: 'new', providerUserId: 'g-2' }),
    );
  });

  it('knows whether a user has a password', async () => {
    (userRepository.findOne as jest.Mock).mockResolvedValueOnce({
      id: 'u1',
      passwordHash: 'hash',
    });
    await expect(service.hasPassword('u1')).resolves.toBe(true);

    (userRepository.findOne as jest.Mock).mockResolvedValueOnce({
      id: 'u1',
      passwordHash: null,
    });
    await expect(service.hasPassword('u1')).resolves.toBe(false);
  });

  it('unlinks Google when the account is deleted', async () => {
    await service.deleteOwnAccount('u1', 'random-hash');
    expect(manager.delete).toHaveBeenCalledWith(UserIdentity, { userId: 'u1' });
  });

  it('updates and removes users by id', async () => {
    await service.update('u1', { displayName: 'Renamed' });
    expect(userRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({ id: 'u1', displayName: 'Renamed' }),
    );

    await service.remove('u1');
    expect(userRepository.remove).toHaveBeenCalledWith(
      expect.objectContaining({ id: 'u1' }),
    );
  });
});
