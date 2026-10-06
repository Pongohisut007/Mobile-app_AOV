import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity';
import { User } from './user.entity';

/** ผู้ให้บริการเข้าสู่ระบบภายนอก (เพิ่มเจ้าใหม่ได้ที่นี่ เช่น apple) */
export enum IdentityProvider {
  GOOGLE = 'google',
}

/**
 * บัญชีภายนอกที่ผูกกับผู้ใช้ (เข้าสู่ระบบด้วย Google ฯลฯ)
 * ผู้ใช้หนึ่งคนผูกได้เจ้าละหนึ่งบัญชี และบัญชีภายนอกหนึ่งอันผูกได้กับผู้ใช้คนเดียว
 */
@Entity('user_identities')
@Index(['provider', 'providerUserId'], { unique: true })
@Index(['userId', 'provider'], { unique: true })
export class UserIdentity extends BaseEntity {
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ type: 'enum', enum: IdentityProvider })
  provider!: IdentityProvider;

  /** id ของผู้ใช้ฝั่งผู้ให้บริการ (Google: ค่า sub ใน ID token) ไม่เปลี่ยนแม้เปลี่ยนอีเมล */
  @Column({ name: 'provider_user_id', type: 'varchar', length: 255 })
  providerUserId!: string;

  /** อีเมลจากผู้ให้บริการตอนผูก (เก็บไว้ดูย้อนหลัง ไม่ได้ใช้จับคู่) */
  @Column({ type: 'varchar', length: 255, nullable: true })
  email!: string | null;
}
