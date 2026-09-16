import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { basename, extname } from 'node:path';
import { randomUUID } from 'node:crypto';
import { Readable } from 'node:stream';
import { R2Provider } from './storage/r2.provider';

export enum UploadKind {
  IMAGES = 'images',
  VIDEOS = 'videos',
}

export interface UploadedFileData {
  originalname: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
}

export interface UploadResult {
  filename: string;
  originalName: string;
  mimeType: string;
  size: number;
  url: string;
}

export interface PresignedUploadResult {
  filename: string;
  url: string;
  uploadUrl: string;
  method: 'PUT';
  headers: { 'Content-Type': string };
  expiresIn: number;
}

export interface StoredFile {
  stream: Readable;
  mimeType: string;
  size: number;
  contentRange?: string;
}

const IMAGE_TYPES: Readonly<Record<string, string>> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
};

const VIDEO_TYPES: Readonly<Record<string, string>> = {
  'video/mp4': '.mp4',
  'video/webm': '.webm',
  'video/quicktime': '.mov',
};

const MIME_BY_EXTENSION: Readonly<Record<string, string>> = {
  ...Object.fromEntries(
    Object.entries(IMAGE_TYPES).map(([mimeType, extension]) => [
      extension,
      mimeType,
    ]),
  ),
  ...Object.fromEntries(
    Object.entries(VIDEO_TYPES).map(([mimeType, extension]) => [
      extension,
      mimeType,
    ]),
  ),
};

@Injectable()
export class UploadsService {
  constructor(private readonly r2: R2Provider) {}

  async presign(
    kind: UploadKind,
    mimeType: string,
    size: number,
  ): Promise<PresignedUploadResult> {
    const extension = this.validateUpload(kind, mimeType, size);
    const filename = `${randomUUID()}${extension}`;
    const expiresIn = 300;
    const uploadUrl = await this.r2.presignUpload(
      `${kind}/${filename}`,
      mimeType,
      expiresIn,
    );
    return {
      filename,
      url: `/uploads/${kind}/${filename}`,
      uploadUrl,
      method: 'PUT',
      headers: { 'Content-Type': mimeType },
      expiresIn,
    };
  }

  async complete(kind: UploadKind, filename: string): Promise<UploadResult> {
    const mimeType = MIME_BY_EXTENSION[extname(filename).toLowerCase()];
    if (!mimeType || !this.allowedTypes(kind)[mimeType]) {
      throw new BadRequestException('Invalid filename for upload kind');
    }
    const key = `${kind}/${filename}`;
    let object: Awaited<ReturnType<R2Provider['head']>>;
    try {
      object = await this.r2.head(key);
    } catch (error: unknown) {
      const r2Error = error as { name?: string; Code?: string };
      if (
        r2Error.name === 'NoSuchKey' ||
        r2Error.name === 'NotFound' ||
        r2Error.Code === 'NoSuchKey'
      ) {
        throw new NotFoundException('Uploaded file not found');
      }
      throw error;
    }
    const size = object.ContentLength;
    if (!size || size > this.maxSize(kind) || object.ContentType !== mimeType) {
      await this.r2.delete(key);
      throw new BadRequestException('Uploaded file has invalid size or type');
    }
    return {
      filename,
      originalName: filename,
      mimeType,
      size,
      url: `/uploads/${kind}/${filename}`,
    };
  }

  saveImage(file?: UploadedFileData): Promise<UploadResult> {
    return this.save(file, UploadKind.IMAGES);
  }

  saveVideo(file?: UploadedFileData): Promise<UploadResult> {
    return this.save(file, UploadKind.VIDEOS);
  }

