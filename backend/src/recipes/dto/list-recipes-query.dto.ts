import { IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { OptionalPaginationQueryDto } from '../../common/pagination';
import { RecipeStatus, RecipeType } from '../entities/recipe.entity';

export enum RecipeSort {
  // เผยแพร่ล่าสุดก่อน (ค่าเดิม)
  LATEST = 'latest',
  // คะแนนรีวิวเฉลี่ยแบบถ่วงจำนวนรีวิว สูตรที่ยังไม่มีรีวิวไปท้ายสุด
  RATING = 'rating',
}

// GET /recipes: ตัวกรอง + แบ่งหน้าแบบไม่บังคับ
export class ListRecipesQueryDto extends OptionalPaginationQueryDto {
  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsOptional()
  @IsUUID()
  creatorId?: string;

  @IsOptional()
  @IsEnum(RecipeStatus)
  status?: RecipeStatus;

  @IsOptional()
  @IsEnum(RecipeType)
  type?: RecipeType;

  // ใช้เฉพาะตอนแบ่งหน้า (ส่ง page มา)
  @IsOptional()
  @IsEnum(RecipeSort)
  sort?: RecipeSort;
}
