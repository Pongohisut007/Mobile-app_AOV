import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity';
import { Recipe } from '../../recipes/entities/recipe.entity';
import { User } from '../../users/entities/user.entity';

export enum NotificationType {
  /** มีคนซื้อสูตรของคุณ (ถึง creator) */
  RECIPE_PURCHASED = 'recipe_purchased',
  /** admin ซ่อน/ไม่ผ่านการตรวจ สูตรของคุณ */
  RECIPE_MODERATED = 'recipe_moderated',
  /** รีวิวใหม่บนสูตรของคุณ */
  RECIPE_REVIEWED = 'recipe_reviewed',
  /** คอมเมนต์ใหม่บนสูตรของคุณ */
  RECIPE_COMMENTED = 'recipe_commented',
}

/** รายละเอียดเฉพาะของแต่ละประเภท แอปใช้ประกอบข้อความเองตามภาษาที่ผู้ใช้เลือก */
export interface NotificationData {
  /** RECIPE_MODERATED */
  status?: 'hidden' | 'rejected';
  /** RECIPE_REVIEWED */
  rating?: number;
  /** RECIPE_REVIEWED / RECIPE_COMMENTED: ข้อความตัดสั้น */
  excerpt?: string;
}

/**
 * กล่องแจ้งเตือนในแอป หนึ่งแถว = หนึ่งเรื่องที่แจ้งผู้ใช้ [userId]
 * push (FCM) ส่งจากแถวนี้ ปิด push แล้วก็ยังเห็นในกล่องแจ้งเตือน
 */
@Entity('notifications')
@Index(['userId', 'createdAt'])
export class Notification extends BaseEntity {
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  /** คนที่ทำให้เกิดเรื่องนี้ (คนซื้อ/รีวิว/คอมเมนต์) null = ทีมงาน */
  @Column({ name: 'actor_id', type: 'uuid', nullable: true })
  actorId!: string | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'actor_id' })
  actor!: User | null;

  @Column({ type: 'enum', enum: NotificationType })
  type!: NotificationType;

  @Column({ name: 'recipe_id', type: 'uuid', nullable: true })
  recipeId!: string | null;

  // สูตรถูกลบจริง = แจ้งเตือนเรื่องนั้นไม่มีความหมายแล้ว ลบตาม
  @ManyToOne(() => Recipe, { nullable: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'recipe_id' })
  recipe!: Recipe | null;

  @Column({ type: 'jsonb', default: () => "'{}'" })
  data!: NotificationData;

  @Column({ name: 'read_at', type: 'timestamptz', nullable: true })
  readAt!: Date | null;
}
