import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateRecipeDto, RECIPE_LIMITS } from './create-recipe.dto';
import { UpdateRecipeDto } from './update-recipe.dto';

describe('recipe DTO limits', () => {
  const valid = { title: 'Pad Thai', slug: 'pad-thai', price: '120.50' };
  // ตั้งค่าเดียวกับ ValidationPipe ใน main.ts
  const errors =
    (dto: typeof CreateRecipeDto | typeof UpdateRecipeDto) => (body: object) =>
      validate(plainToInstance(dto, body), {
        whitelist: true,
        forbidNonWhitelisted: true,
      });
  const create = errors(CreateRecipeDto);
  const update = errors(UpdateRecipeDto);

  it('accepts a normal recipe', async () => {
    expect(await create(valid)).toHaveLength(0);
    expect(await update({ price: '0.00', cookingMinutes: 30 })).toHaveLength(0);
  });

  it.each(['-5', '1.234', '1e5', '12345678901', 'abc'])(
    'rejects price %s',
    async (price) => {
      expect(await create({ ...valid, price })).not.toHaveLength(0);
      expect(await update({ price })).not.toHaveLength(0);
    },
  );

  it('rejects numbers too large for the integer columns', async () => {
    const huge = 3_000_000_000;
    for (const field of [
      'preparationMinutes',
      'cookingMinutes',
      'servingCount',
    ]) {
      expect(await create({ ...valid, [field]: huge })).not.toHaveLength(0);
      expect(await update({ [field]: huge })).not.toHaveLength(0);
    }
    const section = (extra: object) => ({
      ...valid,
      sections: [{ title: 'Step', ...extra }],
    });
    expect(await create(section({ sortOrder: huge }))).not.toHaveLength(0);
    expect(
      await create(
        section({ contents: [{ contentType: 'text', durationSeconds: huge }] }),
      ),
    ).not.toHaveLength(0);
  });

  it('caps array sizes and text lengths', async () => {
    const sections = Array.from({ length: RECIPE_LIMITS.sections + 1 }, () => ({
      title: 'Step',
    }));
    expect(await create({ ...valid, sections })).not.toHaveLength(0);
    expect(await update({ sections })).not.toHaveLength(0);

    const contents = Array.from(
      { length: RECIPE_LIMITS.contentsPerSection + 1 },
      () => ({ contentType: 'text' }),
    );
    expect(
      await create({ ...valid, sections: [{ title: 'Step', contents }] }),
    ).not.toHaveLength(0);

    const categoryIds = Array.from(
      { length: RECIPE_LIMITS.categories + 1 },
      () => '00000000-0000-4000-8000-000000000000',
    );
    expect(await create({ ...valid, categoryIds })).not.toHaveLength(0);

    const longText = 'a'.repeat(RECIPE_LIMITS.shortDescription + 1);
    expect(
      await create({ ...valid, shortDescription: longText }),
    ).not.toHaveLength(0);
  });
});
