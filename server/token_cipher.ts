import crypto from 'crypto';

const VERSION = 'v1';
const IV_BYTES = 12;

function getKey(): Buffer | null {
  const raw = process.env.TELEGRAM_TOKEN_KEY;
  if (!raw) return null;

  try {
    const key = Buffer.from(raw, 'base64');

    if (key.length !== 32) {
      return null;
    }

    return key;
  } catch {
    return null;
  }
}

export function isTokenCipherConfigured(): boolean {
  return getKey() !== null;
}

/// Mengenkripsi token bot dengan AES-256-GCM.
/// Format: v1.<iv>.<tag>.<ciphertext> (base64url).
export function encryptToken(token: string): string {
  const key = getKey();
  if (!key) {
    throw new Error('TELEGRAM_TOKEN_KEY belum dikonfigurasi.');
  }

  const iv = crypto.randomBytes(IV_BYTES);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([
    cipher.update(token, 'utf8'),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();

  return [
    VERSION,
    iv.toString('base64url'),
    tag.toString('base64url'),
    encrypted.toString('base64url'),
  ].join('.');
}

export function decryptToken(payload: string): string | null {
  const key = getKey();
  if (!key) return null;

  const parts = payload.split('.');
  if (parts.length !== 4 || parts[0] !== VERSION) return null;

  try {
    const iv = Buffer.from(parts[1], 'base64url');
    const tag = Buffer.from(parts[2], 'base64url');
    const data = Buffer.from(parts[3], 'base64url');

    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(tag);

    return Buffer.concat([decipher.update(data), decipher.final()]).toString(
      'utf8',
    );
  } catch {
    return null;
  }
}
