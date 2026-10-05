import { applyDecorators, UseGuards } from '@nestjs/common';
import { UserRole } from '../../users/entities/user.entity';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from './roles.decorator';

/** ต้อง login และเป็น admin (ใช้กับ endpoint จัดการข้อมูลหลังบ้าน) */
export const AdminOnly = () =>
  applyDecorators(UseGuards(JwtAuthGuard, RolesGuard), Roles(UserRole.ADMIN));
