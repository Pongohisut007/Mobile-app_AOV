/* eslint-disable @typescript-eslint/no-unsafe-assignment -- repository manager is a Jest mock. */
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { QueryFailedError, Repository } from 'typeorm';
import { RecipeStatus, RecipeType } from '../recipes/entities/recipe.entity';
import { CartService } from './cart.service';
import { CartItem } from './entities/cart-item.entity';
import { Cart } from './entities/cart.entity';

function uniqueViolation() {
  return new QueryFailedError(
    'INSERT',
    [],
    Object.assign(new Error('duplicate'), { code: '23505' }),
  );
}

describe('CartService', () => {
  const cart = { id: 'c1', userId: 'u1' } as Cart;
  const item = { id: 'i1', cartId: 'c1', recipeId: 'r1' } as CartItem;
  let carts: Record<string, jest.Mock>;
  let items: Record<
    | 'find'
    | 'findOne'
    | 'findOneOrFail'
    | 'create'
    | 'save'
    | 'remove'
    | 'delete',
    jest.Mock
  > & { manager: { findOne: jest.Mock } };
  const forSale = {
    id: 'r1',
    status: RecipeStatus.PUBLISHED,
    type: RecipeType.OFFICIAL,
    creatorId: 'chef',
  };
  let service: CartService;

  beforeEach(() => {
    carts = {
      find: jest.fn().mockResolvedValue([cart]),
      findOne: jest.fn().mockResolvedValue(cart),
      findOneOrFail: jest.fn().mockResolvedValue(cart),
      create: jest.fn((value: Partial<Cart>) => value),
      save: jest.fn().mockResolvedValue(cart),
      remove: jest.fn(),
    };
    items = {
      find: jest.fn().mockResolvedValue([item]),
      findOne: jest.fn().mockResolvedValue(null),
      findOneOrFail: jest.fn().mockResolvedValue(item),
      create: jest.fn((value: Partial<CartItem>) => value),
      save: jest.fn().mockResolvedValue(item),
      remove: jest.fn(),
      delete: jest.fn(),
      manager: { findOne: jest.fn().mockResolvedValue(forSale) },
    };
    service = new CartService(
      carts as unknown as Repository<Cart>,
      items as unknown as Repository<CartItem>,
    );
  });

  it('lists the carts of a user', async () => {
    await expect(service.findAll('u1')).resolves.toEqual([cart]);
    expect(carts.find).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId: 'u1' } }),
    );
  });

  it("hides other people's carts", async () => {
    carts.findOne.mockResolvedValue(null);
    await expect(service.findOne('c1', 'other')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('reuses the existing cart', async () => {
    await expect(service.getOrCreate('u1')).resolves.toBe(cart);
    expect(carts.save).not.toHaveBeenCalled();
  });

  it('creates a cart the first time', async () => {
    carts.findOne.mockResolvedValueOnce(null);
    await expect(service.getOrCreate('u1')).resolves.toBe(cart);
    expect(carts.save).toHaveBeenCalledWith({ userId: 'u1' });
  });

  it('uses the cart created by a parallel request', async () => {
    carts.findOne.mockResolvedValueOnce(null);
    carts.save.mockRejectedValue(uniqueViolation());
    await expect(service.getOrCreate('u1')).resolves.toBe(cart);
    expect(carts.findOneOrFail).toHaveBeenCalled();
  });

  it('rethrows other errors while creating a cart', async () => {
    carts.findOne.mockResolvedValueOnce(null);
    carts.save.mockRejectedValue(new Error('db down'));
    await expect(service.getOrCreate('u1')).rejects.toThrow('db down');
  });

  it('lists items only after checking the owner', async () => {
    await expect(service.findItems('c1', 'u1')).resolves.toEqual([item]);
    carts.findOne.mockResolvedValue(null);
    await expect(service.findItems('c1', 'other')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('adds an item, or returns the one already in the cart', async () => {
    await expect(service.addItem('c1', 'u1', 'r1')).resolves.toBe(item);
    expect(items.save).toHaveBeenCalledWith({ cartId: 'c1', recipeId: 'r1' });

    items.findOne.mockResolvedValue(item);
    items.save.mockClear();
    await expect(service.addItem('c1', 'u1', 'r1')).resolves.toBe(item);
    expect(items.save).not.toHaveBeenCalled();
  });

  it('only adds official recipes that are on sale and not your own', async () => {
    items.manager.findOne.mockResolvedValueOnce(null);
    await expect(service.addItem('c1', 'u1', 'r1')).rejects.toBeInstanceOf(
      NotFoundException,
    );
    for (const recipe of [
      { ...forSale, status: RecipeStatus.DRAFT },
      { ...forSale, status: RecipeStatus.HIDDEN },
      { ...forSale, type: RecipeType.COMMUNITY },
      { ...forSale, creatorId: 'u1' },
    ]) {
      items.manager.findOne.mockResolvedValueOnce(recipe);
      await expect(service.addItem('c1', 'u1', 'r1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    }
    expect(items.save).not.toHaveBeenCalled();
  });

  it('handles adding the same recipe twice at once', async () => {
    items.save.mockRejectedValue(uniqueViolation());
    await expect(service.addItem('c1', 'u1', 'r1')).resolves.toBe(item);

    items.save.mockRejectedValue(new Error('db down'));
    await expect(service.addItem('c1', 'u1', 'r1')).rejects.toThrow('db down');
  });

  it('removes one item or clears the cart', async () => {
    items.findOne.mockResolvedValue(item);
    await service.removeItem('c1', 'u1', 'i1');
    expect(items.remove).toHaveBeenCalledWith(item);

    await service.clearItems('c1', 'u1');
    expect(items.delete).toHaveBeenCalledWith({ cartId: 'c1' });
  });

  it('reports a missing item', async () => {
    await expect(service.removeItem('c1', 'u1', 'nope')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('removes a cart that belongs to the user', async () => {
    await service.remove('c1', 'u1');
    expect(carts.remove).toHaveBeenCalledWith(cart);

    carts.findOne.mockResolvedValue(null);
    await expect(service.remove('c1', 'other')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
