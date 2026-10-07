import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { IapController } from './iap.controller';
import { IapService } from './iap.service';

@Module({
  imports: [NotificationsModule],
  controllers: [IapController],
  providers: [IapService],
})
export class IapModule {}
