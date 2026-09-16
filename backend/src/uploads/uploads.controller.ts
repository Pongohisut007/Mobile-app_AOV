import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  ParseEnumPipe,
  Post,
  Res,
  StreamableFile,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CompleteUploadDto } from './dto/complete-upload.dto';
import { PresignUploadDto } from './dto/presign-upload.dto';
import type { Response } from 'express';
import {
  type UploadResult,
  type PresignedUploadResult,
  UploadKind,
  type UploadedFileData,
  UploadsService,
} from './uploads.service';

@Controller('uploads')
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  @Post('presign')
  @UseGuards(JwtAuthGuard)
  presign(@Body() dto: PresignUploadDto): Promise<PresignedUploadResult> {
    return this.uploadsService.presign(dto.kind, dto.mimeType, dto.size);
  }

  @Post('complete')
  @UseGuards(JwtAuthGuard)
  complete(@Body() dto: CompleteUploadDto): Promise<UploadResult> {
    return this.uploadsService.complete(dto.kind, dto.filename);
  }

  @Post('images')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }),
  )
  uploadImage(@UploadedFile() file?: UploadedFileData): Promise<UploadResult> {
    return this.uploadsService.saveImage(file);
  }

  @Post('videos')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: 100 * 1024 * 1024 } }),
  )
  uploadVideo(@UploadedFile() file?: UploadedFileData): Promise<UploadResult> {
    return this.uploadsService.saveVideo(file);
  }

  @Get(':kind/:filename')
  async open(
    @Param('kind', new ParseEnumPipe(UploadKind)) kind: UploadKind,
    @Param('filename') filename: string,
    @Headers('range') range: string | undefined,
    @Res({ passthrough: true }) response: Response,
  ): Promise<StreamableFile> {
    const file = await this.uploadsService.open(kind, filename, range);
    response.set({
      'Content-Type': file.mimeType,
      'Content-Length': file.size.toString(),
      'Accept-Ranges': 'bytes',
      'Cache-Control': 'public, max-age=31536000, immutable',
      'X-Content-Type-Options': 'nosniff',
    });
    if (file.contentRange) {
      response.status(206);
      response.set('Content-Range', file.contentRange);
    }
    return new StreamableFile(file.stream);
  }
}
