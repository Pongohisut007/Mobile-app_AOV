import { randomUUID } from 'node:crypto';
import request from 'supertest';

const baseUrl = process.env.BASE_URL;
if (!baseUrl) {
  throw new Error(
    'BASE_URL is required: start the disposable CI Compose stack first.',
  );
}
const api = request(baseUrl);

interface AuthResponse {
  accessToken: string;
  user: { id: string; email: string; displayName: string };
}

describe('Built API image (e2e)', () => {
  // บัญชีที่เทสต์สมัครไว้ ลบทิ้งตอนจบด้วยการลบบัญชีตัวเอง (ไม่มี /users ให้ลบแทนกันแล้ว)
  let createdAccount: { token: string; password: string } | undefined;

  it('/ (GET)', () => {
    return api.get('/').expect(200).expect('Hello World!');
  });

  it('/health (GET)', () => {
    return api.get('/health').expect(200).expect({ status: 'ok' });
  });

  it('reads recipes and categories from the initialized database', async () => {
    const recipes = await api.get('/recipes').expect(200);
    const categories = await api.get('/categories').expect(200);
    expect(Array.isArray(recipes.body)).toBe(true);
    expect(Array.isArray(categories.body)).toBe(true);
  });

  it('rejects invalid recipe IDs and unauthenticated profile requests', async () => {
    await api.get('/recipes/not-a-uuid').expect(400);
    await api.get('/auth/me').expect(401);
  });

  it('registers, logs in, and validates a signed-in user against the database', async () => {
    const email = `ci-${randomUUID()}@example.test`;
    const password = 'ci-password';
    const registration = await api
      .post('/auth/register')
      .send({
        email,
        password,
        displayName: 'CI user',
      })
      .expect(201);
    const registered = registration.body as AuthResponse;
    const createdUserId = registered.user.id;
    createdAccount = { token: registered.accessToken, password };
    expect(registered.user.email).toBe(email);
    expect(typeof registered.accessToken).toBe('string');

    const login = await api
      .post('/auth/login')
      .send({ email, password })
      .expect(200);
    const loggedIn = login.body as AuthResponse;
    expect(loggedIn.user.id).toBe(createdUserId);
    await api
      .get('/auth/me')
      .set('Authorization', `Bearer ${loggedIn.accessToken}`)
      .expect(200)
      .expect((response) => {
        const user = response.body as AuthResponse['user'];
        expect(user.id).toBe(createdUserId);
        expect(user.email).toBe(email);
      });
  });

  it("keeps admin and other users' data behind authentication", async () => {
    await api.get('/users').expect(404);
    await api.get('/orders').expect(404);
    await api.post('/recipe-access').send({}).expect(404);
    await api.get('/recipe-access/me').expect(401);
    await api.post('/recipes').send({}).expect(401);
    await api.post('/categories').send({ name: 'x', slug: 'x' }).expect(401);
    await api.get('/recipes?status=draft').expect(403);
  });

  afterAll(async () => {
    if (createdAccount) {
      await api
        .post('/auth/delete-account')
        .set('Authorization', `Bearer ${createdAccount.token}`)
        .send({ password: createdAccount.password })
        .expect(204);
    }
  });
});
