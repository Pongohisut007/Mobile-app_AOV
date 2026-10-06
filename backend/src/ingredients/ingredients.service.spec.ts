import type { Repository } from 'typeorm';
import { Ingredient } from './entities/ingredient.entity';
import { IngredientsService } from './ingredients.service';

describe('IngredientsService.findAll', () => {
  const builder = () => {
    const query = {
      where: jest.fn(),
      orderBy: jest.fn(),
      andWhere: jest.fn(),
      take: jest.fn(),
      getMany: jest.fn().mockResolvedValue([]),
    };
    for (const method of ['where', 'orderBy', 'andWhere', 'take'] as const) {
      query[method].mockReturnValue(query);
    }
    return query;
  };

  it('lists only active ingredients, searching by part of the name', async () => {
    const query = builder();
    const service = new IngredientsService({
      createQueryBuilder: () => query,
    } as unknown as Repository<Ingredient>);

    await service.findAll();
    expect(query.where).toHaveBeenCalledWith('ingredient.isActive = true');
    expect(query.andWhere).not.toHaveBeenCalled();

    await service.findAll('  10%_ไก่ ');
    expect(query.andWhere).toHaveBeenCalledWith(
      "ingredient.name ILIKE :search ESCAPE '\\'",
      { search: '%10\\%\\_ไก่%' },
    );
    expect(query.take).toHaveBeenCalledWith(30);
  });
});
