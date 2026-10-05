import { ConfigService } from '@nestjs/config';
import { MediaSigner } from './media-signer.service';

describe('MediaSigner', () => {
  const signer = new MediaSigner({
    get: () => undefined,
    getOrThrow: () => 'jwt-secret',
  } as unknown as ConfigService);
  const now = Date.UTC(2026, 9, 6, 1, 0, 0);
  const hour = 60 * 60 * 1000;

  const parse = (url: string) => {
    const parsed = new URL(url, 'http://api');
    return {
      path: parsed.pathname,
      exp: parsed.searchParams.get('exp') ?? undefined,
      sig: parsed.searchParams.get('sig') ?? undefined,
    };
  };

  it('signs upload paths and verifies them until they expire', () => {
    const signed = signer.sign('/uploads/videos/step.mp4', now);
    const { path, exp, sig } = parse(signed);

    expect(path).toBe('/uploads/videos/step.mp4');
    expect(signer.verify('videos', 'step.mp4', exp, sig, now)).toBe(true);
    // ใช้ได้อย่างน้อย 6 ชั่วโมง
    expect(signer.verify('videos', 'step.mp4', exp, sig, now + 6 * hour)).toBe(
      true,
    );
    expect(signer.verify('videos', 'step.mp4', exp, sig, now + 13 * hour)).toBe(
      false,
    );
  });

  it('keeps the same link within a window so it can be cached', () => {
    expect(signer.sign('/uploads/images/a.png', now)).toBe(
      signer.sign('/uploads/images/a.png', now + 30 * 60 * 1000),
    );
  });

  it('rejects tampered, swapped or missing signatures', () => {
    const { exp, sig } = parse(signer.sign('/uploads/videos/a.mp4', now));
    expect(signer.verify('videos', 'b.mp4', exp, sig, now)).toBe(false);
    expect(signer.verify('images', 'a.mp4', exp, sig, now)).toBe(false);
    expect(
      signer.verify('videos', 'a.mp4', String(Number(exp) + 1), sig, now),
    ).toBe(false);
    expect(signer.verify('videos', 'a.mp4', exp, `${sig}x`, now)).toBe(false);
    expect(signer.verify('videos', 'a.mp4', undefined, sig, now)).toBe(false);
    expect(signer.verify('videos', 'a.mp4', 'soon', sig, now)).toBe(false);
  });

  it('signs full URLs stored by older app versions', () => {
    const signed = signer.sign(
      'http://10.0.2.2:3000/uploads/videos/old.mp4',
      now,
    );
    const { exp, sig } = parse(signed);
    expect(
      signed.startsWith('http://10.0.2.2:3000/uploads/videos/old.mp4?'),
    ).toBe(true);
    expect(signer.verify('videos', 'old.mp4', exp, sig, now)).toBe(true);
  });

  it('re-signs already signed links and ignores other URLs', () => {
    const once = signer.sign('/uploads/images/a.png', now);
    expect(signer.sign(once, now)).toBe(once);
    expect(signer.sign('https://example.com/x.png', now)).toBe(
      'https://example.com/x.png',
    );
    expect(MediaSigner.stripQuery(once)).toBe('/uploads/images/a.png');
    expect(MediaSigner.stripQuery('/uploads/images/a.png')).toBe(
      '/uploads/images/a.png',
    );
  });
});
