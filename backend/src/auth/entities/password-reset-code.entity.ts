import { Column, Entity, JoinColumn, OneToOne } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';

/**
 * รหัส 6 หลักสำหรับรีเซ็ตรหัสผ่าน (ผู้ใช้หนึ่งคนมีได้ทีละรหัส ขอใหม่ = ทับของเดิม)
 * เก็บแค่ hash ของรหัส ใช้แล้ว/ตั้งรหัสใหม่สำเร็จ = ลบแถวทิ้ง
 */
@Entity('password_reset_codes')
export class PasswordResetCode extends BaseEntity {
  @Column({ name: 'user_id', type: 'uuid', unique: true })
  userId!: string;

  @OneToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'code_hash', type: 'varchar', length: 100 })
  codeHash!: string;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt!: Date;

  /** กรอกผิดไปกี่ครั้งแล้ว (ครบกำหนด = ต้องขอรหัสใหม่) */
  @Column({ type: 'int', default: 0 })
  attempts!: number;

  /** ส่งอีเมลล่าสุดเมื่อไร (กันกดขอรหัสถี่ ๆ) */
  @Column({ name: 'sent_at', type: 'timestamptz' })
  sentAt!: Date;
}
