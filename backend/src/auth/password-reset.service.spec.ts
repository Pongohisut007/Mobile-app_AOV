/* eslint-disable @typescript-eslint/no-unsafe-member-access -- service dependencies are Jest mocks. */
import {
  BadRequestException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import type { Repository } from 'typeorm';
import { MailService } from '../mail/mail.service';
import { User, UserStatus } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { PasswordResetCode } from './entities/password-reset-code.entity';
import {
  PasswordResetService,
  RESET_CODE_MAX_ATTEMPTS,
} from './password-reset.service';

// @nestjs/jwt เป็น ESM ที่ jest โหลดตรง ๆ ไม่ได้ (auth.service import อยู่)
jest.mock('@nestjs/jwt', () => ({ JwtService: class JwtService {} }));

describe('PasswordResetService', () => {
  const activeUser = {
    id: 'u1',
    email: 'cook@example.com',
    status: UserStatus.ACTIVE,
  } as User;

  let codes: Record<string, jest.Mock>;
  let usersService: Record<string, jest.Mock>;
  let authService: { issueToken: jest.Mock };
  let mailService: { send: jest.Mock; isConfigured: boolean };
  let appEnv: string;
  let service: PasswordResetService;

  const record = (overrides: Partial<PasswordResetCode> = {}) =>
    ({
      id: 'r1',
      userId: 'u1',
      codeHash: bcrypt.hashSync('123456', 4),
      expiresAt: new Date(Date.now() + 60_000),
      attempts: 0,
      sentAt: new Date(Date.now() - 5 * 60_000),
      ...overrides,
    }) as PasswordResetCode;

  beforeEach(() => {
    codes = {
      findOne: jest.fn().mockResolvedValue(null),
      save: jest.fn((value: Partial<PasswordResetCode>) =>
        Promise.resolve({ id: 'saved', ...value }),
      ),
      increment: jest.fn().mockResolvedValue(undefined),
      delete: jest.fn().mockResolvedValue(undefined),
    };
    usersService = {
      findByEmail: jest.fn().mockResolvedValue(activeUser),
      updatePasswordHash: jest.fn().mockResolvedValue(activeUser),
    };
    authService = { issueToken: jest.fn().mockReturnValue('token') };
    mailService = {
      send: jest.fn().mockResolvedValue(undefined),
      isConfigured: true,
    };
    appEnv = 'development';
    service = new PasswordResetService(
      codes as unknown as Repository<PasswordResetCode>,
      usersService as unknown as UsersService,
      authService as unknown as AuthService,
      mailService as unknown as MailService,
      {
        get: (key: string, fallback: unknown) =>
          key === 'app.env' ? appEnv : fallback === 10 ? 4 : fallback,
      } as unknown as ConfigService,
    );
  });

  describe('requestCode', () => {
    it('answers right away and issues the code in the background', async () => {
      const issue = jest
        .spyOn(service, 'issueCode')
        .mockResolvedValue(undefined);

      await expect(
        service.requestCode('cook@example.com', 'en'),
      ).resolves.toBeUndefined();
      expect(issue).toHaveBeenCalledWith('u1', 'cook@example.com', 'en');
    });

    it('answers the same way for unknown or disabled accounts', async () => {
      const issue = jest
        .spyOn(service, 'issueCode')
        .mockResolvedValue(undefined);
      usersService.findByEmail.mockResolvedValueOnce(null);
      await expect(
        service.requestCode('nobody@example.com'),
      ).resolves.toBeUndefined();
      usersService.findByEmail.mockResolvedValueOnce({
        ...activeUser,
        status: UserStatus.DISABLED,
      });
      await expect(
        service.requestCode('cook@example.com'),
      ).resolves.toBeUndefined();

      expect(issue).not.toHaveBeenCalled();
    });

    it('fails for everyone alike when production has no SMTP', async () => {
      appEnv = 'production';
      mailService.isConfigured = false;
      for (const email of ['cook@example.com', 'nobody@example.com']) {
        await expect(service.requestCode(email)).rejects.toBeInstanceOf(
          ServiceUnavailableException,
        );
      }
      // ไม่ได้ไปดูด้วยซ้ำว่าอีเมลนี้มีบัญชีไหม
      expect(usersService.findByEmail).not.toHaveBeenCalled();
    });
  });

  describe('issueCode', () => {
    it('saves a hashed 6-digit code and emails it', async () => {
      await service.issueCode('u1', 'cook@example.com', 'en');

      const saved = codes.save.mock.calls[0][0] as PasswordResetCode;
      const mail = mailService.send.mock.calls[0][0] as {
        to: string;
        text: string;
        subject: string;
      };
      const code = /\b(\d{6})\b/.exec(mail.text)?.[1] ?? '';
      expect(mail.to).toBe('cook@example.com');
      expect(mail.subject).toContain('password reset code');
      expect(saved.codeHash).not.toContain(code);
      await expect(bcrypt.compare(code, saved.codeHash)).resolves.toBe(true);
      expect(saved.attempts).toBe(0);
      expect(saved.expiresAt.getTime()).toBeGreaterThan(Date.now());
    });

    it('writes the email in Thai when asked', async () => {
      await service.issueCode('u1', 'cook@example.com', 'th');
      const mail = mailService.send.mock.calls[0][0] as { subject: string };
      expect(mail.subject).toContain('รหัสรีเซ็ตรหัสผ่าน');
    });

    it('ignores repeat requests within the resend cooldown', async () => {
      codes.findOne.mockResolvedValue(record({ sentAt: new Date() }));
      await service.issueCode('u1', 'cook@example.com', 'th');
      expect(mailService.send).not.toHaveBeenCalled();
    });

    it('replaces an older code after the cooldown', async () => {
      codes.findOne.mockResolvedValue(record({ attempts: 3 }));
      await service.issueCode('u1', 'cook@example.com', 'th');

      const saved = codes.save.mock.calls[0][0] as PasswordResetCode;
      expect(saved.id).toBe('r1');
      expect(saved.attempts).toBe(0);
      expect(mailService.send).toHaveBeenCalled();
    });

    it('removes the code when the email cannot be sent, so a retry works now', async () => {
      mailService.send.mockRejectedValue(new Error('smtp down'));

      await expect(
        service.issueCode('u1', 'cook@example.com', 'th'),
      ).resolves.toBeUndefined();
      expect(codes.delete).toHaveBeenCalledWith({ id: 'saved' });
    });

    it('never throws, even if saving fails', async () => {
      codes.save.mockRejectedValue(new Error('db down'));
      await expect(
        service.issueCode('u1', 'cook@example.com', 'th'),
      ).resolves.toBeUndefined();
      expect(mailService.send).not.toHaveBeenCalled();
      expect(codes.delete).not.toHaveBeenCalled();
    });
  });

  describe('resetPassword', () => {
    it('sets the new password, removes the code and signs in', async () => {
      codes.findOne.mockResolvedValue(record());

      await expect(
        service.resetPassword('cook@example.com', '123456', 'new-pass1'),
      ).resolves.toBe('token');

      expect(codes.delete).toHaveBeenCalledWith({ id: 'r1' });
      const [userId, hash] = usersService.updatePasswordHash.mock.calls[0] as [
        string,
        string,
      ];
      expect(userId).toBe('u1');
      await expect(bcrypt.compare('new-pass1', hash)).resolves.toBe(true);
    });

    it('counts a wrong code as an attempt', async () => {
      codes.findOne.mockResolvedValue(record());

      await expect(
        service.resetPassword('cook@example.com', '000000', 'new-pass1'),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(codes.increment).toHaveBeenCalledWith({ id: 'r1' }, 'attempts', 1);
      expect(usersService.updatePasswordHash).not.toHaveBeenCalled();
    });

    it('rejects missing, expired and used-up codes', async () => {
      const reset = () =>
        service.resetPassword('cook@example.com', '123456', 'new-pass1');

      await expect(reset()).rejects.toBeInstanceOf(BadRequestException);

      codes.findOne.mockResolvedValue(
        record({ expiresAt: new Date(Date.now() - 1) }),
      );
      await expect(reset()).rejects.toBeInstanceOf(BadRequestException);

      codes.findOne.mockResolvedValue(
        record({ attempts: RESET_CODE_MAX_ATTEMPTS }),
      );
      await expect(reset()).rejects.toThrow('กรอกรหัสผิดหลายครั้งเกินไป');

      usersService.findByEmail.mockResolvedValue(null);
      await expect(reset()).rejects.toBeInstanceOf(BadRequestException);

      expect(usersService.updatePasswordHash).not.toHaveBeenCalled();
    });

    it('rejects disabled accounts even with the right code', async () => {
      usersService.findByEmail.mockResolvedValue({
        ...activeUser,
        status: UserStatus.DISABLED,
      });
      codes.findOne.mockResolvedValue(record());

      await expect(
        service.resetPassword('cook@example.com', '123456', 'new-pass1'),
      ).rejects.toThrow('ถูกระงับ');
      expect(usersService.updatePasswordHash).not.toHaveBeenCalled();
    });
  });
});
