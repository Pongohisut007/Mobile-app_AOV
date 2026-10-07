import {
  IsBoolean,
  IsEnum,
  IsIn,
  IsOptional,
  IsString,
  Length,
} from 'class-validator';
import { DevicePlatform } from '../entities/device-token.entity';

export class RegisterDeviceDto {
  @IsString()
  @Length(10, 512)
  token!: string;

  @IsEnum(DevicePlatform)
  platform!: DevicePlatform;

  /** ภาษาของแอปในเครื่องนี้ (ภาษาที่แอปรองรับ) */
  @IsOptional()
  @IsIn(['th', 'en'])
  locale?: string;
}

export class UnregisterDeviceDto {
  @IsString()
  @Length(10, 512)
  token!: string;
}

export class UpdateNotificationSettingsDto {
  @IsOptional()
  @IsBoolean()
  pushEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  sales?: boolean;

  @IsOptional()
  @IsBoolean()
  moderation?: boolean;

  @IsOptional()
  @IsBoolean()
  reviews?: boolean;

  @IsOptional()
  @IsBoolean()
  comments?: boolean;
}
