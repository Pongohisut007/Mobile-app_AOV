import type { DataSource } from 'typeorm';
import { NotificationType } from '../notifications/entities/notification.entity';
import type { NotificationsService } from '../notifications/notifications.service';
import { IapService } from './iap.service';

describe('IapService mock purchases', () => {
  it('is allowed in every environment, production included', async () => {
    const transaction = jest.fn().mockResolvedValue('purchased');
    const service = new IapService({ transaction } as unknown as DataSource);
    await expect(service.createMockPurchase('u1', 'item1')).resolves.toBe(
      'purchased',
    );
    expect(transaction).toHaveBeenCalledTimes(1);
  });

  it('tells the creator about a sale only after the purchase succeeds', async () => {
    const notifications = { notifyRecipeOwner: jest.fn() };
    const transaction = jest.fn();
    const service = new IapService(
      { transaction } as unknown as DataSource,
      notifications as unknown as NotificationsService,
    );

    transaction.mockResolvedValueOnce({ status: 'purchased', recipeId: 'r1' });
    await service.createMockPurchase('buyer', 'item1');
    expect(notifications.notifyRecipeOwner).toHaveBeenCalledWith({
      type: NotificationType.RECIPE_PURCHASED,
      recipeId: 'r1',
      actorId: 'buyer',
    });

    notifications.notifyRecipeOwner.mockClear();
    transaction.mockResolvedValueOnce({
      status: 'already_owned',
      recipeId: 'r1',
    });
    await service.createMockPurchase('buyer', 'item1');
    expect(notifications.notifyRecipeOwner).not.toHaveBeenCalled();
  });
});
