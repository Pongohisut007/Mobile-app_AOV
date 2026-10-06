import { resolveAppEnv } from '../../config/app.config';

describe('resolveAppEnv', () => {
  it('uses APP_ENV when it is set', () => {
    expect(resolveAppEnv({ APP_ENV: 'staging', NODE_ENV: 'production' })).toBe(
      'staging',
    );
    expect(resolveAppEnv({ APP_ENV: ' production ' })).toBe('production');
    expect(resolveAppEnv({ APP_ENV: 'development' })).toBe('development');
  });

  it('falls back to NODE_ENV when APP_ENV is missing', () => {
    expect(resolveAppEnv({ NODE_ENV: 'production' })).toBe('production');
    expect(resolveAppEnv({ NODE_ENV: 'test' })).toBe('development');
    expect(resolveAppEnv({ APP_ENV: '' })).toBe('development');
  });

  it('refuses unknown values instead of guessing', () => {
    expect(() => resolveAppEnv({ APP_ENV: 'prod' })).toThrow('APP_ENV');
  });
});
