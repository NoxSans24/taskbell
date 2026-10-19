import 'dotenv/config';

import { decryptToken, encryptToken, isTokenCipherConfigured } from '../token_cipher';

describe('Telegram token cipher', () => {
  it('is configured from environment', () => {
    expect(isTokenCipherConfigured()).toBe(true);
  });

  it('round trips without storing plaintext', () => {
    const token = '123456789:ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghi';
    const encrypted = encryptToken(token);

    expect(encrypted).not.toContain(token);
    expect(encrypted.startsWith('v1.')).toBe(true);
    expect(decryptToken(encrypted)).toBe(token);
  });

  it('rejects a tampered payload', () => {
    const parts = encryptToken('rahasia').split('.');
    parts[3] = `${parts[3]}x`;

    expect(decryptToken(parts.join('.'))).toBeNull();
  });

  it('rejects an unknown version', () => {
    const parts = encryptToken('rahasia').split('.');
    parts[0] = 'v9';

    expect(decryptToken(parts.join('.'))).toBeNull();
  });
});
