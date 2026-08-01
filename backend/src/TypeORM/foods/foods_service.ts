import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Food } from './foods_entity';

@Injectable()
export class FoodService {
  constructor(
    @InjectRepository(Food)
    private readonly foodRepository: Repository<Food>,
  ) {}

  async findAll(): Promise<Food[]> {
    return this.foodRepository.find();
  }

  async findOne(id: number): Promise<Food> {
    const food = await this.foodRepository.findOne({ where: { idfoods: id } });
    if (!food) {
      throw new NotFoundException(`Food with id ${id} not found`);
    }
    return food;
  }

  async create(data: Partial<Food>): Promise<Food> {
    const food = this.foodRepository.create(data);
    return this.foodRepository.save(food);
  }

  async update(id: number, data: Partial<Food>): Promise<Food> {
    const food = await this.findOne(id);
    Object.assign(food, data);
    return this.foodRepository.save(food);
  }

  async remove(id: number): Promise<void> {
    const result = await this.foodRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException(`Food with id ${id} not found`);
    }
  }
}