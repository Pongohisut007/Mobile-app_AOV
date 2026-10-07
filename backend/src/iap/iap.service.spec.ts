import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { DataSource } from 'typeorm';
import { NotificationType } from '../notifications/entities/notification.entity';
import type { NotificationsService } from '../notifications/notifications.service';
import { IapService } from './iap.service';

describe('IapService mock purchases', () => {
  const serviceWith = (values: Record<string, string>) => {
    const transaction = jest.fn().mockResolvedValue('purchased');
    const service = new IapService(
      { transaction } as unknown as DataSource,
      {
        get: (key: string) => values[key],
      } as unknown as ConfigService,
    );
    return { service, transaction };
  };

  it('is blocked in production even if enabled explicitly', async () => {
    const { service, transaction } = serviceWith({
      'app.env': 'production',
      IAP_MOCK_ENABLED: 'true',
    });
    await expect(
      service.createMockPurchase('u1', 'item1'),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(transaction).not.toHaveBeenCalled();
  });

  it('is allowed on staging and development', async () => {
    for (const env of ['staging', 'development']) {
      const { service } = serviceWith({ 'app.env': env });
      await expect(service.createMockPurchase('u1', 'item1')).resolves.toBe(
        'purchased',
      );
    }
  });

  it('can be switched off outside production', async () => {
    const { service } = serviceWith({
      'app.env': 'staging',
      IAP_MOCK_ENABLED: 'false',
    });
    await expect(
      service.createMockPurchase('u1', 'item1'),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
  it('tells the creator about a sale only after the purchase succeeds', async () => {
    const notifications = { notifyRecipeOwner: jest.fn() };
    const transaction = jest.fn();
    const service = new IapService(
      { transaction } as unknown as DataSource,
      { get: () => 'development' } as unknown as ConfigService,
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
