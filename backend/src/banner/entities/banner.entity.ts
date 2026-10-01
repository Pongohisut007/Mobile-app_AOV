import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity';

@Entity('banners')
export class Banner extends BaseEntity {
  @Column({ name: 'image_url', type: 'text' })
  imageUrl!: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  title!: string | null;

  @Column({ type: 'text', nullable: true })
  description!: string | null;

  @Column({ name: 'start_date', type: 'timestamptz', nullable: true })
  startDate!: Date | null;

  @Column({ name: 'end_date', type: 'timestamptz', nullable: true })
  endDate!: Date | null;
}
