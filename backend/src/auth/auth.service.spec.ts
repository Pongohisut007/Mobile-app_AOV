/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access -- service dependencies are Jest mocks. */
import {
  BadRequestException,
  ConflictException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User, UserRole, UserStatus } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';

// @nestjs/jwt เป็น ESM ที่ jest โหลดตรง ๆ ไม่ได้ เทสต์นี้ใช้ JwtService ปลอมอยู่แล้ว
jest.mock('@nestjs/jwt', () => ({ JwtService: class JwtService {} }));

describe('AuthService', () => {
  let passwordHash: string;
  let usersService: Record<string, jest.Mock>;
  let jwtService: { sign: jest.Mock };
  let service: AuthService;

  const user = (overrides: Partial<User> = {}) =>
    ({
      id: 'u1',
      email: 'cook@example.com',
      displayName: 'Cook',
      avatarUrl: null,
      role: UserRole.USER,
      status: UserStatus.ACTIVE,
      tokenVersion: 2,
      passwordHash,
      ...overrides,
    }) as User;

  beforeAll(async () => {
    passwordHash = await bcrypt.hash('secret-pass', 4);
  });

  beforeEach(() => {
    usersService = {
      findByEmail: jest.fn().mockResolvedValue(null),
      create: jest.fn((input: Partial<User>) =>
        Promise.resolve(user({ ...input, passwordHash: input.passwordHash })),
      ),
      findByEmailWithPassword: jest.fn().mockResolvedValue(user()),
      findByIdWithPassword: jest.fn().mockResolvedValue(user()),
      updatePasswordHash: jest
        .fn()
        .mockResolvedValue(user({ tokenVersion: 3 })),
      bumpTokenVersion: jest.fn(),
      deleteOwnAccount: jest.fn(),
    };
    jwtService = { sign: jest.fn().mockReturnValue('signed-token') };
    // salt rounds ต่ำ ให้เทสต์เร็ว
    const config = {
      get: jest.fn((key: string, fallback?: unknown) =>
        key === 'jwt.bcryptSaltRounds' ? 4 : fallback,
      ),
    };
    service = new AuthService(
      usersService as unknown as UsersService,
      jwtService as unknown as JwtService,
      config as unknown as ConfigService,
    );
  });

  it('registers a new user and returns a token', async () => {
    const result = await service.register({
      email: 'cook@example.com',
      password: 'secret-pass',
      displayName: 'Cook',
    });

    const created = usersService.create.mock.calls[0][0] as {
      passwordHash: string;
      role: UserRole;
    };
    expect(created.role).toBe(UserRole.USER);
    await expect(
      bcrypt.compare('secret-pass', created.passwordHash),
    ).resolves.toBe(true);
    expect(result).toEqual({
      accessToken: 'signed-token',
      expiresIn: '7d',
      user: expect.objectContaining({ id: 'u1', avatarUrl: null }),
    });
  });

  it('refuses to register an email that is taken', async () => {
    usersService.findByEmail.mockResolvedValue(user());
    await expect(
      service.register({
        email: 'cook@example.com',
        password: 'secret-pass',
        displayName: 'Cook',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('logs in with the right password and signs the token version', async () => {
    await service.login({ email: 'cook@example.com', password: 'secret-pass' });
    expect(jwtService.sign).toHaveBeenCalledWith({
      sub: 'u1',
      email: 'cook@example.com',
      role: UserRole.USER,
      ver: 2,
    });
  });

  it.each([
    ['unknown email', () => null],
    [
      'wrong password',
      () => user({ passwordHash: '$2b$04$invalidinvalidinvalidinv' }),
    ],
    ['disabled account', () => user({ status: UserStatus.DISABLED })],
  ])('rejects login for %s', async (_, found) => {
    usersService.findByEmailWithPassword.mockResolvedValue(found());
    await expect(
      service.validateUser('cook@example.com', 'secret-pass'),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('changes the password and returns a fresh token', async () => {
    const result = await service.changePassword('u1', {
      currentPassword: 'secret-pass',
      newPassword: 'new-secret-pass',
    });

    expect(usersService.updatePasswordHash).toHaveBeenCalledWith(
      'u1',
      expect.any(String),
    );
    expect(jwtService.sign).toHaveBeenCalledWith(
      expect.objectContaining({ ver: 3 }),
    );
    expect(result.accessToken).toBe('signed-token');
  });

  it('rejects a wrong current password or an unchanged password', async () => {
    await expect(
      service.changePassword('u1', {
        currentPassword: 'wrong-pass',
        newPassword: 'new-secret-pass',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);

    await expect(
      service.changePassword('u1', {
        currentPassword: 'secret-pass',
        newPassword: 'secret-pass',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(usersService.updatePasswordHash).not.toHaveBeenCalled();
  });

  it('rejects password checks for a user that no longer exists', async () => {
    usersService.findByIdWithPassword.mockResolvedValue(null);
    await expect(
      service.deleteAccount('u1', 'secret-pass'),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('signs out of every device', async () => {
    await service.logoutAll('u1');
    expect(usersService.bumpTokenVersion).toHaveBeenCalledWith('u1');
  });

  it('deletes the account after confirming the password', async () => {
    await service.deleteAccount('u1', 'secret-pass');
    expect(usersService.deleteOwnAccount).toHaveBeenCalledWith(
      'u1',
      expect.any(String),
    );
  });

  it('defaults the token version to 0 for old users', () => {
    service.issueToken(user({ tokenVersion: undefined }));
    expect(jwtService.sign).toHaveBeenCalledWith(
      expect.objectContaining({ ver: 0 }),
    );
  });
});
