import { matchesFileSignature } from './file-signature';

const bytes = (...values: number[]) => Buffer.from(values);
const text = (value: string) => Buffer.from(value, 'latin1');

describe('matchesFileSignature', () => {
  it('recognises each allowed type', () => {
    expect(
      matchesFileSignature('image/jpeg', bytes(0xff, 0xd8, 0xff, 0xe0)),
    ).toBe(true);
    expect(
      matchesFileSignature(
        'image/png',
        bytes(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a),
      ),
    ).toBe(true);
    expect(matchesFileSignature('image/gif', text('GIF89a...'))).toBe(true);
    expect(
      matchesFileSignature('image/webp', text('RIFF\0\0\0\0WEBPVP8 ')),
    ).toBe(true);
    expect(
      matchesFileSignature('video/webm', bytes(0x1a, 0x45, 0xdf, 0xa3)),
    ).toBe(true);
    expect(matchesFileSignature('video/mp4', text('\0\0\0\x18ftypisom'))).toBe(
      true,
    );
    expect(
      matchesFileSignature('video/quicktime', text('\0\0\0\x14ftypqt  ')),
    ).toBe(true);
  });

  it('rejects mismatched, short or unknown content', () => {
    expect(matchesFileSignature('image/png', text('<html>'))).toBe(false);
    expect(matchesFileSignature('image/jpeg', bytes(0xff))).toBe(false);
    expect(matchesFileSignature('image/webp', text('RIFF\0\0\0\0WAVE'))).toBe(
      false,
    );
    expect(matchesFileSignature('video/mp4', text('<?xml version'))).toBe(
      false,
    );
    expect(matchesFileSignature('text/html', text('<html>'))).toBe(false);
  });
});
