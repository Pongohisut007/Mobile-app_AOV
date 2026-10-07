import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Readable } from 'node:stream';
import { UploadKind, UploadsService } from './uploads.service';
import { R2Provider } from './storage/r2.provider';

describe('UploadsService presigned uploads', () => {
  const r2 = {
    presignUpload: jest.fn(),
    head: jest.fn(),
    delete: jest.fn(),
    download: jest.fn(),
    upload: jest.fn(),
  };
  const PNG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const firstBytes = (bytes: Buffer) => ({ Body: Readable.from([bytes]) });
  const service = new UploadsService(r2 as unknown as R2Provider);

  beforeEach(() => {
    jest.clearAllMocks();
    r2.presignUpload.mockResolvedValue('https://r2.example/signed');
    r2.delete.mockResolvedValue(undefined);
    r2.upload.mockResolvedValue(undefined);
    r2.download.mockImplementation(() => Promise.resolve(firstBytes(PNG)));
  });

  it('signs the declared size so a larger file cannot be uploaded', async () => {
    const result = await service.presign(UploadKind.IMAGES, 'image/png', 123);
    expect(result.method).toBe('PUT');
    expect(result.headers).toEqual({ 'Content-Type': 'image/png' });
    expect(result.filename).toMatch(/^[0-9a-f-]+\.png$/);
    expect(result.url).toBe(`/uploads/images/${result.filename}`);
    expect(r2.presignUpload).toHaveBeenCalledWith(
      `images/${result.filename}`,
      'image/png',
      123,
      300,
    );
  });

  it('rejects unsupported types and oversize files before signing', async () => {
    await expect(
      service.presign(UploadKind.IMAGES, 'video/mp4', 1),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.presign(UploadKind.VIDEOS, 'video/mp4', 100 * 1024 * 1024 + 1),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(r2.presignUpload).not.toHaveBeenCalled();
  });

  it('confirms the object size and type after upload', async () => {
    r2.head.mockResolvedValue({ ContentLength: 123, ContentType: 'image/png' });
    const filename = '7d87b810-4274-4b3f-92bb-83013ba857d9.png';
    const result = await service.complete(UploadKind.IMAGES, filename);
    expect(result.size).toBe(123);
    expect(result.url).toBe(`/uploads/images/${filename}`);
    expect(r2.download).toHaveBeenCalledWith(
      `images/${filename}`,
      'bytes=0-15',
    );
  });

  it('deletes an upload whose content is not really the claimed type', async () => {
    r2.head.mockResolvedValue({ ContentLength: 123, ContentType: 'image/png' });
    r2.download.mockResolvedValue(firstBytes(Buffer.from('<html><script>')));
    await expect(
      service.complete(
        UploadKind.IMAGES,
        '7d87b810-4274-4b3f-92bb-83013ba857d9.png',
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(r2.delete).toHaveBeenCalled();
  });

  it('checks direct uploads before storing them', async () => {
    const file = (buffer: Buffer) => ({
      buffer,
      mimetype: 'image/png',
      originalname: 'x.png',
      size: buffer.length,
    });
    await expect(
      service.saveImage(file(Buffer.from('GIF89a not a png'))),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(r2.upload).not.toHaveBeenCalled();

    await expect(service.saveImage(file(PNG))).resolves.toEqual(
      expect.objectContaining({ mimeType: 'image/png' }),
    );
    expect(r2.upload).toHaveBeenCalled();
  });

  it('deletes an object that exceeds the size limit', async () => {
    r2.head.mockResolvedValue({
      ContentLength: 10 * 1024 * 1024 + 1,
      ContentType: 'image/png',
    });
    await expect(
      service.complete(
        UploadKind.IMAGES,
        '7d87b810-4274-4b3f-92bb-83013ba857d9.png',
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(r2.delete).toHaveBeenCalled();
  });

  it('reports a missing upload', async () => {
    r2.head.mockRejectedValue({ name: 'NotFound' });
    await expect(
      service.complete(
        UploadKind.IMAGES,
        '7d87b810-4274-4b3f-92bb-83013ba857d9.png',
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
