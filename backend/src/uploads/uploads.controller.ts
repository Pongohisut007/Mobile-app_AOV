import {
  Controller,
  Get,
  Param,
  ParseEnumPipe,
  Post,
  Res,
  StreamableFile,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import {
  type UploadResult,
  UploadKind,
  type UploadedFileData,
  UploadsService,
} from './uploads.service';

@Controller('uploads')
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

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
    @Res({ passthrough: true }) response: Response,
  ): Promise<StreamableFile> {
    const file = await this.uploadsService.open(kind, filename);
    response.set({
      'Content-Type': file.mimeType,
      'Content-Length': file.size.toString(),
      'Cache-Control': 'public, max-age=31536000, immutable',
      'X-Content-Type-Options': 'nosniff',
    });
    return new StreamableFile(file.stream);
  }
}
