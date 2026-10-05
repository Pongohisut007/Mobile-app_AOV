import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Readable } from 'node:stream';
import { R2Provider } from './storage/r2.provider';
import { UploadKind, UploadsService } from './uploads.service';

async function readStream(stream: Readable): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk as string));
  }
  return Buffer.concat(chunks).toString();
}

describe('UploadsService.open (serving files)', () => {
  const r2 = { head: jest.fn(), download: jest.fn() };
  let service: UploadsService;

  beforeEach(() => {
    jest.clearAllMocks();
    // service ใหม่ทุกเทสต์ cache ใน RAM จะได้ไม่ปนกัน
    service = new UploadsService(r2 as unknown as R2Provider);
  });

  it('rejects filenames that try to escape the folder', async () => {
    await expect(
      service.open(UploadKind.IMAGES, '../secret.png'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(r2.head).not.toHaveBeenCalled();
  });

  it('downloads a small image once and serves it from memory afterwards', async () => {
    r2.head.mockResolvedValue({ ContentLength: 5, ContentType: 'image/png' });
    r2.download.mockResolvedValue({
      Body: Readable.from([Buffer.from('hello')]),
    });

    const first = await service.open(UploadKind.IMAGES, 'a.png');
    expect(await readStream(first.stream)).toBe('hello');
    expect(first).toMatchObject({ mimeType: 'image/png', size: 5 });

    const ranged = await service.open(UploadKind.IMAGES, 'a.png', 'bytes=1-3');
    expect(await readStream(ranged.stream)).toBe('ell');
    expect(ranged).toMatchObject({ size: 3, contentRange: 'bytes 1-3/5' });

    expect(r2.head).toHaveBeenCalledTimes(1);
    expect(r2.download).toHaveBeenCalledTimes(1);
  });

  it('falls back to the extension when R2 has no content type', async () => {
    r2.head.mockResolvedValue({ ContentLength: 2 });
    r2.download.mockResolvedValue({ Body: Readable.from([Buffer.from('hi')]) });

    const file = await service.open(UploadKind.IMAGES, 'b.webp');
    expect(file.mimeType).toBe('image/webp');
  });

  it('streams videos from R2 with the requested byte range', async () => {
    r2.head.mockResolvedValue({ ContentLength: 100, ContentType: 'video/mp4' });
    r2.download.mockResolvedValue({ Body: Readable.from(['part']) });

    const file = await service.open(UploadKind.VIDEOS, 'v.mp4', 'bytes=10-19');

    expect(r2.download).toHaveBeenCalledWith('videos/v.mp4', 'bytes=10-19');
    expect(file).toMatchObject({
      size: 10,
      contentRange: 'bytes 10-19/100',
    });
  });

  it('supports suffix and open-ended ranges', async () => {
    r2.head.mockResolvedValue({ ContentLength: 100, ContentType: 'video/mp4' });
    r2.download.mockResolvedValue({ Body: Readable.from(['x']) });

    const suffix = await service.open(UploadKind.VIDEOS, 'v.mp4', 'bytes=-20');
    expect(suffix.contentRange).toBe('bytes 80-99/100');

    const open = await service.open(UploadKind.VIDEOS, 'v.mp4', 'bytes=90-');
    expect(open.contentRange).toBe('bytes 90-99/100');

    const clamped = await service.open(
      UploadKind.VIDEOS,
      'v.mp4',
      'bytes=95-500',
    );
    expect(clamped.contentRange).toBe('bytes 95-99/100');
  });

  it('streams the whole video when no range is requested', async () => {
    r2.head.mockResolvedValue({ ContentLength: 100 });
    r2.download.mockResolvedValue({ Body: Readable.from(['x']) });

    const file = await service.open(UploadKind.VIDEOS, 'v.mov');

    expect(r2.download).toHaveBeenCalledWith('videos/v.mov', undefined);
    expect(file).toMatchObject({ size: 100, mimeType: 'video/quicktime' });
    expect(file.contentRange).toBeUndefined();
  });

  it.each(['bytes=abc', 'bytes=-', 'bytes=-0', 'bytes=200-', 'bytes=50-10'])(
    'rejects the invalid range %s with 416',
    async (range) => {
      r2.head.mockResolvedValue({ ContentLength: 100 });
      await expect(
        service.open(UploadKind.VIDEOS, 'v.mp4', range),
      ).rejects.toMatchObject({ status: 416 });
    },
  );

  it.each([
    [{ name: 'NoSuchKey' }],
    [{ name: 'NotFound' }],
    [{ Code: 'NoSuchKey' }],
  ])('maps the R2 error %o to 404', async (error) => {
    r2.head.mockRejectedValue(error);
    await expect(
      service.open(UploadKind.IMAGES, 'missing.png'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('treats objects without a size as missing', async () => {
    r2.head.mockResolvedValue({});
    await expect(
      service.open(UploadKind.IMAGES, 'empty.png'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('treats downloads without a body as missing', async () => {
    r2.head.mockResolvedValue({ ContentLength: 10 });
    r2.download.mockResolvedValue({});

    await expect(
      service.open(UploadKind.IMAGES, 'nobody.png'),
    ).rejects.toBeInstanceOf(NotFoundException);
    await expect(
      service.open(UploadKind.VIDEOS, 'nobody.mp4'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('rethrows unexpected R2 errors', async () => {
    r2.head.mockRejectedValue(new Error('network down'));
    await expect(service.open(UploadKind.IMAGES, 'x.png')).rejects.toThrow(
      'network down',
    );
  });
});
