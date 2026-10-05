import { User, UserRole, UserStatus } from './user.entity';

describe('User JSON', () => {
  it('only exposes public fields', () => {
    const user = Object.assign(new User(), {
      id: 'u1',
      email: 'cook@example.com',
      passwordHash: 'hash',
      displayName: 'Cook',
      avatarUrl: null,
      role: UserRole.CREATOR,
      status: UserStatus.ACTIVE,
      tokenVersion: 3,
      createdAt: new Date('2026-01-01T00:00:00Z'),
    });

    const json = JSON.parse(JSON.stringify({ creator: user })) as {
      creator: Record<string, unknown>;
    };

    expect(json.creator).toEqual({
      id: 'u1',
      displayName: 'Cook',
      avatarUrl: null,
      role: 'creator',
      createdAt: '2026-01-01T00:00:00.000Z',
    });
  });
});
