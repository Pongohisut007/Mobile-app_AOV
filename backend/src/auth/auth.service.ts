import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { ChangePasswordDto } from './dto/change-password.dto';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'node:crypto';
import { User, UserRole, UserStatus } from '../users/entities/user.entity';
import { IdentityProvider } from '../users/entities/user-identity.entity';
import { UsersService } from '../users/users.service';
import { GoogleTokenVerifier } from './google-token-verifier';
import type { LoginDto } from './dto/login.dto';
import type { RegisterDto } from './dto/register.dto';
import type {
  AuthResponse,
  AuthUser,
  JwtPayload,
} from './interfaces/jwt-payload.interface';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly googleVerifier: GoogleTokenVerifier,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResponse> {
    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) throw new ConflictException('อีเมลนี้ถูกใช้งานแล้ว');

    const saltRounds = this.configService.get<number>(
      'jwt.bcryptSaltRounds',
      10,
    );
    const user = await this.usersService.create({
      email: dto.email,
      passwordHash: await bcrypt.hash(dto.password, saltRounds),
      displayName: dto.displayName,
      role: dto.role ?? UserRole.USER,
    });

    return this.issueToken(user);
  }

  /** ใช้โดย LocalStrategy — คืน user ถ้า email/password ถูกต้อง */
  async validateUser(email: string, password: string): Promise<User> {
    const user = await this.usersService.findByEmailWithPassword(email);
    if (!user) throw new UnauthorizedException('อีเมลหรือรหัสผ่านไม่ถูกต้อง');

    // สมัครผ่าน Google แล้วยังไม่ตั้งรหัสผ่าน: เข้าด้วยรหัสผ่านไม่ได้
    if (!user.passwordHash) {
      throw new UnauthorizedException(
        'บัญชีนี้เข้าสู่ระบบด้วย Google กรุณากดปุ่ม Google',
      );
    }
    const matched = await bcrypt.compare(password, user.passwordHash);
    if (!matched)
      throw new UnauthorizedException('อีเมลหรือรหัสผ่านไม่ถูกต้อง');

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('บัญชีนี้ถูกระงับการใช้งาน');
    }
    return user;
  }

  /**
   * เข้าสู่ระบบด้วย Google (แอปส่ง ID token จาก Google Sign-In มา)
   * 1. เคยผูกบัญชี Google นี้แล้ว = เข้าบัญชีนั้น
   * 2. อีเมลตรงกับบัญชีที่มีอยู่ (Google ยืนยันอีเมลแล้ว) = ผูกแล้วเข้าบัญชีเดิม
   * 3. ไม่เจอเลย = สมัครใหม่ (ไม่มีรหัสผ่าน ตั้งทีหลังได้)
   */
  async loginWithGoogle(idToken: string): Promise<AuthResponse> {
    const google = await this.googleVerifier.verify(idToken);

    let user = await this.usersService.findByIdentity(
      IdentityProvider.GOOGLE,
      google.sub,
    );

    if (!user) {
      const existing = await this.usersService.findByEmail(google.email);
      if (existing) {
        // อีเมลที่ Google ยังไม่ยืนยัน ห้ามใช้เข้าบัญชีคนอื่น
        if (!google.emailVerified) {
          throw new ConflictException(
            'อีเมลนี้มีบัญชีอยู่แล้ว กรุณาเข้าสู่ระบบด้วยรหัสผ่าน',
          );
        }
        await this.usersService.linkIdentity(
          existing.id,
          IdentityProvider.GOOGLE,
          google.sub,
          google.email,
        );
        user = existing;
      } else {
        user = await this.usersService.createWithIdentity(
          {
            email: google.email,
            displayName: (google.name ?? google.email.split('@')[0]).slice(
              0,
              150,
            ),
            avatarUrl: google.picture,
            role: UserRole.USER,
          },
          IdentityProvider.GOOGLE,
          google.sub,
        );
      }
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('บัญชีนี้ถูกระงับการใช้งาน');
    }
    return this.issueToken(user);
  }

  /**
   * เปลี่ยนรหัสผ่านของตัวเอง ต้องยืนยันรหัสเดิมก่อน
   * สมัครผ่าน Google แล้วยังไม่มีรหัสผ่าน = ตั้งรหัสผ่านได้เลยไม่ต้องกรอกรหัสเดิม
   * เครื่องอื่นที่ login อยู่จะหลุดทันที เครื่องนี้ได้ token ใบใหม่กลับไปใช้ต่อ
   */
  async changePassword(
    userId: string,
    dto: ChangePasswordDto,
  ): Promise<AuthResponse> {
    if (await this.usersService.hasPassword(userId)) {
      await this.verifyPassword(userId, dto.currentPassword ?? '');
      if (dto.newPassword === dto.currentPassword) {
        throw new BadRequestException('รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม');
      }
    }

    const user = await this.usersService.updatePasswordHash(
      userId,
      await bcrypt.hash(dto.newPassword, this.saltRounds()),
    );
    return this.issueToken(user);
  }

  /** ออกจากระบบทุกอุปกรณ์ (รวมเครื่องนี้) */
  async logoutAll(userId: string): Promise<void> {
    await this.usersService.bumpTokenVersion(userId);
  }

  /**
   * ลบบัญชีของตัวเอง (ต้องยืนยันรหัสผ่าน)
   * ปิดบัญชีและลบข้อมูลส่วนตัว ไม่ลบแถวจริง เพราะสูตรที่คนอื่นซื้อไปแล้วต้องเปิดดูได้ต่อ
   */
  async deleteAccount(userId: string, password?: string): Promise<void> {
    // ไม่มีรหัสผ่าน (สมัครผ่าน Google) แอปให้ติ๊กยืนยันแทน
    if (await this.usersService.hasPassword(userId)) {
      await this.verifyPassword(userId, password ?? '');
    }
    await this.usersService.deleteOwnAccount(
      userId,
      await bcrypt.hash(randomUUID(), this.saltRounds()),
    );
  }

  // ใช้ 400 ไม่ใช่ 401 แอปจะได้ไม่เข้าใจผิดว่า session หมดอายุแล้วพาไปหน้า login
  private async verifyPassword(userId: string, password: string) {
    const user = await this.usersService.findByIdWithPassword(userId);
    if (!user?.passwordHash) throw new UnauthorizedException('ไม่พบผู้ใช้งาน');
    const matched = await bcrypt.compare(password, user.passwordHash);
    if (!matched) throw new BadRequestException('รหัสผ่านปัจจุบันไม่ถูกต้อง');
  }

  private saltRounds(): number {
    return this.configService.get<number>('jwt.bcryptSaltRounds', 10);
  }

  async login(dto: LoginDto): Promise<AuthResponse> {
    const user = await this.validateUser(dto.email, dto.password);
    return this.issueToken(user);
  }

  issueToken(user: User): AuthResponse {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      ver: user.tokenVersion ?? 0,
    };

    return {
      accessToken: this.jwtService.sign(payload),
      expiresIn: this.configService.get<string>('jwt.expiresIn', '7d'),
      user: AuthService.toAuthUser(user),
    };
  }

  static toAuthUser(user: User): AuthUser {
    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl ?? null,
      role: user.role,
    };
  }
}
