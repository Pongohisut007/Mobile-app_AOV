import {
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client, type TokenPayload } from 'google-auth-library';

export interface GoogleProfile {
  /** id ถาวรของบัญชี Google */
  sub: string;
  email: string;
  emailVerified: boolean;
  name: string | null;
  picture: string | null;
}

/** ตรวจ ID token ที่แอปได้จาก Google Sign-In (ลายเซ็น อายุ และ client ID ที่ออกให้) */
@Injectable()
export class GoogleTokenVerifier {
  private readonly client: OAuth2Client;
  private readonly clientIds: string[];

  constructor(config: ConfigService) {
    this.clientIds = config.get<string[]>('google.clientIds') ?? [];
    this.client = new OAuth2Client();
  }

  async verify(idToken: string): Promise<GoogleProfile> {
    if (this.clientIds.length === 0) {
      throw new ServiceUnavailableException(
        'ยังไม่ได้ตั้งค่าการเข้าสู่ระบบด้วย Google',
      );
    }

    let payload: TokenPayload | undefined;
    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: this.clientIds,
      });
      payload = ticket.getPayload();
    } catch {
      throw new UnauthorizedException('ยืนยันบัญชี Google ไม่สำเร็จ');
    }
    if (!payload?.sub || !payload.email) {
      throw new UnauthorizedException('ยืนยันบัญชี Google ไม่สำเร็จ');
    }

    return {
      sub: payload.sub,
      email: payload.email.toLowerCase(),
      emailVerified: payload.email_verified === true,
      name: payload.name?.trim() || null,
      picture: payload.picture ?? null,
    };
  }
}
