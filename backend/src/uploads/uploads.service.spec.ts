import { BadRequestException, NotFoundException } from '@nestjs/common';
import { UploadKind, UploadsService } from './uploads.service';
import { R2Provider } from './storage/r2.provider';

describe('UploadsService presigned uploads', () => {
  const r2 = {
    presignUpload: jest.fn(),
    head: jest.fn(),
    delete: jest.fn(),
  };
  const service = new UploadsService(r2 as unknown as R2Provider);

  beforeEach(() => {
    jest.clearAllMocks();
    r2.presignUpload.mockResolvedValue('https://r2.example/signed');
    r2.delete.mockResolvedValue(undefined);
  });

  it('signs an image PUT and preserves the existing read URL', async () => {
    const result = await service.presign(UploadKind.IMAGES, 'image/png', 123);
    expect(result.method).toBe('PUT');
    expect(result.headers).toEqual({ 'Content-Type': 'image/png' });
    expect(result.filename).toMatch(/^[0-9a-f-]+\.png$/);
    expect(result.url).toBe(`/uploads/images/${result.filename}`);
    expect(r2.presignUpload).toHaveBeenCalledWith(
      `images/${result.filename}`,
      'image/png',
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
