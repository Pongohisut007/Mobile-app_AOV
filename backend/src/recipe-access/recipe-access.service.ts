import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, MoreThan, Repository } from 'typeorm';
import { RecipeAccess } from './entities/recipe-access.entity';

@Injectable()
export class RecipeAccessService {
  constructor(
    @InjectRepository(RecipeAccess)
    private readonly accessRepository: Repository<RecipeAccess>,
  ) {}

  findAll(): Promise<RecipeAccess[]> {
    return this.accessRepository.find({ order: { grantedAt: 'DESC' } });
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
