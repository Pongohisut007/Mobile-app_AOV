import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport, type Transporter } from 'nodemailer';

export interface MailMessage {
  to: string;
  subject: string;
  text: string;
  html?: string;
}

/**
 * ส่งอีเมลผ่าน SMTP (ตั้งค่าใน config/mail.config.ts)
 * ยังไม่ได้ตั้ง SMTP: ตอนพัฒนาพิมพ์อีเมลลง log ให้ทดสอบต่อได้ ส่วน production ถือว่า error
 */
@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter?: Transporter;

  constructor(private readonly config: ConfigService) {}

  get isConfigured(): boolean {
    return this.config.get<string>('mail.host', '').length > 0;
  }

  async send(message: MailMessage): Promise<void> {
    if (!this.isConfigured) {
      if (this.config.get<string>('NODE_ENV') === 'production') {
        this.logger.error('SMTP_HOST is not set; cannot send email');
        throw new ServiceUnavailableException(
          'ระบบส่งอีเมลยังไม่พร้อม กรุณาลองใหม่ภายหลัง',
        );
      }
      this.logger.warn(
        `SMTP_HOST is not set; email not sent\nTo: ${message.to}\nSubject: ${message.subject}\n${message.text}`,
      );
      return;
    }

    try {
      await this.getTransporter().sendMail({
        from: this.config.get<string>('mail.from'),
        to: message.to,
        subject: message.subject,
        text: message.text,
        html: message.html,
      });
    } catch (error) {
      this.logger.error(`Failed to send email: ${String(error)}`);
      throw new ServiceUnavailableException(
        'ส่งอีเมลไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
      );
    }
  }

  private getTransporter(): Transporter {
    this.transporter ??= createTransport({
      host: this.config.get<string>('mail.host'),
      port: this.config.get<number>('mail.port'),
      secure: this.config.get<boolean>('mail.secure'),
      auth: {
        user: this.config.get<string>('mail.user'),
        pass: this.config.get<string>('mail.pass'),
      },
    });
    return this.transporter;
  }
}
