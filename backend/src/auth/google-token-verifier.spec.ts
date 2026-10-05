import {
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleTokenVerifier } from './google-token-verifier';

const verifyIdToken = jest.fn();
jest.mock('google-auth-library', () => ({
  OAuth2Client: jest.fn().mockImplementation(() => ({ verifyIdToken })),
}));

function verifier(clientIds: string[]) {
  const config = { get: jest.fn().mockReturnValue(clientIds) };
  return new GoogleTokenVerifier(config as unknown as ConfigService);
}

describe('GoogleTokenVerifier', () => {
  beforeEach(() => verifyIdToken.mockReset());

  it('is disabled until client IDs are configured', async () => {
    await expect(verifier([]).verify('token')).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
    expect(verifyIdToken).not.toHaveBeenCalled();
  });

  it('checks the token against every configured client ID', async () => {
    verifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'g-1',
        email: 'Cook@Gmail.com',
        email_verified: true,
        name: '  Cook  ',
        picture: 'p.png',
      }),
    });

    await expect(verifier(['web', 'ios']).verify('token')).resolves.toEqual({
      sub: 'g-1',
      email: 'cook@gmail.com',
      emailVerified: true,
      name: 'Cook',
      picture: 'p.png',
    });
    expect(verifyIdToken).toHaveBeenCalledWith({
      idToken: 'token',
      audience: ['web', 'ios'],
    });
  });

  it('treats a missing verified flag and name as false / null', async () => {
    verifyIdToken.mockResolvedValue({
      getPayload: () => ({ sub: 'g-1', email: 'a@b.co' }),
    });
    await expect(verifier(['web']).verify('token')).resolves.toEqual(
      expect.objectContaining({
        emailVerified: false,
        name: null,
        picture: null,
      }),
    );
  });

  it('rejects invalid tokens and payloads without an email', async () => {
    verifyIdToken.mockRejectedValue(new Error('Wrong recipient'));
    await expect(verifier(['web']).verify('bad')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );

    verifyIdToken.mockResolvedValue({ getPayload: () => ({ sub: 'g-1' }) });
    await expect(verifier(['web']).verify('token')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
