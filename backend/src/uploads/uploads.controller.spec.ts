import { ForbiddenException } from '@nestjs/common';
import type { Response } from 'express';
import { Readable } from 'node:stream';
import { MediaSigner } from './media-signer.service';
import { ProtectedMediaService } from './protected-media.service';
import { UploadsController } from './uploads.controller';
import { UploadKind, UploadsService } from './uploads.service';

// เหมือน api-contract.spec: ไม่ต้องโหลด Passport (ESM) จริงในเทสต์
jest.mock('@nestjs/passport', () => ({
  AuthGuard: () =>
    class {
      canActivate() {
        return true;
      }
    },
}));

describe('UploadsController.open', () => {
  const uploads = {
    open: jest.fn().mockResolvedValue({
      stream: Readable.from(['x']),
      mimeType: 'video/mp4',
      size: 1,
    }),
  };
  const signer = { verify: jest.fn() };
  const protectedMedia = { isProtected: jest.fn() };
  const controller = new UploadsController(
    uploads as unknown as UploadsService,
    signer as unknown as MediaSigner,
    protectedMedia as unknown as ProtectedMediaService,
  );
  const response = () => {
    const headers: Record<string, string> = {};
    return {
      headers,
      res: {
        set: (values: Record<string, string>) => Object.assign(headers, values),
        status: jest.fn(),
      } as unknown as Response,
    };
  };

  beforeEach(() => jest.clearAllMocks());

  it('serves public files to anyone and lets them be cached', async () => {
    protectedMedia.isProtected.mockResolvedValue(false);
    const { res, headers } = response();

    await controller.open(UploadKind.IMAGES, 'cover.png', undefined, res);
    expect(uploads.open).toHaveBeenCalled();
    expect(headers['Cache-Control']).toContain('public');
  });

  it('needs a valid signature for paid step files', async () => {
    protectedMedia.isProtected.mockResolvedValue(true);
    signer.verify.mockReturnValue(false);

    await expect(
      controller.open(UploadKind.VIDEOS, 'step.mp4', undefined, response().res),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(uploads.open).not.toHaveBeenCalled();

    signer.verify.mockReturnValue(true);
    const { res, headers } = response();
    await controller.open(
      UploadKind.VIDEOS,
      'step.mp4',
      undefined,
      res,
      '9',
      'sig',
    );
    expect(signer.verify).toHaveBeenLastCalledWith(
      'videos',
      'step.mp4',
      '9',
      'sig',
    );
    // ห้าม proxy/CDN เก็บไว้แจกคนอื่น
    expect(headers['Cache-Control']).toContain('private');
  });
});
