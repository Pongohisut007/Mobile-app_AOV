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
import { UsersService } from '../users/users.service';
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

    const matched = await bcrypt.compare(password, user.passwordHash);
    if (!matched)
      throw new UnauthorizedException('อีเมลหรือรหัสผ่านไม่ถูกต้อง');

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('บัญชีนี้ถูกระงับการใช้งาน');
    }
    return user;
  }

  /**
   * เปลี่ยนรหัสผ่านของตัวเอง ต้องยืนยันรหัสเดิมก่อน
   * เครื่องอื่นที่ login อยู่จะหลุดทันที เครื่องนี้ได้ token ใบใหม่กลับไปใช้ต่อ
   */
  async changePassword(
    userId: string,
    dto: ChangePasswordDto,
  ): Promise<AuthResponse> {
    await this.verifyPassword(userId, dto.currentPassword);
    if (dto.newPassword === dto.currentPassword) {
      throw new BadRequestException('รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม');
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
  async deleteAccount(userId: string, password: string): Promise<void> {
    await this.verifyPassword(userId, password);
    await this.usersService.deleteOwnAccount(
      userId,
      await bcrypt.hash(randomUUID(), this.saltRounds()),
    );
  }

  // ใช้ 400 ไม่ใช่ 401 แอปจะได้ไม่เข้าใจผิดว่า session หมดอายุแล้วพาไปหน้า login
  private async verifyPassword(userId: string, password: string) {
    const user = await this.usersService.findByIdWithPassword(userId);
    if (!user) throw new UnauthorizedException('ไม่พบผู้ใช้งาน');
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
