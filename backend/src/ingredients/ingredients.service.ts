import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Ingredient } from './entities/ingredient.entity';

@Injectable()
export class IngredientsService {
  constructor(
    @InjectRepository(Ingredient)
    private readonly ingredientRepository: Repository<Ingredient>,
  ) {}

  /**
   * คลังวัตถุดิบสำหรับเลือกตอนสร้างสูตร (เฉพาะที่เปิดใช้งาน)
   * [query] = พิมพ์ค้นหาบางส่วนของชื่อ แสดงไม่เกิน 30 รายการ
   */
  findAll(query?: string): Promise<Ingredient[]> {
    const search = query?.trim();
    const builder = this.ingredientRepository
      .createQueryBuilder('ingredient')
      .where('ingredient.isActive = true')
      .orderBy('ingredient.name', 'ASC');
    if (search) {
      builder
        .andWhere("ingredient.name ILIKE :search ESCAPE '\\'", {
          search: `%${search.replace(/[\\%_]/g, (char) => `\\${char}`)}%`,
        })
        .take(30);
    }
    return builder.getMany();
  }

  async findOne(id: string): Promise<Ingredient> {
    const ingredient = await this.ingredientRepository.findOne({
      where: { id },
    });
    if (!ingredient)
      throw new NotFoundException(`Ingredient with id ${id} not found`);
    return ingredient;
  }

  create(data: Partial<Ingredient>): Promise<Ingredient> {
    return this.ingredientRepository.save(
      this.ingredientRepository.create(data),
    );
  }

  async update(id: string, data: Partial<Ingredient>): Promise<Ingredient> {
    const ingredient = await this.findOne(id);
    Object.assign(ingredient, data, { id: ingredient.id });
    return this.ingredientRepository.save(ingredient);
  }

  async remove(id: string): Promise<void> {
    const ingredient = await this.findOne(id);
    await this.ingredientRepository.remove(ingredient);
  }
}
