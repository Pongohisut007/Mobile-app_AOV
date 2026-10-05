import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual } from 'node:crypto';

/** ลายเซ็นใช้ได้อย่างน้อยเท่านี้ (และไม่เกิน 2 เท่า) */
const WINDOW_SECONDS = 6 * 60 * 60;

// path เปล่า หรือ URL เต็มของข้อมูลเก่า (http://host/uploads/...)
const UPLOAD_PATH =
  /^(?:https?:\/\/[^/]+)?\/uploads\/(images|videos)\/([^/?#]+)$/;

/**
 * ลิงก์ไฟล์ของขั้นตอนที่ต้องซื้อก่อนดู แนบลายเซ็น + วันหมดอายุ (?exp=&sig=)
 * - ใครได้ลิงก์ไปก็ใช้ได้แค่ชั่วคราว ไม่ใช่ตลอดไป
 * - วันหมดอายุปัดเป็นช่วง 6 ชั่วโมง ลิงก์จึงเหมือนเดิมทั้งช่วง (แอป/HTTP cache ได้)
 */
@Injectable()
export class MediaSigner {
  private readonly secret: string;

  constructor(config: ConfigService) {
    this.secret =
      config.get<string>('MEDIA_SIGNING_SECRET') ||
      `media:${config.getOrThrow<string>('jwt.secret')}`;
  }

  /**
   * "/uploads/videos/x.mp4" → "/uploads/videos/x.mp4?exp=...&sig=..."
   * URL เต็มก็เซ็นได้ (คงโดเมนเดิมไว้) ลิงก์อื่นที่ไม่ใช่ไฟล์ของเราคืนตามเดิม
   */
  sign(url: string, now = Date.now()): string {
    const path = MediaSigner.stripQuery(url);
    const match = UPLOAD_PATH.exec(path);
    if (!match) return url;
    const nowSeconds = Math.floor(now / 1000);
    const exp = (Math.floor(nowSeconds / WINDOW_SECONDS) + 2) * WINDOW_SECONDS;
    const sig = this.signature(match[1], match[2], exp);
    return `${path}?exp=${exp}&sig=${sig}`;
  }

  verify(
    kind: string,
    filename: string,
    exp: string | undefined,
    sig: string | undefined,
    now = Date.now(),
  ): boolean {
    if (!exp || !sig || !/^\d+$/.test(exp)) return false;
    const expiresAt = Number(exp);
    if (expiresAt * 1000 <= now) return false;
    const expected = Buffer.from(this.signature(kind, filename, expiresAt));
    const given = Buffer.from(sig);
    return expected.length === given.length && timingSafeEqual(expected, given);
  }

  /** ตัด ?exp=&sig= ออก (เก็บลงฐานข้อมูลเป็น path เปล่าเสมอ) */
  static stripQuery(url: string): string {
    const index = url.search(/[?#]/);
    return index === -1 ? url : url.slice(0, index);
  }

  private signature(kind: string, filename: string, exp: number): string {
    return createHmac('sha256', this.secret)
      .update(`${kind}/${filename}:${exp}`)
      .digest('base64url');
  }
}
