/* eslint-disable @typescript-eslint/no-unsafe-return -- query builder is a chained Jest mock. */
import { BadRequestException, NotFoundException } from '@nestjs/common';
import type { EntityManager } from 'typeorm';
import { Ingredient } from '../ingredients/entities/ingredient.entity';
import {
  hideIngredientAmounts,
  normalizeName,
  replaceRecipeIngredients,
} from './recipe-ingredients';

function fakeManager(catalog: { id: string; name: string }[]) {
  const nameQuery = { lastName: '' };
  const ingredients = {
    findOne: jest.fn(({ where }: { where: { id: string } }) =>
      Promise.resolve(catalog.find((item) => item.id === where.id) ?? null),
    ),
    createQueryBuilder: jest.fn(() => {
      const builder = {
        where: jest.fn((_sql: string, params: { name: string }) => {
          nameQuery.lastName = params.name;
          return builder;
        }),
        getOne: jest.fn(() =>
          Promise.resolve(
            catalog.find(
              (item) =>
                normalizeName(item.name).toLowerCase() ===
                nameQuery.lastName.toLowerCase(),
            ) ?? null,
          ),
        ),
      };
      return builder;
    }),
    create: jest.fn((value: Partial<Ingredient>) => value),
    save: jest.fn((value: Partial<Ingredient>) => {
      const saved = { id: `new-${value.name}`, name: value.name! };
      catalog.push(saved);
      return Promise.resolve(saved);
    }),
  };
  const links = {
    delete: jest.fn().mockResolvedValue(undefined),
    insert: jest.fn().mockResolvedValue(undefined),
  };
  const manager = {
    getRepository: (entity: unknown) =>
      entity === Ingredient ? ingredients : links,
  } as unknown as EntityManager;
  return { manager, ingredients, links };
}

describe('replaceRecipeIngredients', () => {
  it('uses catalog items, reuses typed names and adds new ones', async () => {
    const { manager, ingredients, links } = fakeManager([
      { id: 'garlic', name: 'กระเทียม' },
      { id: 'basil', name: 'ใบกะเพรา' },
    ]);

    await replaceRecipeIngredients(manager, 'r1', [
      { ingredientId: 'garlic', amount: 5, unit: ' กลีบ ', note: 'สับ' },
      { name: '  ใบกะเพรา ', amount: 1.5, unit: 'ถ้วย' },
      { name: 'พริก  ขี้หนู', isOptional: true },
    ]);

    // พิมพ์ชื่อที่มีอยู่แล้ว ไม่สร้างซ้ำ สร้างเฉพาะตัวที่ยังไม่มี
    expect(ingredients.save).toHaveBeenCalledTimes(1);
    expect(ingredients.create).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'พริก ขี้หนู' }),
    );
    expect(links.delete).toHaveBeenCalledWith({ recipeId: 'r1' });
    expect(links.insert).toHaveBeenCalledWith([
      expect.objectContaining({
        ingredientId: 'garlic',
        amount: '5',
        unit: 'กลีบ',
        preparationNote: 'สับ',
        isOptional: false,
        sortOrder: 0,
      }),
      expect.objectContaining({
        ingredientId: 'basil',
        amount: '1.5',
        unit: 'ถ้วย',
        preparationNote: null,
        sortOrder: 1,
      }),
      expect.objectContaining({
        ingredientId: 'new-พริก ขี้หนู',
        amount: null,
        unit: null,
        isOptional: true,
        sortOrder: 2,
      }),
    ]);
  });

  it('clears the list when given nothing', async () => {
    const { manager, links } = fakeManager([]);
    await replaceRecipeIngredients(manager, 'r1', []);
    expect(links.delete).toHaveBeenCalledWith({ recipeId: 'r1' });
    expect(links.insert).not.toHaveBeenCalled();
  });

  it('rejects unknown ids, blank names and duplicates', async () => {
    const { manager, links } = fakeManager([
      { id: 'garlic', name: 'กระเทียม' },
    ]);

    await expect(
      replaceRecipeIngredients(manager, 'r1', [{ ingredientId: 'missing' }]),
    ).rejects.toBeInstanceOf(NotFoundException);
    await expect(
      replaceRecipeIngredients(manager, 'r1', [{ name: '   ' }]),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      replaceRecipeIngredients(manager, 'r1', [
        { ingredientId: 'garlic' },
        { name: 'กระเทียม' },
      ]),
    ).rejects.toThrow('more than once');
    expect(links.insert).not.toHaveBeenCalled();
  });
});

describe('ingredient helpers', () => {
  it('normalizes typed names', () => {
    expect(normalizeName('  น้ำปลา   แท้ ')).toBe('น้ำปลา แท้');
  });

  it('hides amounts but keeps names for people who have not bought', () => {
    const hidden = hideIngredientAmounts([
      {
        amount: '200.000',
        unit: 'กรัม',
        preparationNote: 'สับ',
        isOptional: true,
        ingredient: { name: 'หมูสับ' },
      },
    ]);
    expect(hidden).toEqual([
      {
        amount: null,
        unit: null,
        preparationNote: null,
        isOptional: true,
        ingredient: { name: 'หมูสับ' },
      },
    ]);
  });
});
