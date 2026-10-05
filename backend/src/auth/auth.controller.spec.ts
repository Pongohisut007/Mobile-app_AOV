import { UserRole } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import type { AuthUser } from './interfaces/jwt-payload.interface';

// @nestjs/jwt เป็น ESM ที่ jest โหลดตรง ๆ ไม่ได้ (auth.service import อยู่)
jest.mock('@nestjs/jwt', () => ({ JwtService: class JwtService {} }));

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

describe('AuthController', () => {
  const me: AuthUser = {
    id: 'u1',
    email: 'cook@example.com',
    displayName: 'Cook',
    avatarUrl: null,
    role: UserRole.CREATOR,
  };
  const authService = {
    register: jest.fn().mockResolvedValue('registered'),
    login: jest.fn().mockResolvedValue('logged-in'),
    changePassword: jest.fn().mockResolvedValue('changed'),
    logoutAll: jest.fn().mockResolvedValue(undefined),
    deleteAccount: jest.fn().mockResolvedValue(undefined),
  };
  const usersService = {
    findProfile: jest.fn().mockResolvedValue('profile'),
    updateOwnProfile: jest.fn().mockResolvedValue('updated'),
  };
  const controller = new AuthController(
    authService as unknown as AuthService,
    usersService as unknown as UsersService,
  );

  it('forwards register and login', async () => {
    const register = {
      email: 'a@b.c',
      password: 'password1',
      displayName: 'A',
    };
    await expect(controller.register(register)).resolves.toBe('registered');
    await expect(
      controller.login({ email: 'a@b.c', password: 'password1' }),
    ).resolves.toBe('logged-in');
    expect(authService.register).toHaveBeenCalledWith(register);
  });

  it('returns the signed-in user and their profile', async () => {
    expect(controller.me(me)).toBe(me);
    await expect(controller.profile(me)).resolves.toBe('profile');
    expect(usersService.findProfile).toHaveBeenCalledWith('u1');
  });

  it('uses the id from the token for account actions', async () => {
    const passwords = {
      currentPassword: 'old-pass1',
      newPassword: 'new-pass1',
    };
    await expect(controller.changePassword(me, passwords)).resolves.toBe(
      'changed',
    );
    await controller.logoutAll(me);
    await controller.deleteAccount(me, { password: 'old-pass1' });
    await expect(
      controller.updateProfile(me, { displayName: 'Chef' }),
    ).resolves.toBe('updated');

    expect(authService.changePassword).toHaveBeenCalledWith('u1', passwords);
    expect(authService.logoutAll).toHaveBeenCalledWith('u1');
    expect(authService.deleteAccount).toHaveBeenCalledWith('u1', 'old-pass1');
    expect(usersService.updateOwnProfile).toHaveBeenCalledWith('u1', {
      displayName: 'Chef',
    });
  });

  it('greets creators on the creator-only route', () => {
    expect(controller.creatorOnly(me)).toEqual({
      message: 'สวัสดี creator Cook',
    });
  });
});
