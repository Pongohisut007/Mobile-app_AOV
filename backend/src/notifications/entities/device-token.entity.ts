import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';

export enum DevicePlatform {
  ANDROID = 'android',
  IOS = 'ios',
}

/**
 * FCM token ของเครื่องที่ login อยู่ คนหนึ่งมีได้หลายเครื่อง
 * token เดียวผูกได้บัญชีเดียว (เครื่องเดิมเปลี่ยนบัญชี = ย้ายไปบัญชีใหม่)
 */
@Entity('device_tokens')
export class DeviceToken extends BaseEntity {
  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 512 })
  token!: string;

  @Column({ type: 'enum', enum: DevicePlatform })
  platform!: DevicePlatform;

  /** ภาษาของแอปในเครื่องนั้น ใช้เลือกภาษาข้อความ push */
  @Column({ type: 'varchar', length: 8, default: 'th' })
  locale!: string;

  @Column({
    name: 'last_seen_at',
    type: 'timestamptz',
    default: () => 'CURRENT_TIMESTAMP',
  })
  lastSeenAt!: Date;
}
