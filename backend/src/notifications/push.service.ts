import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  cert,
  getApps,
  initializeApp,
  type ServiceAccount,
} from 'firebase-admin/app';
import { getMessaging, type Messaging } from 'firebase-admin/messaging';

export interface PushMessage {
  title: string;
  body: string;
  /** ส่งไปกับ push ให้แอปรู้ว่ากดแล้วต้องเปิดอะไร (ค่าเป็น string เท่านั้น) */
  data: Record<string, string>;
}

/** token ที่ FCM บอกว่าใช้ไม่ได้แล้ว (ลบแอป/ล้างข้อมูลแอป) ต้องลบทิ้ง */
const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

const APP_NAME = 'recipy-push';

/** ตัวส่ง push ผ่าน FCM ไม่ได้ตั้งค่า service account = ปิดเงียบ ๆ */
@Injectable()
export class PushService implements OnModuleInit {
  private readonly logger = new Logger(PushService.name);
  private messaging: Messaging | null = null;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    const account = this.serviceAccount();
    if (!account) {
      this.logger.log(
        'FIREBASE_SERVICE_ACCOUNT_JSON is not set: push notifications are off',
      );
      return;
    }
    const app =
      getApps().find((existing) => existing.name === APP_NAME) ??
      initializeApp({ credential: cert(account) }, APP_NAME);
    this.messaging = getMessaging(app);
  }

  get enabled(): boolean {
    return this.messaging !== null;
  }

  /** ส่งข้อความเดียวกันไปหลายเครื่อง คืน token ที่ตายแล้ว */
  async send(tokens: string[], message: PushMessage): Promise<string[]> {
    if (!this.messaging || tokens.length === 0) return [];

    const response = await this.messaging.sendEachForMulticast({
      tokens,
      notification: { title: message.title, body: message.body },
      data: message.data,
      // ไม่ระบุ channel: ใช้ช่องแจ้งเตือนตั้งต้นที่ FCM สร้างให้ในแอป
      android: { priority: 'high', notification: { sound: 'default' } },
      apns: { payload: { aps: { sound: 'default' } } },
    });

    const dead: string[] = [];
    response.responses.forEach((result, index) => {
      const code = result.error?.code;
      const token = tokens.at(index);
      if (!code || !token) return;
      if (DEAD_TOKEN_CODES.has(code)) {
        dead.push(token);
      } else {
        this.logger.warn(`FCM send failed: ${code}`);
      }
    });
    return dead;
  }

  /** รับได้ทั้ง JSON ตรง ๆ และ base64 (ตั้งเป็น env บรรทัดเดียวง่ายกว่า) */
  private serviceAccount(): ServiceAccount | null {
    const raw = this.config
      .get<string>('firebase.serviceAccountJson', '')
      .trim();
    if (!raw) return null;

    const text = raw.startsWith('{')
      ? raw
      : Buffer.from(raw, 'base64').toString('utf8');
    const parsed = JSON.parse(text) as {
      project_id?: string;
      client_email?: string;
      private_key?: string;
    };
    if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
      throw new Error(
        'FIREBASE_SERVICE_ACCOUNT_JSON must contain project_id, client_email and private_key',
      );
    }
    return {
      projectId: parsed.project_id,
      clientEmail: parsed.client_email,
      // ตั้งผ่าน env มักได้ \n เป็นตัวอักษร ต้องแปลงกลับเป็นขึ้นบรรทัดจริง
      privateKey: parsed.private_key.replace(/\\n/g, '\n'),
    };
  }
}
