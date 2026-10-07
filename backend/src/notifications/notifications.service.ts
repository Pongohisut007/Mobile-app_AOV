import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { PaginatedResult, toPaginated } from '../common/pagination';
import { Recipe } from '../recipes/entities/recipe.entity';
import { User } from '../users/entities/user.entity';
import {
  RegisterDeviceDto,
  UpdateNotificationSettingsDto,
} from './dto/notification.dto';
import { DeviceToken } from './entities/device-token.entity';
import { NotificationSettings } from './entities/notification-settings.entity';
import {
  Notification,
  NotificationData,
  NotificationType,
} from './entities/notification.entity';
import { notificationText, pushLocaleOf } from './notification-text';
import { PushService } from './push.service';

export interface NotifyRecipeOwnerInput {
  type: NotificationType;
  recipeId: string;
  /** คนที่ทำ null = ทีมงาน (เช่น admin ซ่อนสูตร) */
  actorId: string | null;
  data?: NotificationData;
}

export interface NotificationView {
  id: string;
  type: NotificationType;
  data: NotificationData;
  readAt: Date | null;
  createdAt: Date;
  actor: { id: string; displayName: string; avatarUrl: string | null } | null;
  recipe: {
    id: string;
    title: string;
    titleEn: string | null;
    coverImageUrl: string | null;
  } | null;
}

export type NotificationSettingsView = Omit<
  NotificationSettings,
  'userId' | 'user' | 'updatedAt'
>;

/** ประเภทแจ้งเตือน → สวิตช์ในหน้าตั้งค่า */
const SETTING_OF: Record<
  NotificationType,
  keyof Omit<NotificationSettingsView, 'pushEnabled'>
> = {
  [NotificationType.RECIPE_PURCHASED]: 'sales',
  [NotificationType.RECIPE_MODERATED]: 'moderation',
  [NotificationType.RECIPE_REVIEWED]: 'reviews',
  [NotificationType.RECIPE_COMMENTED]: 'comments',
};

const DEFAULT_SETTINGS: NotificationSettingsView = {
  pushEnabled: true,
  sales: true,
  moderation: true,
  reviews: true,
  comments: true,
};

