import { Injectable, NotFoundException, Optional } from '@nestjs/common';
import { CacheNamespace } from '../cache/app-cache.module';
import { AppCacheService } from '../cache/app-cache.service';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CartItem } from '../cart/entities/cart-item.entity';
import { Cart } from '../cart/entities/cart.entity';
import { Favorite } from '../favorites/entities/favorite.entity';
import {
  RecipeAccess,
  RecipeAccessType,
} from '../recipe-access/entities/recipe-access.entity';
import {
  Recipe,
  RecipeStatus,
  RecipeType,
} from '../recipes/entities/recipe.entity';
import { Review, ReviewStatus } from '../reviews/entities/review.entity';
import type { UserProfileResponse } from './dto/user-profile-response.dto';
import {
  IdentityProvider,
  UserIdentity,
} from './entities/user-identity.entity';
import { User, UserRole, UserStatus } from './entities/user.entity';

type ActivityCountKey =
  | 'reviewCount'
  | 'salesCount'
  | 'officialSavedCount'
  | 'communitySavedCount'
  | 'commentsReceivedCount'
  | 'reviewsWrittenCount';

export interface CreateUserInput {
  email: string;
  passwordHash: string;
  displayName: string;
  avatarUrl?: string | null;
  role?: UserRole;
}

export interface UpdateUserInput {
  email?: string;
  displayName?: string;
  avatarUrl?: string | null;
  role?: UserRole;
  status?: UserStatus;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Recipe)
    private readonly recipeRepository: Repository<Recipe>,
    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,
    @InjectRepository(RecipeAccess)
    private readonly accessRepository: Repository<RecipeAccess>,
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
    @InjectRepository(UserIdentity)
    private readonly identityRepository: Repository<UserIdentity>,
    @Optional()
    private readonly cache?: AppCacheService,
  ) {}

  findAll(): Promise<User[]> {
    return this.userRepository.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) throw new NotFoundException(`User with id ${id} not found`);
    return user;
  }

  findById(id: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { id } });
  }

  findByEmail(email: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { email: email.toLowerCase() },
    });
  }

  /** ใช้ตอน login เท่านั้น เพราะ passwordHash เป็นคอลัมน์ select: false */
  findByEmailWithPassword(email: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { email: email.toLowerCase() },
      select: {
        id: true,
        email: true,
        passwordHash: true,
        displayName: true,
        avatarUrl: true,
        role: true,
        status: true,
      },
    });
  }

  /** ใช้ตอนเปลี่ยนรหัสผ่านเท่านั้น (ต้องเทียบรหัสเดิม) */
  findByIdWithPassword(id: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { id },
      select: { id: true, passwordHash: true },
    });
  }

  /** ผู้ใช้ที่ผูกบัญชีภายนอกนี้ไว้ (เช่น บัญชี Google ตาม sub) */
  async findByIdentity(
    provider: IdentityProvider,
    providerUserId: string,
  ): Promise<User | null> {
    const identity = await this.identityRepository.findOne({
      where: { provider, providerUserId },
      relations: { user: true },
    });
    return identity?.user ?? null;
  }

  /** ผูกบัญชีภายนอกเข้ากับผู้ใช้ที่มีอยู่แล้ว (เช่น อีเมลตรงกับบัญชี Google) */
  async linkIdentity(
    userId: string,
    provider: IdentityProvider,
    providerUserId: string,
    email: string | null,
  ): Promise<void> {
    await this.identityRepository.save(
      this.identityRepository.create({
        userId,
        provider,
        providerUserId,
        email,
      }),
    );
  }

  /** สมัครผ่านบัญชีภายนอก: สร้างผู้ใช้ไม่มีรหัสผ่าน + ผูกบัญชีในครั้งเดียว */
  async createWithIdentity(
    input: Omit<CreateUserInput, 'passwordHash'>,
    provider: IdentityProvider,
    providerUserId: string,
  ): Promise<User> {
    const email = input.email.toLowerCase();
    const id = await this.userRepository.manager.transaction(
      async (manager) => {
        const user = await manager.save(
          manager.create(User, { ...input, email, passwordHash: null }),
        );
        await manager.save(
          manager.create(UserIdentity, {
            userId: user.id,
            provider,
            providerUserId,
            email,
          }),
        );
        return user.id;
      },
    );
    return this.findOne(id);
  }

  /** มีรหัสผ่านไหม (สมัครผ่าน Google แล้วยังไม่ตั้ง = ไม่มี) */
  async hasPassword(id: string): Promise<boolean> {
    const user = await this.findByIdWithPassword(id);
    return Boolean(user?.passwordHash);
  }

  /** เปลี่ยนรหัสผ่าน + เพิ่ม token_version ให้เครื่องอื่นหลุด คืน user ล่าสุดไว้ออก token ใหม่ */
  async updatePasswordHash(id: string, passwordHash: string): Promise<User> {
    await this.userRepository.update({ id }, { passwordHash });
    await this.bumpTokenVersion(id);
    return this.findOne(id);
  }

  /** token ทุกใบที่ออกไปแล้วของ user นี้ใช้ไม่ได้ทันที */
  async bumpTokenVersion(id: string): Promise<void> {
    await this.userRepository.increment({ id }, 'tokenVersion', 1);
  }

  /**
   * ลบบัญชีตัวเอง: ปิดบัญชี + ลบข้อมูลส่วนตัว (ไม่ลบแถวจริง)
   * - สูตรของคนนี้ถูกซ่อนจากทุกรายการ (RecipesService กรองผู้สร้างที่ไม่ active)
   *   แต่คนที่ซื้อไปแล้วยังเปิดจากหน้า Purchased ได้
   * - หัวใจ/ของในตะกร้า ที่คนอื่นกดสูตรของคนนี้ไว้ถูกลบ (ไม่งั้นยังโผล่/ยังซื้อได้)
   * - คอมเมนต์/รีวิวยังอยู่ แต่ชื่อเป็น "ผู้ใช้ที่ลบบัญชีแล้ว" ไม่มีรูป
   * - อีเมลถูกเปลี่ยน คนเดิมกลับมาสมัครใหม่ด้วยอีเมลเดิมได้
   */
  async deleteOwnAccount(
    id: string,
    randomPasswordHash: string,
  ): Promise<void> {
    await this.userRepository.manager.transaction(async (manager) => {
      const ownRecipeIds = `(SELECT id FROM recipes WHERE creator_id = :id)`;

      await manager
        .createQueryBuilder()
        .delete()
        .from(Favorite)
        .where(`user_id = :id OR recipe_id IN ${ownRecipeIds}`, { id })
        .execute();
      await manager
        .createQueryBuilder()
        .delete()
        .from(CartItem)
        .where(`recipe_id IN ${ownRecipeIds}`, { id })
        .execute();
      await manager.delete(Cart, { userId: id });
      // ปลดบัญชี Google ออก เจ้าของสมัครใหม่ด้วยบัญชีเดิมได้
      await manager.delete(UserIdentity, { userId: id });

      await manager.update(
        User,
        { id },
        {
          email: `deleted+${id}@deleted.invalid`,
          displayName: 'ผู้ใช้ที่ลบบัญชีแล้ว',
          avatarUrl: null,
          passwordHash: randomPasswordHash,
          status: UserStatus.DISABLED,
        },
      );
      await manager.increment(User, { id }, 'tokenVersion', 1);
    });

    // สูตรถูกซ่อน ชื่อในคอมเมนต์/รีวิวเปลี่ยน
    await Promise.all([
      this.cache?.invalidate(CacheNamespace.recipes),
      this.cache?.invalidate(CacheNamespace.comments),
      this.cache?.invalidate(CacheNamespace.reviews),
    ]);
  }

  async findProfile(id: string): Promise<UserProfileResponse> {
    const user = await this.findOne(id);

    const [
      recipeCount,
      draftCount,
      savedCount,
      purchasedCount,
      ratingRow,
      activity,
      hasPassword,
    ] = await Promise.all([
      this.recipeRepository.count({
        where: { creatorId: id, status: RecipeStatus.PUBLISHED },
      }),
      this.recipeRepository.count({
        where: { creatorId: id, status: RecipeStatus.DRAFT },
      }),
      this.favoriteRepository.count({ where: { userId: id } }),
      this.accessRepository
        .createQueryBuilder('access')
        .where('access.user_id = :userId', { userId: id })
        .andWhere('access.access_type = :accessType', {
          accessType: RecipeAccessType.PURCHASE,
        })
        .andWhere('access.revoked_at IS NULL')
        .andWhere(
          '(access.expires_at IS NULL OR access.expires_at > CURRENT_TIMESTAMP)',
        )
        .getCount(),
      this.reviewRepository
        .createQueryBuilder('review')
        .innerJoin('review.recipe', 'recipe')
        .select('COALESCE(AVG(review.rating), 0)', 'rating')
        .where('recipe.creator_id = :creatorId', { creatorId: id })
        .andWhere('recipe.status = :recipeStatus', {
          recipeStatus: RecipeStatus.PUBLISHED,
        })
        .andWhere('review.status = :reviewStatus', {
          reviewStatus: ReviewStatus.PUBLISHED,
        })
        .getRawOne<{ rating: string | number | null }>(),
      this.loadActivityCounts(id),
      this.hasPassword(id),
    ]);

    const rating = Number(ratingRow?.rating ?? 0);

    return {
      id: user.id,
      displayName: user.displayName,
      email: user.email,
      avatarUrl: user.avatarUrl,
      role: user.role,
      status: user.status,
      recipeCount,
      purchasedCount,
      savedCount,
      draftCount,
      rating: Number.isFinite(rating) ? Number(rating.toFixed(1)) : 0,
      ...activity,
      hasPassword,
    };
  }

  /**
   * ตัวเลขผลงานบนหน้าโปรไฟล์ นับเฉพาะสูตรที่เผยแพร่แล้ว
   * หัวใจ/ความคิดเห็น/การซื้อของเจ้าของสูตรเองไม่นับ (นับเฉพาะจากคนอื่น)
   */
  private async loadActivityCounts(id: string) {
    const ownPublished = `JOIN recipes r ON r.id = t.recipe_id
      WHERE r.creator_id = $1 AND r.status = $2`;
    const rows: Partial<Record<ActivityCountKey, string | number>>[] =
      await this.userRepository.query(
        `SELECT
          (SELECT COUNT(*) FROM reviews t ${ownPublished}
            AND t.status = $3) AS "reviewCount",
          (SELECT COUNT(*) FROM recipe_access t JOIN recipes r ON r.id = t.recipe_id
            WHERE r.creator_id = $1 AND t.access_type = $4
            AND t.revoked_at IS NULL AND t.user_id <> $1) AS "salesCount",
          (SELECT COUNT(*) FROM favorites t ${ownPublished}
            AND r.type = $5 AND t.user_id <> $1) AS "officialSavedCount",
          (SELECT COUNT(*) FROM favorites t ${ownPublished}
            AND r.type = $6 AND t.user_id <> $1) AS "communitySavedCount",
          (SELECT COUNT(*) FROM recipe_comments t ${ownPublished}
            AND r.type = $6 AND t.user_id <> $1) AS "commentsReceivedCount",
          (SELECT COUNT(*) FROM reviews t
            WHERE t.user_id = $1 AND t.status = $3) AS "reviewsWrittenCount"`,
        [
          id,
          RecipeStatus.PUBLISHED,
          ReviewStatus.PUBLISHED,
          RecipeAccessType.PURCHASE,
          RecipeType.OFFICIAL,
          RecipeType.COMMUNITY,
        ],
      );
    const row = rows[0] ?? {};
    // COUNT ของ postgres กลับมาเป็น string
    const count = (value: string | number | undefined) =>
      Number(value ?? 0) || 0;
    return {
      reviewCount: count(row.reviewCount),
      salesCount: count(row.salesCount),
      officialSavedCount: count(row.officialSavedCount),
      communitySavedCount: count(row.communitySavedCount),
      commentsReceivedCount: count(row.commentsReceivedCount),
      reviewsWrittenCount: count(row.reviewsWrittenCount),
    };
  }

  async create(input: CreateUserInput): Promise<User> {
    const user = await this.userRepository.save(
      this.userRepository.create({
        ...input,
        email: input.email.toLowerCase(),
      }),
    );
    return this.findOne(user.id);
  }

  /** ผู้ใช้แก้โปรไฟล์ตัวเอง: แค่ชื่อกับรูป */
  async updateOwnProfile(
    id: string,
    input: { displayName?: string; avatarUrl?: string | null },
  ): Promise<UserProfileResponse> {
    const user = await this.findOne(id);
    if (input.displayName !== undefined) user.displayName = input.displayName;
    // null = ลบรูป, undefined = ไม่แตะ
    if (input.avatarUrl !== undefined) user.avatarUrl = input.avatarUrl;
    await this.userRepository.save(user);

    // ชื่อ/รูปผู้ใช้ฝังอยู่ในข้อมูลสูตร (ผู้สร้าง) คอมเมนต์ และรีวิวที่ cache ไว้
    await Promise.all([
      this.cache?.invalidate(CacheNamespace.recipes),
      this.cache?.invalidate(CacheNamespace.comments),
      this.cache?.invalidate(CacheNamespace.reviews),
    ]);
    return this.findProfile(id);
  }

  async update(id: string, input: UpdateUserInput): Promise<User> {
    const user = await this.findOne(id);
    Object.assign(user, input, { id: user.id });
    await this.userRepository.save(user);
    return this.findOne(user.id);
  }

  async remove(id: string): Promise<void> {
    const user = await this.findOne(id);
    await this.userRepository.remove(user);
  }
}
