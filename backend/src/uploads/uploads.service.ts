import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { createReadStream, type ReadStream } from 'node:fs';
import { mkdir, stat, writeFile } from 'node:fs/promises';
import { basename, extname, join, resolve, sep } from 'node:path';
import { randomUUID } from 'node:crypto';

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

export interface StoredFile {
  stream: ReadStream;
  mimeType: string;
  size: number;
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
  private readonly uploadRoot = resolve(process.cwd(), 'uploads');

  saveImage(file?: UploadedFileData): Promise<UploadResult> {
    return this.save(file, UploadKind.IMAGES, IMAGE_TYPES, 10 * 1024 * 1024);
  }

  saveVideo(file?: UploadedFileData): Promise<UploadResult> {
    return this.save(file, UploadKind.VIDEOS, VIDEO_TYPES, 100 * 1024 * 1024);
  }

  async open(kind: UploadKind, filename: string): Promise<StoredFile> {
    const safeFilename = basename(filename);
    if (safeFilename !== filename) {
      throw new BadRequestException('Invalid filename');
    }

    const directory = resolve(this.uploadRoot, kind);
    const filePath = resolve(directory, safeFilename);
    if (!filePath.startsWith(`${directory}${sep}`)) {
      throw new BadRequestException('Invalid file path');
    }

    try {
      const fileStat = await stat(filePath);
      if (!fileStat.isFile()) throw new NotFoundException('File not found');

      return {
        stream: createReadStream(filePath),
        mimeType:
          MIME_BY_EXTENSION[extname(safeFilename).toLowerCase()] ??
          'application/octet-stream',
        size: fileStat.size,
      };
    } catch (error: unknown) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
        throw new NotFoundException('File not found');
      }
      throw error;
    }
  }

  private async save(
    file: UploadedFileData | undefined,
    kind: UploadKind,
    allowedTypes: Readonly<Record<string, string>>,
    maxSize: number,
  ): Promise<UploadResult> {
    if (!file) throw new BadRequestException('File is required');

    const extension = allowedTypes[file.mimetype];
    if (!extension) {
      throw new BadRequestException(
        `Unsupported file type: ${file.mimetype || 'unknown'}`,
      );
    }
    if (file.size > maxSize) {
      throw new BadRequestException(
        `File size must not exceed ${maxSize / 1024 / 1024} MB`,
      );
    }

    const directory = join(this.uploadRoot, kind);
    await mkdir(directory, { recursive: true });

    const filename = `${randomUUID()}${extension}`;
    await writeFile(join(directory, filename), file.buffer, { flag: 'wx' });

    return {
      filename,
      originalName: file.originalname,
      mimeType: file.mimetype,
      size: file.size,
      url: `/uploads/${kind}/${filename}`,
    };
  }
}
