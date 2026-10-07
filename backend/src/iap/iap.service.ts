import { Injectable, NotFoundException, Optional } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { DataSource, EntityManager, IsNull, MoreThan } from 'typeorm';
import { CartItem } from '../cart/entities/cart-item.entity';
import { OrderItem } from '../orders/entities/order-item.entity';
import { Order, OrderStatus } from '../orders/entities/order.entity';
import { Payment, PaymentStatus } from '../payments/entities/payment.entity';
import {
  RecipeAccess,
  RecipeAccessType,
} from '../recipe-access/entities/recipe-access.entity';
import { assertPurchasable } from '../recipes/recipe-permissions';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/entities/notification.entity';

export interface MockPurchaseResult {
  status: 'purchased' | 'already_owned';
  recipeId: string;
  orderId: string | null;
  paymentId: string | null;
  transactionId: string | null;
}

/**
 * ซื้อจำลองใช้ได้ทุก environment รวม production
 * (ยังไม่มีระบบจ่ายเงินจริง แอปแจกเป็น APK ใช้ Google Play Billing ไม่ได้)
 */
@Injectable()
export class IapService {
  constructor(
    private readonly dataSource: DataSource,
    @Optional()
    private readonly notifications?: NotificationsService,
  ) {}

  async createMockPurchase(
    userId: string,
    cartItemId: string,
  ): Promise<MockPurchaseResult> {
    const result = await this.dataSource.transaction((manager) =>
      this.purchaseCartItem(manager, userId, cartItemId),
    );
    // แจ้ง creator หลังจ่ายเงินสำเร็จ (commit แล้ว) เท่านั้น
    if (result.status === 'purchased') {
      await this.notifications?.notifyRecipeOwner({
        type: NotificationType.RECIPE_PURCHASED,
        recipeId: result.recipeId,
        actorId: userId,
      });
    }
    return result;
  }

  private async purchaseCartItem(
    manager: EntityManager,
    userId: string,
    cartItemId: string,
  ): Promise<MockPurchaseResult> {
    const cartItem = await manager
      .getRepository(CartItem)
      .createQueryBuilder('cartItem')
      .innerJoinAndSelect('cartItem.cart', 'cart')
      .innerJoinAndSelect('cartItem.recipe', 'recipe')
      .where('cartItem.id = :cartItemId', { cartItemId })
      .andWhere('cart.user_id = :userId', { userId })
      .setLock('pessimistic_write')
      .getOne();

    if (!cartItem) {
      throw new NotFoundException(`Cart item ${cartItemId} not found`);
    }

    const existingAccess = await manager.getRepository(RecipeAccess).findOne({
      where: [
        {
          userId,
          recipeId: cartItem.recipeId,
          revokedAt: IsNull(),
          expiresAt: IsNull(),
        },
        {
          userId,
          recipeId: cartItem.recipeId,
          revokedAt: IsNull(),
          expiresAt: MoreThan(new Date()),
        },
      ],
    });

    if (existingAccess) {
      await manager.getRepository(CartItem).remove(cartItem);
      return {
        status: 'already_owned',
        recipeId: cartItem.recipeId,
        orderId: null,
        paymentId: null,
        transactionId: null,
      };
    }

    // ตรวจอีกครั้งตอนจ่าย: สูตรอาจถูกซ่อน/เปลี่ยนเป็นฟรีหลังใส่ตะกร้าไปแล้ว
    assertPurchasable(cartItem.recipe, userId);

    const now = new Date();
    const transactionId = `mock_${randomUUID()}`;
    const orderNumber = `MOCK-${Date.now()}-${randomUUID().slice(0, 8)}`;
    const amount = cartItem.recipe.price;

    const order = await manager.getRepository(Order).save(
      manager.getRepository(Order).create({
        orderNumber,
        userId,
        subtotal: amount,
        discountAmount: '0.00',
        totalAmount: amount,
        currency: 'THB',
        status: OrderStatus.PAID,
        paidAt: now,
        cancelledAt: null,
      }),
    );

    const orderItem = await manager.getRepository(OrderItem).save(
      manager.getRepository(OrderItem).create({
        orderId: order.id,
        recipeId: cartItem.recipeId,
        recipeTitle: cartItem.recipe.title,
        creatorId: cartItem.recipe.creatorId,
        unitPrice: amount,
      }),
    );

    const payment = await manager.getRepository(Payment).save(
      manager.getRepository(Payment).create({
        orderId: order.id,
        provider: 'mock_google_play',
        providerTransactionId: transactionId,
        paymentMethod: 'test_purchase',
        amount,
        currency: 'THB',
        status: PaymentStatus.SUCCESSFUL,
        paidAt: now,
        failureReason: null,
        providerResponse: {
          environment: 'mock',
          productId: this.productIdFor(cartItem.recipe.slug),
        },
      }),
    );

    const previousAccess = await manager.getRepository(RecipeAccess).findOne({
      where: { userId, recipeId: cartItem.recipeId },
    });

    if (previousAccess) {
      previousAccess.orderItemId = orderItem.id;
      previousAccess.accessType = RecipeAccessType.PURCHASE;
      previousAccess.grantedAt = now;
      previousAccess.expiresAt = null;
      previousAccess.revokedAt = null;
      await manager.getRepository(RecipeAccess).save(previousAccess);
    } else {
      await manager.getRepository(RecipeAccess).save(
        manager.getRepository(RecipeAccess).create({
          userId,
          recipeId: cartItem.recipeId,
          orderItemId: orderItem.id,
          accessType: RecipeAccessType.PURCHASE,
          grantedAt: now,
          expiresAt: null,
          revokedAt: null,
        }),
      );
    }

    await manager.getRepository(CartItem).remove(cartItem);

    return {
      status: 'purchased',
      recipeId: cartItem.recipeId,
      orderId: order.id,
      paymentId: payment.id,
      transactionId,
    };
  }

  private productIdFor(slug: string): string {
    return `recipe_${slug}`
      .toLowerCase()
      .replace(/[^a-z0-9_]+/g, '_')
      .replace(/^_+|_+$/g, '');
  }
}
