import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { RegisterDto } from './register.dto';

describe('RegisterDto', () => {
  const valid = {
    email: 'cook@example.com',
    password: 'password1',
    displayName: 'Cook',
  };
  // ตั้งค่าเดียวกับ ValidationPipe ใน main.ts
  const errors = (body: object) =>
    validate(plainToInstance(RegisterDto, body), {
      whitelist: true,
      forbidNonWhitelisted: true,
    });

  it('accepts a normal sign-up', async () => {
    expect(await errors(valid)).toHaveLength(0);
  });

  it('does not let people choose their own role', async () => {
    expect(await errors({ ...valid, role: 'creator' })).not.toHaveLength(0);
    expect(await errors({ ...valid, role: 'admin' })).not.toHaveLength(0);
  });
});
