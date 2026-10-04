import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, MoreThan, Repository } from 'typeorm';
import { PaginatedResult, toPaginated } from '../common/pagination';
import {
  RecipeAccess,
  RecipeAccessType,
} from './entities/recipe-access.entity';

@Injectable()
export class RecipeAccessService {
  constructor(
    @InjectRepository(RecipeAccess)
    private readonly accessRepository: Repository<RecipeAccess>,
  ) {}

  findAll(): Promise<RecipeAccess[]> {
    return this.accessRepository.find({ order: { grantedAt: 'DESC' } });
  }

  findPurchasedByUser(userId: string): Promise<RecipeAccess[]> {
    return this.purchasedQuery(userId)
      .leftJoinAndSelect('access.recipe', 'recipe')
      .leftJoinAndSelect('recipe.creator', 'creator')
      .leftJoinAndSelect('recipe.categories', 'category')
      .orderBy('access.granted_at', 'DESC')
      .getMany();
  }

  async findPurchasedPageByUser(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<RecipeAccess>> {
    const total = await this.purchasedQuery(userId).getCount();
    if (total === 0) return toPaginated([], total, page, limit);

    // หา id ของหน้านี้ก่อน (ไม่ join categories) ไม่งั้น limit นับแถวที่ join ซ้ำ
    const rows = await this.purchasedQuery(userId)
      .select('access.id', 'id')
      .addSelect('access.granted_at', 'granted_at')
      .orderBy('access.granted_at', 'DESC')
      .addOrderBy('access.id', 'ASC')
      .offset((page - 1) * limit)
      .limit(limit)
      .getRawMany<{ id: string }>();
    const ids = rows.map((row) => row.id);

    const accesses = await this.accessRepository.find({
      where: { id: In(ids) },
      relations: { recipe: { creator: true, categories: true } },
    });
    const byId = new Map(accesses.map((access) => [access.id, access]));
    const data = ids
      .map((id) => byId.get(id))
      .filter((access): access is RecipeAccess => access !== undefined);

    return toPaginated(data, total, page, limit);
  }

  /** id ของสูตรที่ซื้อแล้วทั้งหมด (แอปใช้เช็กว่าซื้อหรือยัง ไม่ต้องโหลดรายละเอียด) */
  async findPurchasedRecipeIds(userId: string): Promise<string[]> {
    const rows = await this.purchasedQuery(userId)
      .select('DISTINCT access.recipe_id', 'recipeId')
      .getRawMany<{ recipeId: string }>();
    return rows.map((row) => row.recipeId);
  }

  // สิทธิ์จากการซื้อที่ยังใช้ได้อยู่ของ user คนนี้
  private purchasedQuery(userId: string) {
    return this.accessRepository
      .createQueryBuilder('access')
      .where('access.user_id = :userId', { userId })
      .andWhere('access.access_type = :accessType', {
        accessType: RecipeAccessType.PURCHASE,
      })
      .andWhere('access.revoked_at IS NULL')
      .andWhere(
        '(access.expires_at IS NULL OR access.expires_at > CURRENT_TIMESTAMP)',
      );
  }

  async findOne(id: string): Promise<RecipeAccess> {
    const access = await this.accessRepository.findOne({
      where: { id },
      relations: { recipe: true },
    });
    if (!access)
      throw new NotFoundException(`Recipe access with id ${id} not found`);
    return access;
  }

  async hasActiveAccess(userId: string, recipeId: string): Promise<boolean> {
    const permanent = await this.accessRepository.exists({
      where: { userId, recipeId, revokedAt: IsNull(), expiresAt: IsNull() },
    });
    if (permanent) return true;
    return this.accessRepository.exists({
      where: {
        userId,
        recipeId,
        revokedAt: IsNull(),
        expiresAt: MoreThan(new Date()),
      },
    });
  }

  create(data: Partial<RecipeAccess>): Promise<RecipeAccess> {
    return this.accessRepository.save(this.accessRepository.create(data));
  }

  async update(id: string, data: Partial<RecipeAccess>): Promise<RecipeAccess> {
    const access = await this.findOne(id);
    Object.assign(access, data, { id: access.id });
    return this.accessRepository.save(access);
  }

  async remove(id: string): Promise<void> {
    const access = await this.findOne(id);
    await this.accessRepository.remove(access);
  }
}
