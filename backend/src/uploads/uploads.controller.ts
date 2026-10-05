import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Headers,
  Param,
  ParseEnumPipe,
  Post,
  Query,
  Res,
  StreamableFile,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { SkipThrottle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RateLimit } from '../common/throttle/rate-limits';
import { CompleteUploadDto } from './dto/complete-upload.dto';
import { PresignUploadDto } from './dto/presign-upload.dto';
import type { Response } from 'express';
import { MediaSigner } from './media-signer.service';
import { ProtectedMediaService } from './protected-media.service';
import {
  type UploadResult,
  type PresignedUploadResult,
  UploadKind,
  type UploadedFileData,
  UploadsService,
} from './uploads.service';

@Controller('uploads')
export class UploadsController {
  constructor(
    private readonly uploadsService: UploadsService,
    private readonly mediaSigner: MediaSigner,
    private readonly protectedMedia: ProtectedMediaService,
  ) {}

  @RateLimit('upload')
  @Post('presign')
  @UseGuards(JwtAuthGuard)
  presign(@Body() dto: PresignUploadDto): Promise<PresignedUploadResult> {
    return this.uploadsService.presign(dto.kind, dto.mimeType, dto.size);
  }

  @RateLimit('upload')
  @Post('complete')
  @UseGuards(JwtAuthGuard)
  complete(@Body() dto: CompleteUploadDto): Promise<UploadResult> {
    return this.uploadsService.complete(dto.kind, dto.filename);
  }

  @RateLimit('upload')
  @Post('images')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }),
  )
  uploadImage(@UploadedFile() file?: UploadedFileData): Promise<UploadResult> {
    return this.uploadsService.saveImage(file);
  }

  @RateLimit('upload')
  @Post('videos')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: 100 * 1024 * 1024 } }),
  )
  uploadVideo(@UploadedFile() file?: UploadedFileData): Promise<UploadResult> {
    return this.uploadsService.saveVideo(file);
  }

  // รูป/วิดีโอโหลดทีละหลายไฟล์ตอนเลื่อนหน้า (แอป cache ไว้แล้ว) ไม่นับรวมเพดาน
  @SkipThrottle()
  @Get(':kind/:filename')
  async open(
    @Param('kind', new ParseEnumPipe(UploadKind)) kind: UploadKind,
    @Param('filename') filename: string,
    @Headers('range') range: string | undefined,
    @Res({ passthrough: true }) response: Response,
    @Query('exp') exp?: string,
    @Query('sig') sig?: string,
  ): Promise<StreamableFile> {
    // ไฟล์ของขั้นตอนที่ต้องซื้อ: เปิดได้เฉพาะลิงก์ที่ backend เซ็นให้คนที่ซื้อแล้ว
    const isProtected = await this.protectedMedia.isProtected(kind, filename);
    if (isProtected && !this.mediaSigner.verify(kind, filename, exp, sig)) {
      throw new ForbiddenException('ลิงก์ไฟล์นี้หมดอายุหรือไม่มีสิทธิ์เปิด');
    }

    const file = await this.uploadsService.open(kind, filename, range);
    response.set({
      'Content-Type': file.mimeType,
      'Content-Length': file.size.toString(),
      'Accept-Ranges': 'bytes',
      // ไฟล์ที่ต้องซื้อ: เก็บได้แค่ในเครื่องผู้ใช้ ห้าม proxy/CDN เก็บแจกต่อ
      'Cache-Control': isProtected
        ? 'private, max-age=21600'
        : 'public, max-age=31536000, immutable',
      'X-Content-Type-Options': 'nosniff',
    });
    if (file.contentRange) {
      response.status(206);
      response.set('Content-Range', file.contentRange);
    }
    return new StreamableFile(file.stream);
  }
}
