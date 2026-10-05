import { RecipeAccessController } from './recipe-access.controller';
import { RecipeAccessService } from './recipe-access.service';

// เหมือน api-contract.spec: ไม่ต้องโหลด Passport (ESM) จริงในเทสต์
jest.mock('@nestjs/passport', () => ({
  AuthGuard: () =>
    class {
      canActivate() {
        return true;
      }
    },
}));

describe('RecipeAccessController', () => {
  const service = {
    findPurchasedByUser: jest.fn().mockResolvedValue('all'),
    findPurchasedPageByUser: jest.fn().mockResolvedValue('page'),
    findPurchasedRecipeIds: jest.fn().mockResolvedValue(['r1']),
    hasActiveAccess: jest.fn().mockResolvedValue(true),
  };
  const controller = new RecipeAccessController(
    service as unknown as RecipeAccessService,
  );

  it('always uses the signed-in user', async () => {
    await expect(controller.findPurchased('u1', {})).resolves.toBe('all');
    expect(service.findPurchasedByUser).toHaveBeenCalledWith('u1');

    await expect(
      controller.findPurchased('u1', { page: 2, limit: 5 }),
    ).resolves.toBe('page');
    expect(service.findPurchasedPageByUser).toHaveBeenCalledWith('u1', 2, 5);

    await expect(controller.findPurchasedRecipeIds('u1')).resolves.toEqual([
      'r1',
    ]);
    await expect(controller.hasActiveAccess('u1', 'r1')).resolves.toBe(true);
    expect(service.hasActiveAccess).toHaveBeenCalledWith('u1', 'r1');
  });
});
