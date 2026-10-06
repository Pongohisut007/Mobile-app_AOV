import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { parseTrustProxy } from './common/trust-proxy';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // อยู่หลัง load balancer/ingress: ต้องเชื่อ X-Forwarded-For ถึงจะได้ IP จริงของผู้ใช้
  // (rate limit นับตาม IP) ตั้งเฉพาะตอนมี proxy จริง ไม่งั้นใครก็ปลอม IP ได้
  const trustProxy = parseTrustProxy(process.env.TRUST_PROXY);
  if (trustProxy !== undefined) app.set('trust proxy', trustProxy);

  // header ความปลอดภัยพื้นฐาน; ไฟล์ใน /uploads ต้องให้เปิดข้ามโดเมนได้ (แอป/เว็บ)
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap().catch((error) => {
  console.error('Failed to start application:', error);
  process.exit(1);
});
