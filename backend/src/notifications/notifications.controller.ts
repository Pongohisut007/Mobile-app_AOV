import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  DEFAULT_PAGE_LIMIT,
  OptionalPaginationQueryDto,
  PaginatedResult,
} from '../common/pagination';
import { RateLimit } from '../common/throttle/rate-limits';
import {
  RegisterDeviceDto,
  UnregisterDeviceDto,
  UpdateNotificationSettingsDto,
} from './dto/notification.dto';
import {
  NotificationSettingsView,
  NotificationView,
  NotificationsService,
} from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  list(
    @CurrentUser('id') userId: string,
    @Query() query: OptionalPaginationQueryDto,
  ): Promise<PaginatedResult<NotificationView>> {
    return this.notificationsService.list(
      userId,
      query.page ?? 1,
      query.limit ?? DEFAULT_PAGE_LIMIT,
    );
  }

  @UseGuards(JwtAuthGuard)
  @Get('unread-count')
  unreadCount(@CurrentUser('id') userId: string): Promise<{ count: number }> {
    return this.notificationsService.unreadCount(userId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('read-all')
  @HttpCode(HttpStatus.NO_CONTENT)
  markAllRead(@CurrentUser('id') userId: string): Promise<void> {
    return this.notificationsService.markAllRead(userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('settings')
  getSettings(
    @CurrentUser('id') userId: string,
  ): Promise<NotificationSettingsView> {
    return this.notificationsService.getSettings(userId);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('settings')
  updateSettings(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateNotificationSettingsDto,
  ): Promise<NotificationSettingsView> {
    return this.notificationsService.updateSettings(userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('devices')
  @HttpCode(HttpStatus.NO_CONTENT)
  registerDevice(
    @CurrentUser('id') userId: string,
    @Body() dto: RegisterDeviceDto,
  ): Promise<void> {
    return this.notificationsService.registerDevice(userId, dto);
  }

  // ไม่บังคับ login: ตอนออกจากระบบ session อาจหมดอายุไปแล้ว
  @RateLimit('write')
  @Delete('devices')
  @HttpCode(HttpStatus.NO_CONTENT)
  unregisterDevice(@Body() dto: UnregisterDeviceDto): Promise<void> {
    return this.notificationsService.unregisterDevice(dto.token);
  }

  // :id ต้องอยู่หลัง route ชื่อคงที่ (settings/devices/read-all)
  @UseGuards(JwtAuthGuard)
  @Patch(':id/read')
  @HttpCode(HttpStatus.NO_CONTENT)
  markRead(
    @CurrentUser('id') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.notificationsService.markRead(userId, id);
  }
}