/** เครื่องต่อบัญชีที่ยังส่ง push ให้ (เกินนี้ลบเครื่องที่เงียบไปนานสุด) */
const MAX_DEVICES_PER_USER = 10;

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    @InjectRepository(Notification)
    private readonly notificationRepository: Repository<Notification>,

    @InjectRepository(DeviceToken)
    private readonly deviceRepository: Repository<DeviceToken>,

    @InjectRepository(NotificationSettings)
    private readonly settingsRepository: Repository<NotificationSettings>,

    @InjectRepository(Recipe)
    private readonly recipeRepository: Repository<Recipe>,

    @InjectRepository(User)
    private readonly userRepository: Repository<User>,

    private readonly push: PushService,
  ) {}

  // ---- สร้างแจ้งเตือน ----

  /**
   * แจ้งเจ้าของสูตร: บันทึกลงกล่องแจ้งเตือน แล้วส่ง push เบื้องหลัง
   * ไม่โยน error กลับ: แจ้งเตือนพลาดต้องไม่ทำให้การซื้อ/รีวิว/คอมเมนต์ล้ม
   * เรียกหลัง transaction ของเรื่องนั้น commit แล้วเท่านั้น
   */
  async notifyRecipeOwner(input: NotifyRecipeOwnerInput): Promise<void> {
    try {
      const recipe = await this.recipeRepository.findOne({
        where: { id: input.recipeId },
        select: { id: true, creatorId: true, title: true, titleEn: true },
      });
      // ทำกับสูตรตัวเอง ไม่ต้องแจ้ง
      if (!recipe || recipe.creatorId === input.actorId) return;

      const notification = await this.notificationRepository.save(
        this.notificationRepository.create({
          userId: recipe.creatorId,
          actorId: input.actorId,
          type: input.type,
          recipeId: recipe.id,
          data: input.data ?? {},
          readAt: null,
        }),
      );

      // รอส่ง push ไม่ได้ (เรียก FCM ข้ามเน็ต) ผู้ใช้ที่กดซื้อ/คอมเมนต์จะต้องรอ
      void this.deliverPush(notification, recipe).catch((error: unknown) =>
        this.logger.warn(
          `Push for notification ${notification.id} failed: ${String(error)}`,
        ),
      );
    } catch (error) {
      this.logger.error(
        `Could not create ${input.type} notification for recipe ${input.recipeId}`,
        error instanceof Error ? error.stack : String(error),
      );
    }
  }

  private async deliverPush(
    notification: Notification,
    recipe: Pick<Recipe, 'id' | 'title' | 'titleEn'>,
  ): Promise<void> {
    if (!this.push.enabled) return;

    const settings = await this.getSettings(notification.userId);
    if (!settings.pushEnabled || !settings[SETTING_OF[notification.type]]) {
      return;
    }

    const devices = await this.deviceRepository.find({
      where: { userId: notification.userId },
      select: { token: true, locale: true },
    });
    if (devices.length === 0) return;

    const actor = notification.actorId
      ? await this.userRepository.findOne({
          where: { id: notification.actorId },
          select: { id: true, displayName: true },
        })
      : null;

    const data = {
      notificationId: notification.id,
      type: notification.type,
      recipeId: recipe.id,
    };

    // แต่ละเครื่องตั้งภาษาไม่เหมือนกัน ส่งทีละกลุ่มภาษา
    const dead: string[] = [];
    for (const locale of ['th', 'en'] as const) {
      const tokens = devices
        .filter((device) => pushLocaleOf(device.locale) === locale)
        .map((device) => device.token);
      if (tokens.length === 0) continue;

      const text = notificationText(
        {
          type: notification.type,
          data: notification.data,
          recipeTitle:
            locale === 'en' && recipe.titleEn ? recipe.titleEn : recipe.title,
          actorName:
            actor?.displayName ?? (locale === 'en' ? 'Someone' : 'มีคน'),
        },
        locale,
      );
      dead.push(...(await this.push.send(tokens, { ...text, data })));
    }

    if (dead.length > 0) {
      await this.deviceRepository.delete({ token: In(dead) });
    }
  }

  // ---- กล่องแจ้งเตือน ----

  async list(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<NotificationView>> {
    const [rows, total] = await this.notificationRepository.findAndCount({
      where: { userId },
      relations: { actor: true, recipe: true },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return toPaginated(
      rows.map((row) => this.toView(row)),
      total,
      page,
      limit,
    );
  }

  async unreadCount(userId: string): Promise<{ count: number }> {
    const count = await this.notificationRepository.count({
      where: { userId, readAt: IsNull() },
    });
    return { count };
  }

  async markRead(userId: string, id: string): Promise<void> {
    const exists = await this.notificationRepository.exists({
      where: { id, userId },
    });
    if (!exists) throw new NotFoundException(`Notification ${id} not found`);
    await this.notificationRepository.update(
      { id, userId, readAt: IsNull() },
      { readAt: new Date() },
    );
  }

  async markAllRead(userId: string): Promise<void> {
    await this.notificationRepository.update(
      { userId, readAt: IsNull() },
      { readAt: new Date() },
    );
  }

  // ---- ตั้งค่า ----

  async getSettings(userId: string): Promise<NotificationSettingsView> {
    const saved = await this.settingsRepository.findOne({ where: { userId } });
    if (!saved) return { ...DEFAULT_SETTINGS };
    return {
      pushEnabled: saved.pushEnabled,
      sales: saved.sales,
      moderation: saved.moderation,
      reviews: saved.reviews,
      comments: saved.comments,
    };
  }

  async updateSettings(
    userId: string,
    dto: UpdateNotificationSettingsDto,
  ): Promise<NotificationSettingsView> {
    const next = { ...(await this.getSettings(userId)), ...dto };
    await this.settingsRepository.upsert({ userId, ...next }, ['userId']);
    return next;
  }

  // ---- เครื่องที่รับ push ----

  /** เครื่องเดิมเปลี่ยนบัญชี = token ย้ายมาบัญชีนี้ บัญชีเก่าไม่ได้รับ push ที่เครื่องนี้แล้ว */
  async registerDevice(userId: string, dto: RegisterDeviceDto): Promise<void> {
    await this.deviceRepository.upsert(
      {
        userId,
        token: dto.token,
        platform: dto.platform,
        locale: dto.locale ?? 'th',
        lastSeenAt: new Date(),
      },
      ['token'],
    );

    const devices = await this.deviceRepository.find({
      where: { userId },
      select: { id: true },
      order: { lastSeenAt: 'DESC' },
    });
    const stale = devices
      .slice(MAX_DEVICES_PER_USER)
      .map((device) => device.id);
    if (stale.length > 0) await this.deviceRepository.delete({ id: In(stale) });
  }

  /**
   * เลิกรับ push ที่เครื่องนี้ (ตอนออกจากระบบ)
   * ไม่ต้อง login: session อาจหมดอายุไปแล้วตอนกดออก ถือ token ของเครื่องอยู่ก็พอ
   */
  async unregisterDevice(token: string): Promise<void> {
    await this.deviceRepository.delete({ token });
  }

  private toView(row: Notification): NotificationView {
    return {
      id: row.id,
      type: row.type,
      data: row.data ?? {},
      readAt: row.readAt,
      createdAt: row.createdAt,
      actor: row.actor
        ? {
            id: row.actor.id,
            displayName: row.actor.displayName,
            avatarUrl: row.actor.avatarUrl,
          }
        : null,
      recipe: row.recipe
        ? {
            id: row.recipe.id,
            title: row.recipe.title,
            titleEn: row.recipe.titleEn,
            coverImageUrl: row.recipe.coverImageUrl,
          }
        : null,
    };
  }
}
