import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { randomInt } from 'node:crypto';
import { Repository } from 'typeorm';
import { MailService } from '../mail/mail.service';
import { UserStatus } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { PasswordResetCode } from './entities/password-reset-code.entity';
import type { AuthResponse } from './interfaces/jwt-payload.interface';

/** รหัสใช้ได้กี่นาที */
export const RESET_CODE_TTL_MINUTES = 10;
/** กรอกผิดได้กี่ครั้งก่อนต้องขอรหัสใหม่ */
export const RESET_CODE_MAX_ATTEMPTS = 5;
/** ขอรหัสใหม่ได้อีกครั้งหลังกี่วินาที (แอปนับถอยหลังเท่านี้) */
export const RESET_CODE_RESEND_SECONDS = 60;

const INVALID_CODE = 'รหัสยืนยันไม่ถูกต้องหรือหมดอายุแล้ว';

/**
 * ลืมรหัสผ่าน
 * 1. requestCode: ส่งรหัส 6 หลักไปที่อีเมล
 * 2. resetPassword: รหัสถูก = ตั้งรหัสผ่านใหม่ + เข้าสู่ระบบให้เลย (เครื่องอื่นหลุดหมด)
 */
@Injectable()
export class PasswordResetService {
  constructor(
    @InjectRepository(PasswordResetCode)
    private readonly codes: Repository<PasswordResetCode>,
    private readonly usersService: UsersService,
    private readonly authService: AuthService,
    private readonly mailService: MailService,
    private readonly config: ConfigService,
  ) {}

  /**
   * ตอบเหมือนกันทุกกรณี (มี/ไม่มีบัญชี, เพิ่งขอไป) คนนอกจะเดาไม่ได้ว่าอีเมลไหนสมัครไว้
   * บัญชีที่สมัครผ่าน Google ก็ขอได้ = ได้ตั้งรหัสผ่านครั้งแรก
   */
  async requestCode(
    email: string,
    language: 'th' | 'en' = 'th',
  ): Promise<void> {
    const user = await this.usersService.findByEmail(email);
    if (!user || user.status !== UserStatus.ACTIVE) return;

    const existing = await this.codes.findOne({ where: { userId: user.id } });
    const now = Date.now();
    if (
      existing &&
      now - existing.sentAt.getTime() < RESET_CODE_RESEND_SECONDS * 1000
    ) {
      return;
    }

    const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
    await this.codes.save({
      ...existing,
      userId: user.id,
      codeHash: await bcrypt.hash(code, this.saltRounds()),
      expiresAt: new Date(now + RESET_CODE_TTL_MINUTES * 60 * 1000),
      attempts: 0,
      sentAt: new Date(now),
    });

    await this.mailService.send({
      to: user.email,
      ...PasswordResetService.email(code, language),
    });
  }

  async resetPassword(
    email: string,
    code: string,
    newPassword: string,
  ): Promise<AuthResponse> {
    const user = await this.usersService.findByEmail(email);
    const record = user
      ? await this.codes.findOne({ where: { userId: user.id } })
      : null;
    if (!user || !record || record.expiresAt.getTime() <= Date.now()) {
      throw new BadRequestException(INVALID_CODE);
    }
    if (record.attempts >= RESET_CODE_MAX_ATTEMPTS) {
      throw new BadRequestException(
        'กรอกรหัสผิดหลายครั้งเกินไป กรุณาขอรหัสใหม่',
      );
    }

    if (!(await bcrypt.compare(code, record.codeHash))) {
      await this.codes.increment({ id: record.id }, 'attempts', 1);
      throw new BadRequestException(INVALID_CODE);
    }
    if (user.status !== UserStatus.ACTIVE) {
      throw new BadRequestException('บัญชีนี้ถูกระงับการใช้งาน');
    }

    // ใช้รหัสได้ครั้งเดียว
    await this.codes.delete({ id: record.id });
    const updated = await this.usersService.updatePasswordHash(
      user.id,
      await bcrypt.hash(newPassword, this.saltRounds()),
    );
    return this.authService.issueToken(updated);
  }

  private saltRounds(): number {
    return this.config.get<number>('jwt.bcryptSaltRounds', 10);
  }

  static email(code: string, language: 'th' | 'en') {
    const minutes = RESET_CODE_TTL_MINUTES;
    const t =
      language === 'en'
        ? {
            subject: `Your Recipy password reset code: ${code}`,
            intro: 'Use this code to reset your Recipy password:',
            expiry: `The code expires in ${minutes} minutes.`,
            ignore:
              "If you didn't ask to reset your password, you can ignore this email.",
          }
        : {
            subject: `รหัสรีเซ็ตรหัสผ่าน Recipy: ${code}`,
            intro: 'ใช้รหัสนี้เพื่อตั้งรหัสผ่าน Recipy ใหม่:',
            expiry: `รหัสใช้ได้ภายใน ${minutes} นาที`,
            ignore:
              'ถ้าคุณไม่ได้ขอรีเซ็ตรหัสผ่าน ไม่ต้องทำอะไร ละเว้นอีเมลนี้ได้เลย',
          };

    return {
      subject: t.subject,
      text: `${t.intro}\n\n${code}\n\n${t.expiry}\n${t.ignore}`,
      html: `<div style="font-family:sans-serif;color:#303030">
<p>${t.intro}</p>
<p style="font-size:32px;font-weight:800;letter-spacing:8px;color:#D32F2F">${code}</p>
<p>${t.expiry}</p>
<p style="color:#8A8A8A;font-size:13px">${t.ignore}</p>
</div>`,
    };
  }
}
