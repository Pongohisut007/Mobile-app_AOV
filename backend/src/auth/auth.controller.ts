import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ChangePasswordDto } from './dto/change-password.dto';
import { DeleteAccountDto } from './dto/delete-account.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { GoogleLoginDto } from './dto/google-login.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UserRole } from '../users/entities/user.entity';
import type { UserProfileResponse } from '../users/dto/user-profile-response.dto';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { CurrentUser } from './decorators/current-user.decorator';
import { Roles } from './decorators/roles.decorator';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { LocalAuthGuard } from './guards/local-auth.guard';
import { RolesGuard } from './guards/roles.guard';
import { PasswordResetService } from './password-reset.service';
import type {
  AuthResponse,
  AuthUser,
} from './interfaces/jwt-payload.interface';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
    private readonly passwordResetService: PasswordResetService,
  ) {}

  @Post('register')
  register(@Body() dto: RegisterDto): Promise<AuthResponse> {
    return this.authService.register(dto);
  }

  // LocalAuthGuard ตรวจ email/password ให้ก่อนเข้ามาถึง handler
  @UseGuards(LocalAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('login')
  login(@Body() dto: LoginDto): Promise<AuthResponse> {
    return this.authService.login(dto);
  }

  @HttpCode(HttpStatus.OK)
  @Post('google')
  loginWithGoogle(@Body() dto: GoogleLoginDto): Promise<AuthResponse> {
    return this.authService.loginWithGoogle(dto.idToken);
  }

  // ลืมรหัสผ่าน ขั้นที่ 1: ส่งรหัส 6 หลักทางอีเมล
  // ตอบ 204 เสมอ (ไม่บอกว่าอีเมลนี้มีบัญชีหรือไม่)
  @HttpCode(HttpStatus.NO_CONTENT)
  @Post('forgot-password')
  forgotPassword(@Body() dto: ForgotPasswordDto): Promise<void> {
    return this.passwordResetService.requestCode(dto.email, dto.language);
  }

  // ลืมรหัสผ่าน ขั้นที่ 2: รหัสถูก = ตั้งรหัสใหม่และได้ token กลับไปเข้าสู่ระบบเลย
  @HttpCode(HttpStatus.OK)
  @Post('reset-password')
  resetPassword(@Body() dto: ResetPasswordDto): Promise<AuthResponse> {
    return this.passwordResetService.resetPassword(
      dto.email,
      dto.code,
      dto.newPassword,
    );
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@CurrentUser() user: AuthUser): AuthUser {
    return user;
  }

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  profile(@CurrentUser() user: AuthUser): Promise<UserProfileResponse> {
    return this.usersService.findProfile(user.id);
  }

  // คืน token ใบใหม่ให้เครื่องนี้ใช้ต่อ (เครื่องอื่นหลุดเพราะ token_version เปลี่ยน)
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('change-password')
  changePassword(
    @CurrentUser() user: AuthUser,
    @Body() dto: ChangePasswordDto,
  ): Promise<AuthResponse> {
    return this.authService.changePassword(user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  @Post('logout-all')
  logoutAll(@CurrentUser() user: AuthUser): Promise<void> {
    return this.authService.logoutAll(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  @Post('delete-account')
  deleteAccount(
    @CurrentUser() user: AuthUser,
    @Body() dto: DeleteAccountDto,
  ): Promise<void> {
    return this.authService.deleteAccount(user.id, dto.password);
  }

  // แก้ได้เฉพาะโปรไฟล์ของคนที่ login อยู่ (id มาจาก token ไม่ใช่จาก URL)
  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  updateProfile(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateProfileDto,
  ): Promise<UserProfileResponse> {
    return this.usersService.updateOwnProfile(user.id, dto);
  }

  // ตัวอย่างการจำกัดสิทธิ์เฉพาะ creator
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CREATOR)
  @Get('creator-only')
  creatorOnly(@CurrentUser() user: AuthUser): { message: string } {
    return { message: `สวัสดี creator ${user.displayName}` };
  }
}
