import {
  Column,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

/**
 * สวิตช์ push ของแต่ละบัญชี (ยังไม่มีแถว = เปิดทุกอย่าง)
 * มีผลกับ push เท่านั้น กล่องแจ้งเตือนในแอปเก็บทุกเรื่องเสมอ
 */
@Entity('notification_settings')
export class NotificationSettings {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  /** สวิตช์หลัก ปิด = ไม่ส่ง push เลย */
  @Column({ name: 'push_enabled', type: 'boolean', default: true })
  pushEnabled!: boolean;

  @Column({ type: 'boolean', default: true })
  sales!: boolean;

  @Column({ type: 'boolean', default: true })
  moderation!: boolean;

  @Column({ type: 'boolean', default: true })
  reviews!: boolean;

  @Column({ type: 'boolean', default: true })
  comments!: boolean;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
