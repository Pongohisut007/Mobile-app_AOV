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
import { AppCacheService } from '../cache/app-cache.service';
import { GoogleTokenVerifier } from './google-token-verifier';

// @nestjs/jwt เป็น ESM ที่ jest โหลดตรง ๆ ไม่ได้ เทสต์นี้ใช้ JwtService ปลอมอยู่แล้ว
jest.mock('@nestjs/jwt', () => ({ JwtService: class JwtService {} }));

describe('AuthService', () => {
  let passwordHash: string;
  let usersService: Record<string, jest.Mock>;
  let jwtService: { sign: jest.Mock; decode: jest.Mock };
  let googleVerifier: { verify: jest.Mock };
  let cache: { setFlag: jest.Mock; hasFlag: jest.Mock };
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
      hasPassword: jest.fn().mockResolvedValue(true),
      findByIdentity: jest.fn().mockResolvedValue(null),
      linkIdentity: jest.fn(),
      createWithIdentity: jest.fn((input: Partial<User>) =>
        Promise.resolve(user({ ...input, id: 'new-user' })),
      ),
    };
    googleVerifier = {
      verify: jest.fn().mockResolvedValue({
        sub: 'g-1',
        email: 'cook@example.com',
        emailVerified: true,
        name: 'Google Cook',
        picture: 'https://example.com/p.png',
      }),
    };
    jwtService = {
      sign: jest.fn().mockReturnValue('signed-token'),
      decode: jest.fn(),
    };
    cache = {
      setFlag: jest.fn().mockResolvedValue(undefined),
      hasFlag: jest.fn().mockResolvedValue(false),
    };
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
      googleVerifier as unknown as GoogleTokenVerifier,
      cache as unknown as AppCacheService,
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
      jti: expect.any(String),
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
  describe('Google sign-in', () => {
    it('signs in the user already linked to the Google account', async () => {
      usersService.findByIdentity.mockResolvedValue(user());

      const result = await service.loginWithGoogle('id-token');

      expect(googleVerifier.verify).toHaveBeenCalledWith('id-token');
      expect(usersService.linkIdentity).not.toHaveBeenCalled();
      expect(result.user.id).toBe('u1');
    });

    it('links Google to an existing account with the same verified email', async () => {
      usersService.findByEmail.mockResolvedValue(user());

      await service.loginWithGoogle('id-token');

      expect(usersService.linkIdentity).toHaveBeenCalledWith(
        'u1',
        'google',
        'g-1',
        'cook@example.com',
      );
      expect(usersService.createWithIdentity).not.toHaveBeenCalled();
    });

    it('refuses to link when Google has not verified the email', async () => {
      usersService.findByEmail.mockResolvedValue(user());
      googleVerifier.verify.mockResolvedValue({
        sub: 'g-1',
        email: 'cook@example.com',
        emailVerified: false,
        name: null,
        picture: null,
      });

      await expect(service.loginWithGoogle('id-token')).rejects.toBeInstanceOf(
        ConflictException,
      );
      expect(usersService.linkIdentity).not.toHaveBeenCalled();
    });

    it('creates a new account from the Google profile', async () => {
      const result = await service.loginWithGoogle('id-token');

      expect(usersService.createWithIdentity).toHaveBeenCalledWith(
        {
          email: 'cook@example.com',
          displayName: 'Google Cook',
          avatarUrl: 'https://example.com/p.png',
          role: UserRole.USER,
        },
        'google',
        'g-1',
      );
      expect(result.user.id).toBe('new-user');
    });

    it('uses the email name when Google has no display name', async () => {
      googleVerifier.verify.mockResolvedValue({
        sub: 'g-2',
        email: 'chef.mook@gmail.com',
        emailVerified: true,
        name: null,
        picture: null,
      });

      await service.loginWithGoogle('id-token');

      expect(usersService.createWithIdentity).toHaveBeenCalledWith(
        expect.objectContaining({ displayName: 'chef.mook' }),
        'google',
        'g-2',
      );
    });

    it('blocks disabled accounts', async () => {
      usersService.findByIdentity.mockResolvedValue(
        user({ status: UserStatus.DISABLED }),
      );
      await expect(service.loginWithGoogle('id-token')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });
  });

  describe('accounts without a password', () => {
    beforeEach(() => {
      usersService.hasPassword.mockResolvedValue(false);
      usersService.findByEmailWithPassword.mockResolvedValue(
        user({ passwordHash: null }),
      );
    });

    it('cannot sign in with a password', async () => {
      await expect(
        service.validateUser('cook@example.com', 'anything1'),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('can set a first password without the current one', async () => {
      await service.changePassword('u1', { newPassword: 'first-pass1' });
      expect(usersService.updatePasswordHash).toHaveBeenCalledWith(
        'u1',
        expect.any(String),
      );
    });

    it('can delete the account without a password', async () => {
      await service.deleteAccount('u1');
      expect(usersService.deleteOwnAccount).toHaveBeenCalled();
    });
  });

  it('revokes only this token until it would have expired', async () => {
    const decode = jwtService.decode;
    const now = Math.floor(Date.now() / 1000);
    decode.mockReturnValue({ sub: 'u1', jti: 'token-1', exp: now + 120 });

    await service.logout('signed-token');
    const [key, ttl] = cache.setFlag.mock.calls[0] as [string, number];
    expect(key).toBe('revoked-token:token-1');
    expect(ttl).toBeGreaterThan(115);
    expect(ttl).toBeLessThanOrEqual(120);

    cache.hasFlag.mockResolvedValueOnce(true);
    await expect(service.isRevoked('token-1')).resolves.toBe(true);
    await expect(service.isRevoked(undefined)).resolves.toBe(false);

    // token รุ่นเก่าที่ไม่มี jti ยกเลิกทีละใบไม่ได้ (ใช้ออกจากระบบทุกอุปกรณ์)
    cache.setFlag.mockClear();
    decode.mockReturnValue({ sub: 'u1', exp: now + 120 });
    await service.logout('old-token');
    expect(cache.setFlag).not.toHaveBeenCalled();
  });
});
