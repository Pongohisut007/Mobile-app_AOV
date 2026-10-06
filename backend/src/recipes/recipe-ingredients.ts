import { BadRequestException, NotFoundException } from '@nestjs/common';
import { EntityManager, Repository } from 'typeorm';
import { Ingredient } from '../ingredients/entities/ingredient.entity';
import { RecipeIngredient } from '../ingredients/entities/recipe-ingredient.entity';
import type { RecipeIngredientInputDto } from './dto/create-recipe.dto';

/**
 * แทนรายการวัตถุดิบของสูตรทั้งชุดตามที่ส่งมา (ลำดับในรายการ = ลำดับที่แสดง)
 * - ส่ง ingredientId = เลือกจากคลัง
 * - ส่ง name = พิมพ์เอง: ชื่อตรงกับในคลัง (ไม่สนตัวพิมพ์/ช่องว่าง) ใช้ตัวเดิม ไม่มีก็เพิ่มเข้าคลัง
 * ใช้ใน transaction เดียวกับการบันทึกสูตร
 */
export async function replaceRecipeIngredients(
  manager: EntityManager,
  recipeId: string,
  inputs: RecipeIngredientInputDto[],
): Promise<void> {
  const ingredients = manager.getRepository(Ingredient);
  const links = manager.getRepository(RecipeIngredient);

  // เฉพาะคอลัมน์ ไม่มี relation (recipe/ingredient) ไม่งั้น type ของ insert() ไล่ลึกเข้าไปใน entity ที่ผูกกันแล้วไม่ผ่าน
  const rows: Pick<
    RecipeIngredient,
    | 'recipeId'
    | 'ingredientId'
    | 'amount'
    | 'unit'
    | 'preparationNote'
    | 'isOptional'
    | 'groupName'
    | 'sortOrder'
  >[] = [];
  const usedIds = new Set<string>();
  for (const [index, input] of inputs.entries()) {
    const ingredient = await resolveIngredient(ingredients, input);
    if (usedIds.has(ingredient.id)) {
      throw new BadRequestException(
        `Ingredient "${ingredient.name}" is listed more than once`,
      );
    }
    usedIds.add(ingredient.id);
    rows.push({
      recipeId,
      ingredientId: ingredient.id,
      amount: input.amount == null ? null : String(input.amount),
      unit: optionalText(input.unit),
      preparationNote: optionalText(input.note),
      isOptional: input.isOptional ?? false,
      groupName: 'main',
      sortOrder: index,
    });
  }

  await links.delete({ recipeId });
  if (rows.length > 0) await links.insert(rows);
}

async function resolveIngredient(
  ingredients: Repository<Ingredient>,
  input: RecipeIngredientInputDto,
): Promise<Ingredient> {
  if (input.ingredientId) {
    const found = await ingredients.findOne({
      where: { id: input.ingredientId },
    });
    if (!found) {
      throw new NotFoundException(
        `Ingredient with id ${input.ingredientId} not found`,
      );
    }
    return found;
  }

  const name = normalizeName(input.name ?? '');
  if (!name) throw new BadRequestException('Ingredient name is required');

  // "กระเทียม", " กระเทียม " และ "กระ  เทียม"(ช่องว่างซ้ำ) ถือเป็นตัวเดียวกัน
  const existing = await ingredients
    .createQueryBuilder('ingredient')
    .where(
      "lower(regexp_replace(trim(ingredient.name), '\\s+', ' ', 'g')) = lower(:name)",
      { name },
    )
    .getOne();
  if (existing) return existing;

  return ingredients.save(
    ingredients.create({ name, imageUrl: null, isActive: true }),
  );
}

/** ตัดช่องว่างหัวท้าย และยุบช่องว่างซ้ำให้เหลือช่องเดียว */
export function normalizeName(value: string): string {
  return value.trim().replace(/\s+/g, ' ');
}

function optionalText(value: string | null | undefined): string | null {
  const text = value?.trim();
  return text ? text : null;
}

/**
 * คนที่ยังไม่ได้ซื้อสูตร official เห็นแค่ชื่อวัตถุดิบ (ไว้ตัดสินใจซื้อ)
 * ปริมาณ หน่วย และหมายเหตุ เป็นส่วนของสูตรที่ขาย
 */
export function hideIngredientAmounts<
  T extends Pick<RecipeIngredient, 'amount' | 'unit' | 'preparationNote'>,
>(items: T[]): T[] {
  return items.map((item) => ({
    ...item,
    amount: null,
    unit: null,
    preparationNote: null,
  }));
}
