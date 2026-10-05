import { ForbiddenException } from '@nestjs/common';
import type { AuthUser } from '../auth/interfaces/jwt-payload.interface';
import { UserRole } from '../users/entities/user.entity';
import { RecipeStatus, RecipeType } from './entities/recipe.entity';

/** สถานะที่เจ้าของสูตรตั้งเองได้ ที่เหลือ (hidden/rejected) เป็นของ admin */
const OWNER_STATUSES: readonly RecipeStatus[] = [
  RecipeStatus.DRAFT,
  RecipeStatus.PUBLISHED,
];

/**
 * รายการ/ค้นหาสูตร: คนทั่วไปเห็นเฉพาะที่เผยแพร่แล้ว
 * สูตรสถานะอื่น (draft ฯลฯ) ดูได้เฉพาะของตัวเอง (creatorId ตรงกับคนที่ login)
 */
export function visibleRecipeFilters<
  T extends { creatorId?: string; status?: RecipeStatus },
>(filters: T, viewerId?: string): T {
  if (filters.status === RecipeStatus.PUBLISHED) return filters;
  if (viewerId && filters.creatorId === viewerId) return filters;
  if (filters.status === undefined) {
    return { ...filters, status: RecipeStatus.PUBLISHED };
  }
  throw new ForbiddenException(
    'ดูได้เฉพาะสูตรที่เผยแพร่แล้ว หรือสูตรของตัวเอง',
  );
}

/**
 * ค่าที่ส่งมาตอนสร้าง/แก้สูตร
 * - สูตร official (ขายได้) ต้องเป็น creator
 * - ซ่อน/ปฏิเสธสูตร เป็นงานของ admin
 */
export function assertRecipeFieldsAllowed(
  dto: { type?: RecipeType; status?: RecipeStatus },
  user: Pick<AuthUser, 'role'>,
  { changingType }: { changingType: boolean },
): void {
  if (user.role === UserRole.ADMIN) return;
  const needsCreator = changingType
    ? dto.type !== undefined
    : dto.type === RecipeType.OFFICIAL;
  if (needsCreator && user.role !== UserRole.CREATOR) {
    throw new ForbiddenException('Only creators can change recipe type');
  }
  if (dto.status !== undefined && !OWNER_STATUSES.includes(dto.status)) {
    throw new ForbiddenException('Only admins can hide or reject recipes');
  }
}

/** แก้/ลบสูตรได้เฉพาะเจ้าของ (หรือ admin) */
export function assertCanManageRecipe(
  recipe: { creatorId: string },
  user: Pick<AuthUser, 'id' | 'role'>,
): void {
  if (user.role === UserRole.ADMIN) return;
  if (recipe.creatorId !== user.id) {
    throw new ForbiddenException('You can only change your own recipes');
  }
}
