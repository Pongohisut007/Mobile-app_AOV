import { Module } from '@nestjs/common';
import { MediaSigner } from './media-signer.service';
import { ProtectedMediaService } from './protected-media.service';
import { UploadsController } from './uploads.controller';
import { R2Provider } from './storage/r2.provider';
import { UploadsService } from './uploads.service';

@Module({
  controllers: [UploadsController],
  providers: [R2Provider, UploadsService, MediaSigner, ProtectedMediaService],
  // RecipesService ใช้แนบลายเซ็นให้ลิงก์ไฟล์ของขั้นตอนที่ซื้อแล้ว
  exports: [MediaSigner],
})
export class UploadsModule {}
