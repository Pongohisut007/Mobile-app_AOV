import { Logger, NotFoundException } from '@nestjs/common';
import { In, Repository } from 'typeorm';
import { Recipe } from '../recipes/entities/recipe.entity';
import { User } from '../users/entities/user.entity';
import { DeviceToken } from './entities/device-token.entity';
import { NotificationSettings } from './entities/notification-settings.entity';
import { Notification, NotificationType } from './entities/notification.entity';
import { excerpt, notificationText } from './notification-text';
import { NotificationsService } from './notifications.service';
import { PushService } from './push.service';

/** รอให้งานเบื้องหลัง (ส่ง push) ทำจนจบ */
const flush = () => new Promise((resolve) => setImmediate(resolve));

describe('NotificationsService', () => {
  const notifications = {
    create: jest.fn((row: Partial<Notification>) => row),
    save: jest.fn(),
    findAndCount: jest.fn(),
    count: jest.fn(),
    exists: jest.fn(),
    update: jest.fn(),
  };
  const devices = {
    find: jest.fn(),
    delete: jest.fn(),
    upsert: jest.fn(),
  };
  const settings = { findOne: jest.fn(), upsert: jest.fn() };
  const recipes = { findOne: jest.fn() };
  const users = { findOne: jest.fn() };
  const push = { enabled: true, send: jest.fn() };
  let service: NotificationsService;

  beforeEach(() => {
    jest.clearAllMocks();
    push.enabled = true;
    recipes.findOne.mockResolvedValue({
      id: 'r1',
      creatorId: 'owner',
      title: 'ต้มยำ',
      titleEn: 'Tom yum',
    });
    notifications.save.mockImplementation((row: Partial<Notification>) =>
      Promise.resolve({ ...row, id: 'n1' }),
    );
    settings.findOne.mockResolvedValue(null);
    users.findOne.mockResolvedValue({ id: 'buyer', displayName: 'สมชาย' });
    devices.find.mockResolvedValue([
      { token: 'token-th', locale: 'th' },
      { token: 'token-en', locale: 'en' },
    ]);
    push.send.mockResolvedValue([]);
    service = new NotificationsService(
      notifications as unknown as Repository<Notification>,
      devices as unknown as Repository<DeviceToken>,
      settings as unknown as Repository<NotificationSettings>,
      recipes as unknown as Repository<Recipe>,
      users as unknown as Repository<User>,
      push as unknown as PushService,
    );
  });

  describe('notifyRecipeOwner', () => {
    it('stores the notification for the recipe owner and pushes it in each language', async () => {
      await service.notifyRecipeOwner({
        type: NotificationType.RECIPE_PURCHASED,
        recipeId: 'r1',
        actorId: 'buyer',
      });
      await flush();

      expect(notifications.save).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'owner',
          actorId: 'buyer',
          type: NotificationType.RECIPE_PURCHASED,
          recipeId: 'r1',
          readAt: null,
        }),
      );
      expect(push.send).toHaveBeenCalledWith(['token-th'], {
        title: 'มีคนซื้อสูตรของคุณ',
        body: 'สมชาย ซื้อ "ต้มยำ"',
        data: {
          notificationId: 'n1',
          type: NotificationType.RECIPE_PURCHASED,
          recipeId: 'r1',
        },
      });
      expect(push.send).toHaveBeenCalledWith(
        ['token-en'],
        expect.objectContaining({ body: 'สมชาย bought "Tom yum"' }),
      );
    });

    it('does not notify people about their own actions', async () => {
      await service.notifyRecipeOwner({
        type: NotificationType.RECIPE_COMMENTED,
        recipeId: 'r1',
        actorId: 'owner',
      });

      expect(notifications.save).not.toHaveBeenCalled();
    });

    it('keeps the inbox entry but skips push when that kind is switched off', async () => {
      settings.findOne.mockResolvedValue({
        pushEnabled: true,
        sales: true,
        moderation: true,
        reviews: false,
        comments: true,
      });

      await service.notifyRecipeOwner({
        type: NotificationType.RECIPE_REVIEWED,
        recipeId: 'r1',
        actorId: 'buyer',
        data: { rating: 5 },
      });
      await flush();

      expect(notifications.save).toHaveBeenCalled();
      expect(push.send).not.toHaveBeenCalled();
    });

    it('skips push entirely when the master switch is off', async () => {
      settings.findOne.mockResolvedValue({
        pushEnabled: false,
        sales: true,
        moderation: true,
        reviews: true,
        comments: true,
      });

      await service.notifyRecipeOwner({
        type: NotificationType.RECIPE_PURCHASED,
        recipeId: 'r1',
        actorId: 'buyer',
      });
      await flush();

      expect(push.send).not.toHaveBeenCalled();
    });

    it('removes device tokens that FCM reports as dead', async () => {
      push.send.mockImplementation((tokens: string[]) =>
        Promise.resolve(tokens.includes('token-en') ? ['token-en'] : []),
      );

      await service.notifyRecipeOwner({
        type: NotificationType.RECIPE_PURCHASED,
        recipeId: 'r1',
        actorId: 'buyer',
      });
      await flush();

      expect(devices.delete).toHaveBeenCalledWith({ token: In(['token-en']) });
    });

    it('never throws back to the purchase/review/comment that triggered it', async () => {
      notifications.save.mockRejectedValue(new Error('db down'));
      const logged = jest
        .spyOn(Logger.prototype, 'error')
        .mockImplementation(() => undefined);

      await expect(
        service.notifyRecipeOwner({
          type: NotificationType.RECIPE_PURCHASED,
          recipeId: 'r1',
          actorId: 'buyer',
        }),
      ).resolves.toBeUndefined();
      expect(logged).toHaveBeenCalled();
      logged.mockRestore();
    });

    it('stores notifications even when push is not configured', async () => {
      push.enabled = false;

      await service.notifyRecipeOwner({
        type: NotificationType.RECIPE_MODERATED,
        recipeId: 'r1',
        actorId: null,
        data: { status: 'hidden' },
      });
      await flush();

      expect(notifications.save).toHaveBeenCalled();
      expect(devices.find).not.toHaveBeenCalled();
    });
  });

  it('defaults every switch to on and merges updates', async () => {
    await expect(service.getSettings('u1')).resolves.toEqual({
      pushEnabled: true,
      sales: true,
      moderation: true,
      reviews: true,
      comments: true,
    });

    await expect(
      service.updateSettings('u1', { comments: false }),
    ).resolves.toEqual(
      expect.objectContaining({ comments: false, sales: true }),
    );
    expect(settings.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'u1', comments: false }),
      ['userId'],
    );
  });

  it('moves a device token to the account that registers it and caps devices', async () => {
    devices.find.mockResolvedValue(
      Array.from({ length: 12 }, (_, index) => ({ id: `d${index}` })),
    );

    await service.registerDevice('u1', {
      token: 'fcm-token-123',
      platform: 'android' as never,
      locale: 'en',
    });

    expect(devices.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'u1',
        token: 'fcm-token-123',
        locale: 'en',
      }),
      ['token'],
    );
    expect(devices.delete).toHaveBeenCalledWith({ id: In(['d10', 'd11']) });
  });

  it('marks only the owner’s notification as read', async () => {
    notifications.exists.mockResolvedValue(false);
    await expect(service.markRead('u1', 'n1')).rejects.toBeInstanceOf(
      NotFoundException,
    );

    notifications.exists.mockResolvedValue(true);
    await service.markRead('u1', 'n1');
    expect(notifications.update).toHaveBeenCalledWith(
      expect.objectContaining({ id: 'n1', userId: 'u1' }),
      { readAt: expect.any(Date) as unknown },
    );
  });
});

describe('notification text', () => {
  it('describes moderation without naming the admin', () => {
    expect(
      notificationText(
        {
          type: NotificationType.RECIPE_MODERATED,
          data: { status: 'rejected' },
          recipeTitle: 'ต้มยำ',
          actorName: 'ignored',
        },
        'th',
      ),
    ).toEqual({
      title: 'สูตรของคุณไม่ผ่านการตรวจ',
      body: '"ต้มยำ" ไม่ผ่านการตรวจ แก้ไขแล้วลองใหม่ได้',
    });
  });

  it('shortens long comments without splitting characters', () => {
    expect(excerpt('ก'.repeat(150), 10)).toBe(`${'ก'.repeat(9)}…`);
    expect(excerpt('  สั้น   ๆ  ')).toBe('สั้น ๆ');
  });
});
