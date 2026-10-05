import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport } from 'nodemailer';
import { MailService } from './mail.service';

jest.mock('nodemailer', () => ({ createTransport: jest.fn() }));

describe('MailService', () => {
  const message = { to: 'cook@example.com', subject: 'Hi', text: 'Code' };
  const sendMail = jest.fn();

  const serviceWith = (values: Record<string, unknown>) =>
    new MailService({
      get: (key: string, fallback?: unknown) => values[key] ?? fallback,
    } as unknown as ConfigService);

  beforeEach(() => {
    sendMail.mockReset().mockResolvedValue(undefined);
    (createTransport as jest.Mock).mockReset().mockReturnValue({ sendMail });
  });

  it('sends through SMTP when configured', async () => {
    const service = serviceWith({
      'mail.host': 'smtp.gmail.com',
      'mail.port': 465,
      'mail.secure': true,
      'mail.user': 'me@gmail.com',
      'mail.pass': 'app-password',
      'mail.from': 'Recipy <me@gmail.com>',
    });

    expect(service.isConfigured).toBe(true);
    await service.send(message);
    await service.send(message);

    // สร้างการเชื่อมต่อครั้งเดียวแล้วใช้ซ้ำ
    expect(createTransport).toHaveBeenCalledTimes(1);
    expect(createTransport).toHaveBeenCalledWith(
      expect.objectContaining({
        host: 'smtp.gmail.com',
        auth: { user: 'me@gmail.com', pass: 'app-password' },
      }),
    );
    expect(sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        from: 'Recipy <me@gmail.com>',
        to: message.to,
      }),
    );
  });

  it('reports SMTP failures as unavailable', async () => {
    sendMail.mockRejectedValue(new Error('auth failed'));
    const service = serviceWith({ 'mail.host': 'smtp.gmail.com' });

    await expect(service.send(message)).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('only logs the email in development when SMTP is not set', async () => {
    const service = serviceWith({});

    expect(service.isConfigured).toBe(false);
    await expect(service.send(message)).resolves.toBeUndefined();
    expect(createTransport).not.toHaveBeenCalled();
  });

  it('fails in production when SMTP is not set', async () => {
    const service = serviceWith({ NODE_ENV: 'production' });

    await expect(service.send(message)).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });
});
