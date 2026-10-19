import * as bcrypt from 'bcryptjs';

// Hash yang dibuat bcrypt native ($2b$, cost 12) sebelum migrasi ke bcryptjs.
// Dipakai untuk memastikan pengguna lama tetap bisa login.
const LEGACY_HASH =
  '$2b$12$LYPjkj6xJXXgHwHCY0S77eumT9ludIWBNOfk9CuGQONKeMy0hWuYi';

describe('Password hashing', () => {
  it('verifies hashes produced by native bcrypt', async () => {
    await expect(bcrypt.compare('Password123!', LEGACY_HASH)).resolves.toBe(
      true,
    );
    await expect(bcrypt.compare('PasswordLain!', LEGACY_HASH)).resolves.toBe(
      false,
    );
  });

  it('produces verifiable hashes with cost 12', async () => {
    const hash = await bcrypt.hash('Password123!', 12);

    expect(hash.startsWith('$2')).toBe(true);
    expect(bcrypt.getRounds(hash)).toBe(12);
    await expect(bcrypt.compare('Password123!', hash)).resolves.toBe(true);
  });
});
