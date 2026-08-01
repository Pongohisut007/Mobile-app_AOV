// foods.entity.ts
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
} from 'typeorm';

@Entity('foods')
export class Food {
  @PrimaryGeneratedColumn()
  idfoods!: number;

  @Column()
  name!: string;

  @Column()
  category!: string;

  @Column()
  description!: string;

  @Column()
  file_path_image!: string;
}