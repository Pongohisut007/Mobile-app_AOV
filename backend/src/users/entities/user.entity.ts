import { Column, Entity, Index, OneToMany, OneToOne } from 'typeorm';
import { Cart } from '../../cart/entities/cart.entity';
import { BaseEntity } from '../../common/entities/base.entity';
import { Favorite } from '../../favorites/entities/favorite.entity';
import { Order } from '../../orders/entities/order.entity';
import { RecipeAccess } from '../../recipe-access/entities/recipe-access.entity';
import { Recipe } from '../../recipes/entities/recipe.entity';
import { Review } from '../../reviews/entities/review.entity';

export enum UserRole {
  USER = 'user',
  CREATOR = 'creator',
  ADMIN = 'admin',
}

export enum UserStatus {
  ACTIVE = 'active',
  SUSPENDED = 'suspended',
  DISABLED = 'disabled',
}

@Entity('users')
export class User extends BaseEntity {
  @Index({ unique: true })
  @Column({ type: 'varchar', length: 255 })
  email!: string;

  // null = สมัครผ่าน Google และยังไม่ได้ตั้งรหัสผ่าน (เข้าได้ทาง Google อย่างเดียว)
  @Column({
    name: 'password_hash',
    type: 'varchar',
    length: 255,
    nullable: true,
    select: false,
  })
  passwordHash!: string | null;

  @Column({ name: 'display_name', type: 'varchar', length: 150 })
  displayName!: string;

  @Column({ name: 'avatar_url', type: 'text', nullable: true })
  avatarUrl!: string | null;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.USER })
  role!: UserRole;

  @Column({ type: 'enum', enum: UserStatus, default: UserStatus.ACTIVE })
  status!: UserStatus;

  // ฝังอยู่ใน JWT ทุกใบ เพิ่มเลขนี้ = token เก่าทุกเครื่องใช้ไม่ได้ทันที
  // (ออกจากระบบทุกอุปกรณ์ / เปลี่ยนรหัสผ่าน / ลบบัญชี)
  @Column({ name: 'token_version', type: 'integer', default: 0 })
  tokenVersion!: number;

  @OneToMany(() => Recipe, (recipe) => recipe.creator)
  recipes!: Recipe[];

  @OneToMany(() => Order, (order) => order.user)
  orders!: Order[];

  @OneToMany(() => RecipeAccess, (access) => access.user)
  recipeAccesses!: RecipeAccess[];

  @OneToMany(() => Review, (review) => review.user)
  reviews!: Review[];

  @OneToMany(() => Favorite, (favorite) => favorite.user)
  favorites!: Favorite[];

  @OneToOne(() => Cart, (cart) => cart.user)
  cart!: Cart | null;
}
