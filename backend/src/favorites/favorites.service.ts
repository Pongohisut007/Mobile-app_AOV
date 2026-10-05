import { Injectable, NotFoundException, Optional } from '@nestjs/common';
import { CacheNamespace } from '../cache/app-cache.module';
import { AppCacheService } from '../cache/app-cache.service';
import { InjectRepository } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';
import { PaginatedResult, toPaginated } from '../common/pagination';
import { Recipe } from '../recipes/entities/recipe.entity';
import { canFavorite } from '../recipes/recipe-permissions';
import { Favorite } from './entities/favorite.entity';

// รหัส error ของ postgres ตอนชน unique constraint
const UNIQUE_VIOLATION = '23505';

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof QueryFailedError &&
    (error.driverError as { code?: string })?.code === UNIQUE_VIOLATION
  );
}

@Injectable()
export class FavoritesService {
  constructor(
    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,
    @Optional()
    private readonly cache?: AppCacheService,
  ) {}

  // ยอดหัวใจอยู่ในข้อมูลสูตรที่ cache ไว้ กด/เลิกกดหัวใจต้องล้าง
  private async invalidateRecipeCounts(): Promise<void> {
    await this.cache?.invalidate(CacheNamespace.recipes);
  }

  findAll(userId: string): Promise<Favorite[]> {
    return this.favoriteRepository.find({
      where: { userId },
      relations: { recipe: { creator: true, categories: true } },
      order: { createdAt: 'DESC' },
    });
  }

  async findPage(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<Favorite>> {
    // relation แบบ many-to-many ทำให้ take/skip นับแถวผิด จึงใช้ find แบบมี order + id
    // (typeorm แยก query หา id ให้เองเมื่อมี relation)
    const [data, total] = await this.favoriteRepository.findAndCount({
      where: { userId },
      relations: { recipe: { creator: true, categories: true } },
      order: { createdAt: 'DESC', id: 'ASC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return toPaginated(data, total, page, limit);
  }

  // รายการโปรดของคนอื่นให้ถือว่าไม่มีอยู่
  async findOne(id: string, userId: string): Promise<Favorite> {
    const favorite = await this.favoriteRepository.findOne({
      where: { id, userId },
      relations: { recipe: true },
    });
    if (!favorite)
      throw new NotFoundException(`Favorite with id ${id} not found`);
    return favorite;
  }

  // กดหัวใจสูตรเดิมซ้ำไม่ควรพัง คืนแถวเดิมกลับไปแทนการสร้างซ้ำ
  async create(userId: string, recipeId: string): Promise<Favorite> {
    // draft/สูตรที่ถูกซ่อนของคนอื่น ตอบเหมือนไม่มีสูตรนี้
    const recipe = await this.favoriteRepository.manager.findOne(Recipe, {
      where: { id: recipeId },
      select: { id: true, status: true, creatorId: true },
    });
    if (!recipe || !canFavorite(recipe, userId)) {
      throw new NotFoundException(`Recipe ${recipeId} not found`);
    }

    const existing = await this.favoriteRepository.findOne({
      where: { userId, recipeId },
    });
    if (existing) return existing;

    try {
      const saved = await this.favoriteRepository.save(
        this.favoriteRepository.create({ userId, recipeId }),
      );
      await this.invalidateRecipeCounts();
      return saved;
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;
      return this.favoriteRepository.findOneOrFail({
        where: { userId, recipeId },
      });
    }
  }

  async remove(id: string, userId: string): Promise<void> {
    const favorite = await this.findOne(id, userId);
    await this.favoriteRepository.remove(favorite);
    await this.invalidateRecipeCounts();
  }

  // ฝั่งแอปรู้แค่ว่ากดหัวใจสูตรไหน ไม่รู้ favoriteId จึงลบด้วยคู่ user + recipe ได้ตรง ๆ
  async removeByRecipe(userId: string, recipeId: string): Promise<void> {
    const favorite = await this.favoriteRepository.findOne({
      where: { userId, recipeId },
    });
    if (!favorite) {
      throw new NotFoundException(
        `Favorite for recipe ${recipeId} not found for user ${userId}`,
      );
    }
    await this.favoriteRepository.remove(favorite);
    await this.invalidateRecipeCounts();
  }
}
