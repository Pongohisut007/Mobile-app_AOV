import { Check, Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';
import { Banner } from './banner.entity';

// หนึ่งคนให้คะแนน event ได้ครั้งเดียว ให้ซ้ำ = แก้คะแนนเดิม
@Entity('banner_ratings')
@Index(['userId', 'bannerId'], { unique: true })
@Check('chk_banner_ratings_rating', '"rating" BETWEEN 1 AND 5')
export class BannerRating extends BaseEntity {
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'banner_id', type: 'uuid' })
  bannerId!: string;

  @ManyToOne(() => Banner, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'banner_id' })
  banner!: Banner;

  @Column({ type: 'smallint' })
  rating!: number;

  @Column({ type: 'text', nullable: true })
  comment!: string | null;
}
