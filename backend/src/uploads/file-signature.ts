/** จำนวน byte แรกของไฟล์ที่ต้องอ่านมาตรวจชนิด */
export const SIGNATURE_BYTES = 16;

const ascii = (head: Buffer, start: number, end: number) =>
  head.subarray(start, end).toString('latin1');

/**
 * ตรวจว่า byte แรกของไฟล์ตรงกับชนิดที่ผู้ส่งบอกมา (magic bytes)
 * กันไฟล์อันตราย (เช่น HTML/สคริปต์) ที่ตั้งชื่อหรือ Content-Type หลอกเป็นรูป
 */
export function matchesFileSignature(mimeType: string, head: Buffer): boolean {
  switch (mimeType) {
    case 'image/jpeg':
      return (
        head.length >= 3 &&
        head[0] === 0xff &&
        head[1] === 0xd8 &&
        head[2] === 0xff
      );
    case 'image/png':
      return head
        .subarray(0, 8)
        .equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]));
    case 'image/gif':
      return ['GIF87a', 'GIF89a'].includes(ascii(head, 0, 6));
    case 'image/webp':
      return ascii(head, 0, 4) === 'RIFF' && ascii(head, 8, 12) === 'WEBP';
    case 'video/webm':
      return head.subarray(0, 4).equals(Buffer.from([0x1a, 0x45, 0xdf, 0xa3]));
    // mp4 กับ mov เป็นตระกูลเดียวกัน (ISO base media) มือถือบางรุ่นบอกชนิดสลับกัน
    case 'video/mp4':
    case 'video/quicktime':
      return ascii(head, 4, 8) === 'ftyp';
    default:
      return false;
  }
}
