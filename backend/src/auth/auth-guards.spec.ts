import {
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { User, UserRole, UserStatus } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { RolesGuard } from './guards/roles.guard';
import { AuthService } from './auth.service';
import { JwtStrategy } from './strategies/jwt.strategy';

// @nestjs/jwt เป็น ESM ที่ jest โหลดตรง ๆ ไม่ได้ (jwt.strategy -> auth.service import อยู่)
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

function contextWithUser(user: unknown): ExecutionContext {
  return {
    getHandler: () => undefined,
    getClass: () => undefined,
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
  } as unknown as ExecutionContext;
}

describe('RolesGuard', () => {
  const reflector = { getAllAndOverride: jest.fn() };
  const guard = new RolesGuard(reflector as unknown as Reflector);

  it('lets everyone through when no role is required', () => {
    reflector.getAllAndOverride.mockReturnValue(undefined);
    expect(guard.canActivate(contextWithUser(undefined))).toBe(true);
    reflector.getAllAndOverride.mockReturnValue([]);
    expect(guard.canActivate(contextWithUser(undefined))).toBe(true);
  });

  it('allows users with a required role', () => {
    reflector.getAllAndOverride.mockReturnValue([UserRole.CREATOR]);
    expect(guard.canActivate(contextWithUser({ role: UserRole.CREATOR }))).toBe(
      true,
    );
  });

  it('blocks missing users and other roles', () => {
    reflector.getAllAndOverride.mockReturnValue([UserRole.CREATOR]);
    expect(() => guard.canActivate(contextWithUser(undefined))).toThrow(
      ForbiddenException,
    );
    expect(() =>
      guard.canActivate(contextWithUser({ role: UserRole.USER })),
    ).toThrow(ForbiddenException);
  });
});

describe('JwtStrategy', () => {
  const usersService = { findById: jest.fn() };
  const authService = { isRevoked: jest.fn().mockResolvedValue(false) };
  const config = { getOrThrow: jest.fn().mockReturnValue('test-secret') };
  const strategy = new JwtStrategy(
    config as unknown as ConfigService,
    usersService as unknown as UsersService,
    authService as unknown as AuthService,
  );
  const activeUser = {
    id: 'u1',
    email: 'cook@example.com',
    displayName: 'Cook',
    avatarUrl: null,
    role: UserRole.USER,
    status: UserStatus.ACTIVE,
    tokenVersion: 1,
  } as User;
  const payload = { sub: 'u1', email: 'cook@example.com', role: UserRole.USER };

  it('returns the user for a valid token', async () => {
    usersService.findById.mockResolvedValue(activeUser);
    await expect(strategy.validate({ ...payload, ver: 1 })).resolves.toEqual(
      expect.objectContaining({ id: 'u1', role: UserRole.USER }),
    );
  });

  it('rejects missing or disabled users', async () => {
    usersService.findById.mockResolvedValue(null);
    await expect(
      strategy.validate({ ...payload, ver: 1 }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    usersService.findById.mockResolvedValue({
      ...activeUser,
      status: UserStatus.DISABLED,
    });
    await expect(
      strategy.validate({ ...payload, ver: 1 }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('rejects a token that signed out on this device', async () => {
    usersService.findById.mockResolvedValue(activeUser);
    authService.isRevoked.mockResolvedValueOnce(true);
    await expect(
      strategy.validate({ ...payload, ver: 1, jti: 'token-1' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(authService.isRevoked).toHaveBeenCalledWith('token-1');
  });

  it('rejects tokens issued before signing out everywhere', async () => {
    usersService.findById.mockResolvedValue(activeUser);
    // token เก่าไม่มี ver ถือเป็น 0
    await expect(strategy.validate(payload)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