  async open(
    kind: UploadKind,
    filename: string,
    rangeHeader?: string,
  ): Promise<StoredFile> {
    const safeFilename = basename(filename);
    if (safeFilename !== filename) {
      throw new BadRequestException('Invalid filename');
    }

    const key = `${kind}/${safeFilename}`;

    try {
      const object = await this.r2.head(key);
      const fileSize = object.ContentLength;
      if (fileSize === undefined) throw new NotFoundException('File not found');

      const range = this.parseRange(rangeHeader, fileSize);
      const downloaded = await this.r2.download(
        key,
        range ? `bytes=${range.start}-${range.end}` : undefined,
      );
      if (!downloaded.Body) throw new NotFoundException('File not found');

      return {
        stream: downloaded.Body as Readable,
        mimeType:
          object.ContentType ??
          MIME_BY_EXTENSION[extname(safeFilename).toLowerCase()] ??
          'application/octet-stream',
        size: range ? range.end - range.start + 1 : fileSize,
        contentRange: range
          ? `bytes ${range.start}-${range.end}/${fileSize}`
          : undefined,
      };
    } catch (error: unknown) {
      const r2Error = error as { name?: string; Code?: string };
      if (
        r2Error.name === 'NoSuchKey' ||
        r2Error.name === 'NotFound' ||
        r2Error.Code === 'NoSuchKey'
      ) {
        throw new NotFoundException('File not found');
      }
      throw error;
    }
  }

  private parseRange(
    rangeHeader: string | undefined,
    fileSize: number,
  ): { start: number; end: number } | undefined {
    if (!rangeHeader) return undefined;

    const match = /^bytes=(\d*)-(\d*)$/.exec(rangeHeader.trim());
    if (!match || (!match[1] && !match[2]) || fileSize === 0) {
      this.throwInvalidRange(fileSize);
    }

    const startText = match[1];
    const endText = match[2];
    let start: number;
    let end: number;

    if (!startText) {
      const suffixLength = Number(endText);
      if (!Number.isSafeInteger(suffixLength) || suffixLength <= 0) {
        this.throwInvalidRange(fileSize);
      }
      start = Math.max(fileSize - suffixLength, 0);
      end = fileSize - 1;
    } else {
      start = Number(startText);
      end = endText ? Number(endText) : fileSize - 1;
    }

    if (
      !Number.isSafeInteger(start) ||
      !Number.isSafeInteger(end) ||
      start < 0 ||
      start >= fileSize ||
      end < start
    ) {
      this.throwInvalidRange(fileSize);
    }

    return { start, end: Math.min(end, fileSize - 1) };
  }

  private throwInvalidRange(fileSize: number): never {
    throw new HttpException(
      {
        statusCode: HttpStatus.REQUESTED_RANGE_NOT_SATISFIABLE,
        message: 'Requested range not satisfiable',
        contentRange: `bytes */${fileSize}`,
      },
      HttpStatus.REQUESTED_RANGE_NOT_SATISFIABLE,
    );
  }

  private async save(
    file: UploadedFileData | undefined,
    kind: UploadKind,
  ): Promise<UploadResult> {
    if (!file) throw new BadRequestException('File is required');

    const extension = this.validateUpload(kind, file.mimetype, file.size);

    const filename = `${randomUUID()}${extension}`;
    await this.r2.upload(`${kind}/${filename}`, file.buffer, file.mimetype);

    return {
      filename,
      originalName: file.originalname,
      mimeType: file.mimetype,
      size: file.size,
      url: `/uploads/${kind}/${filename}`,
    };
  }

  private validateUpload(
    kind: UploadKind,
    mimeType: string,
    size: number,
  ): string {
    const extension = this.allowedTypes(kind)[mimeType];
    if (!extension) {
      throw new BadRequestException(
        `Unsupported file type: ${mimeType || 'unknown'}`,
      );
    }
    const maxSize = this.maxSize(kind);
    if (!Number.isSafeInteger(size) || size < 1 || size > maxSize) {
      throw new BadRequestException(
        `File size must be between 1 byte and ${maxSize / 1024 / 1024} MB`,
      );
    }
    return extension;
  }

  private allowedTypes(kind: UploadKind): Readonly<Record<string, string>> {
    return kind === UploadKind.IMAGES ? IMAGE_TYPES : VIDEO_TYPES;
  }

  private maxSize(kind: UploadKind): number {
    return kind === UploadKind.IMAGES ? 10 * 1024 * 1024 : 100 * 1024 * 1024;
  }
}
