import { FavoritesController } from '../favorites/favorites.controller';
import { FavoritesService } from '../favorites/favorites.service';
import { CartController } from './cart.controller';
import { CartService } from './cart.service';

// เหมือน api-contract.spec: ไม่ต้องโหลด Passport (ESM) จริงในเทสต์
jest.mock('@nestjs/passport', () => ({
  AuthGuard: () =>
    class {
      canActivate() {
        return true;
      }
    },
  PassportStrategy: () =>
    class {
      constructor(readonly options?: unknown) {}
    },
}));

describe('CartController', () => {
  const cartService = {
    findAll: jest.fn().mockResolvedValue('all'),
    getOrCreate: jest.fn().mockResolvedValue('cart'),
    findOne: jest.fn().mockResolvedValue('one'),
    remove: jest.fn().mockResolvedValue(undefined),
    findItems: jest.fn().mockResolvedValue('items'),
    addItem: jest.fn().mockResolvedValue('item'),
    clearItems: jest.fn().mockResolvedValue(undefined),
    removeItem: jest.fn().mockResolvedValue(undefined),
  };
  const controller = new CartController(cartService as unknown as CartService);

  it('always passes the signed-in user id to the service', async () => {
    await expect(controller.findAll('u1')).resolves.toBe('all');
    await expect(controller.create('u1')).resolves.toBe('cart');
    await expect(controller.findOne('u1', 'c1')).resolves.toBe('one');
    await controller.remove('u1', 'c1');
    await expect(controller.findItems('u1', 'c1')).resolves.toBe('items');
    await expect(
      controller.addItem('u1', 'c1', { recipeId: 'r1' }),
    ).resolves.toBe('item');
    await controller.clearItems('u1', 'c1');
    await controller.removeItem('u1', 'c1', 'i1');

    expect(cartService.findOne).toHaveBeenCalledWith('c1', 'u1');
    expect(cartService.remove).toHaveBeenCalledWith('c1', 'u1');
    expect(cartService.addItem).toHaveBeenCalledWith('c1', 'u1', 'r1');
    expect(cartService.clearItems).toHaveBeenCalledWith('c1', 'u1');
    expect(cartService.removeItem).toHaveBeenCalledWith('c1', 'u1', 'i1');
  });
});

describe('FavoritesController', () => {
  const favoritesService = {
    findAll: jest.fn().mockResolvedValue('all'),
    findPage: jest.fn().mockResolvedValue('page'),
    removeByRecipe: jest.fn().mockResolvedValue(undefined),
    findOne: jest.fn().mockResolvedValue('one'),
    create: jest.fn().mockResolvedValue('created'),
    remove: jest.fn().mockResolvedValue(undefined),
  };
  const controller = new FavoritesController(
    favoritesService as unknown as FavoritesService,
  );

  it('returns everything without a page, or one page with it', async () => {
    await expect(controller.findAll('u1', {})).resolves.toBe('all');
    await expect(controller.findAll('u1', { page: 2 })).resolves.toBe('page');
    await controller.findAll('u1', { page: 1, limit: 5 });

    expect(favoritesService.findPage).toHaveBeenCalledWith('u1', 2, 20);
    expect(favoritesService.findPage).toHaveBeenCalledWith('u1', 1, 5);
  });

  it('creates, reads and removes favorites of the signed-in user', async () => {
    await expect(controller.create('u1', { recipeId: 'r1' })).resolves.toBe(
      'created',
    );
    await expect(controller.findOne('u1', 'f1')).resolves.toBe('one');
    await controller.remove('u1', 'f1');
    await controller.removeByRecipe('u1', { recipeId: 'r1' });

    expect(favoritesService.create).toHaveBeenCalledWith('u1', 'r1');
    expect(favoritesService.remove).toHaveBeenCalledWith('f1', 'u1');
    expect(favoritesService.removeByRecipe).toHaveBeenCalledWith('u1', 'r1');
  });
});
