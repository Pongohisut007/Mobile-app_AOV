import { Category } from '../../categories/entities/category.entity';
import { Recipe } from './recipe.entity';

describe('Recipe JSON', () => {
  it('leaves out disabled categories but keeps everything else', () => {
    const recipe = Object.assign(new Recipe(), {
      id: 'r1',
      title: 'Soup',
      categories: [
        Object.assign(new Category(), {
          id: 'a',
          name: 'Thai',
          isActive: true,
        }),
        Object.assign(new Category(), {
          id: 'b',
          name: 'Old',
          isActive: false,
        }),
      ],
    });

    const json = JSON.parse(JSON.stringify(recipe)) as {
      id: string;
      title: string;
      categories: { id: string }[];
    };

    expect(json.id).toBe('r1');
    expect(json.title).toBe('Soup');
    expect(json.categories.map((category) => category.id)).toEqual(['a']);
    // ในหน่วยความจำยังอยู่ครบ (บันทึกลงฐานข้อมูลไม่หาย)
    expect(recipe.categories).toHaveLength(2);
  });

  it('works without loaded categories', () => {
    const json = JSON.parse(
      JSON.stringify(Object.assign(new Recipe(), { id: 'r1' })),
    ) as Record<string, unknown>;
    expect(json).toEqual({ id: 'r1' });
  });
});
