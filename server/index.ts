import express, {
  NextFunction,
  Request,
  Response,
} from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Prisma, PrismaClient } from '@prisma/client';
import { LoginSchema, MutationSchema, RegisterSchema, TelegramLinkSchema } from './validators';
import { clientIp, createRateLimiter } from './rate_limit';
import { decryptToken, encryptToken, isTokenCipherConfigured } from './token_cipher';
import { runReminderCycle, sendTelegramMessage } from './reminders';

dotenv.config();

(BigInt.prototype as unknown as { toJSON: () => string }).toJSON = function () {
  return this.toString();
};

// Nilai contoh yang ikut ter-commit di .env.example tidak boleh dipakai
// menjalankan server: siapa pun yang membaca repository dapat memakainya
// untuk memalsukan token.
const CONTOH_SECRET_TIDAK_AMAN = new Set([
  'replace_with_a_secure_random_secret_at_least_32_characters_long',
]);

function resolveJwtSecret(raw: string | undefined): string {
  const secret = raw?.trim() ?? '';

  if (secret.length < 48) {
    throw new Error(
      'JWT_SECRET wajib diisi dengan secret acak minimal 48 karakter.',
    );
  }

  if (CONTOH_SECRET_TIDAK_AMAN.has(secret)) {
    throw new Error(
      'JWT_SECRET masih memakai nilai contoh dari .env.example. Ganti dengan secret acak sebelum menjalankan server.',
    );
  }

  if (new Set(secret).size < 12) {
    throw new Error(
      'JWT_SECRET terlalu lemah (variasi karakter rendah). Gunakan secret acak.',
    );
  }

  return secret;
}

/// Kesalahan bisnis yang aman ditampilkan ke klien.
class SyncError extends Error {}

/// Mengalokasikan nomor urut perubahan secara atomik.
///
/// `INSERT ... ON CONFLICT ... RETURNING` membuat PostgreSQL yang menyerialkan
/// penulisan, sehingga dua permintaan paralel tidak mungkin memperoleh nomor
/// yang sama.
async function allocateSequence(
  tx: Prisma.TransactionClient,
  userId: string,
): Promise<bigint> {
  const rows = await tx.$queryRaw<Array<{ sequence: bigint }>>`
    INSERT INTO "UserSyncState" ("userId", "sequence")
    VALUES (${userId}, 1)
    ON CONFLICT ("userId") DO UPDATE
      SET "sequence" = "UserSyncState"."sequence" + 1
    RETURNING "sequence"
  `;

  return rows[0].sequence;
}

function isRetryableSyncError(error: unknown): boolean {
  if (!(error instanceof Prisma.PrismaClientKnownRequestError)) {
    return false;
  }

  if (error.code === 'P2034') {
    return true; // deadlock atau konflik tulis
  }

  if (error.code === 'P2002') {
    const target = error.meta?.target;
    if (Array.isArray(target)) {
      return target.some((item) => String(item).includes('SyncChange'));
    }
    return typeof target === 'string' && target.includes('SyncChange');
  }

  return false;
}

async function withSyncRetry<T>(
  operation: () => Promise<T>,
  attempts = 3,
): Promise<T> {
  let lastError: unknown;

  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;

      if (!isRetryableSyncError(error) || attempt === attempts - 1) {
        throw error;
      }

      await new Promise((resolve) => setTimeout(resolve, 25 * (attempt + 1)));
    }
  }

  throw lastError;
}

const app = express();
const prisma = new PrismaClient();
const JWT_SECRET = resolveJwtSecret(process.env.JWT_SECRET);
const PORT = Number(process.env.PORT || 3000);

// CORS hanya untuk origin yang didaftarkan. Aplikasi mobile tidak mengirim
// header Origin sehingga tetap diizinkan.
const allowedOrigins = (process.env.CORS_ORIGINS ?? '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

const localhostOrigin = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

if (process.env.TRUST_PROXY === '1') {
  app.set('trust proxy', 1);
}

app.use(express.json({ limit: '1mb' }));

app.use((_req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader(
    'Permissions-Policy',
    'camera=(), microphone=(), geolocation=()',
  );
  next();
});

app.use(
  cors({
    origin(origin, callback) {
      if (!origin) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      if (allowedOrigins.length === 0 && localhostOrigin.test(origin)) {
        return callback(null, true);
      }
      return callback(null, false);
    },
    methods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }),
);

const loginLimiter = createRateLimiter({
  windowMs: 15 * 60_000,
  max: 10,
  message: 'Terlalu banyak percobaan masuk. Coba lagi beberapa menit lagi.',
  keyGenerator: (req) =>
    `login:${clientIp(req)}:${String(req.body?.email ?? '').toLowerCase()}`,
});

const registerLimiter = createRateLimiter({
  windowMs: 60 * 60_000,
  max: 20,
  message: 'Terlalu banyak pendaftaran dari perangkat ini. Coba lagi nanti.',
  keyGenerator: (req) => `register:${clientIp(req)}`,
});

interface AuthRequest extends Request {
  userId?: string;
}

function maskChatId(chatId: string): string {
  if (chatId.length <= 4) return '****';
  return `****${chatId.slice(-4)}`;
}

const telegramLimiter = createRateLimiter({
  windowMs: 60 * 60_000,
  max: 10,
  message: 'Terlalu banyak permintaan Telegram. Coba lagi nanti.',
  keyGenerator: (req) =>
    `telegram:${(req as AuthRequest).userId ?? clientIp(req)}`,
});

function authenticate(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Bearer token diperlukan' });
  }

  try {
    const decoded = jwt.verify(auth.slice(7), JWT_SECRET);

    if (
      typeof decoded === 'string' ||
      typeof decoded.userId !== 'string'
    ) {
      return res.status(401).json({ error: 'Token tidak valid' });
    }

    (req as AuthRequest).userId = decoded.userId;
    next();
  } catch {
    return res.status(401).json({ error: 'Token tidak valid atau kedaluwarsa' });
  }
}

function issueToken(userId: string) {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '2h' });
}

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

// Registrasi akun pada database yang dikonfigurasi di DATABASE_URL.
app.post('/auth/register', registerLimiter, async (req, res) => {
  const parsed = RegisterSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: 'Data registrasi tidak valid',
      details: parsed.error.issues,
    });
  }

  const email = parsed.data.email.toLowerCase();

  try {
    const passwordHash = await bcrypt.hash(parsed.data.password, 12);

    const user = await prisma.user.create({
      data: {
        email,
        password: passwordHash,
      },
      select: { id: true, email: true },
    });

    return res.status(201).json({
      user,
      token: issueToken(user.id),
    });
  } catch (error) {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      return res.status(409).json({ error: 'Email sudah terdaftar' });
    }

    console.error('Registration failed');
    return res.status(500).json({ error: 'Registrasi gagal' });
  }
});

// Login
app.post('/auth/login', loginLimiter, async (req, res) => {
  const parsed = LoginSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({ error: 'Data login tidak valid' });
  }

  try {
    const email = parsed.data.email.toLowerCase();
    const user = await prisma.user.findUnique({ where: { email } });

    if (!user || !(await bcrypt.compare(parsed.data.password, user.password))) {
      return res.status(401).json({ error: 'Email atau password salah' });
    }

    return res.json({
      user: { id: user.id, email: user.email },
      token: issueToken(user.id),
    });
  } catch {
    return res.status(500).json({ error: 'Login gagal' });
  }
});

// Dipakai klien untuk memvalidasi sesi tersimpan sebelum menampilkan data.
app.get('/auth/me', authenticate, async (req, res) => {
  const { userId } = req as AuthRequest;

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId! },
      select: { id: true, email: true },
    });

    if (!user) {
      return res.status(401).json({ error: 'Sesi tidak valid' });
    }

    return res.json({ user });
  } catch {
    return res.status(500).json({ error: 'Gagal memuat profil' });
  }
});

// ---- Telegram ----

app.get('/telegram/link', authenticate, async (req, res) => {
  const { userId } = req as AuthRequest;

  try {
    const link = await prisma.telegramLink.findUnique({
      where: { userId: userId! },
    });

    if (!link) {
      return res.json({ connected: false, enabled: false });
    }

    return res.json({
      connected: true,
      enabled: link.enabled,
      chatId: maskChatId(link.chatId),
      lastVerifiedAt: link.lastVerifiedAt,
    });
  } catch {
    return res.status(500).json({ error: 'Gagal memuat status Telegram' });
  }
});

app.put('/telegram/link', authenticate, telegramLimiter, async (req, res) => {
  if (!isTokenCipherConfigured()) {
    return res.status(503).json({
      error: 'Fitur Telegram belum dikonfigurasi di server.',
    });
  }

  const parsed = TelegramLinkSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: 'Data Telegram tidak valid',
      details: parsed.error.issues,
    });
  }

  const { userId } = req as AuthRequest;
  const { botToken, chatId } = parsed.data;

  const test = await sendTelegramMessage({
    botToken,
    chatId,
    text: '✅ TaskBell terhubung. Pengingat tugas akan dikirim ke chat ini.',
  });

  if (!test.ok) {
    const clientError =
      test.status === 400 || test.status === 401 || test.status === 403;

    return res.status(clientError ? 400 : 502).json({
      error: clientError
        ? 'Telegram menolak token atau Chat ID. Periksa kembali.'
        : 'Telegram tidak merespons. Coba lagi nanti.',
    });
  }

  const tokenCipher = encryptToken(botToken);
  const verifiedAt = new Date();

  await prisma.telegramLink.upsert({
    where: { userId: userId! },
    update: { chatId, tokenCipher, enabled: true, lastVerifiedAt: verifiedAt },
    create: {
      userId: userId!,
      chatId,
      tokenCipher,
      enabled: true,
      lastVerifiedAt: verifiedAt,
    },
  });

  return res.json({
    connected: true,
    enabled: true,
    chatId: maskChatId(chatId),
  });
});

app.delete('/telegram/link', authenticate, async (req, res) => {
  const { userId } = req as AuthRequest;

  await prisma.telegramLink
    .deleteMany({ where: { userId: userId! } })
    .catch(() => undefined);

  return res.status(204).send();
});

app.post('/telegram/test', authenticate, telegramLimiter, async (req, res) => {
  const { userId } = req as AuthRequest;

  const link = await prisma.telegramLink.findUnique({
    where: { userId: userId! },
  });

  if (!link || !link.enabled) {
    return res.status(404).json({ error: 'Telegram belum terhubung.' });
  }

  const botToken = decryptToken(link.tokenCipher);
  if (!botToken) {
    return res.status(503).json({
      error: 'Konfigurasi enkripsi Telegram di server tidak tersedia.',
    });
  }

  const result = await sendTelegramMessage({
    botToken,
    chatId: link.chatId,
    text: '🔔 Pesan uji dari TaskBell.',
  });

  if (result.ok) {
    await prisma.telegramLink.update({
      where: { userId: userId! },
      data: { lastVerifiedAt: new Date() },
    });
    return res.json({ ok: true });
  }

  if (result.status === 400 || result.status === 401 || result.status === 403) {
    await prisma.telegramLink.update({
      where: { userId: userId! },
      data: { enabled: false },
    });
    return res.status(400).json({
      error: 'Token bot ditolak Telegram. Hubungkan ulang.',
    });
  }

  return res.status(502).json({ error: 'Telegram tidak merespons. Coba lagi.' });
});

app.post('/sync/push', authenticate, async (req, res) => {
  const authReq = req as AuthRequest;
  const userId = authReq.userId!;

  if (!Array.isArray(req.body)) {
    return res.status(400).json({ error: 'Body harus berupa array mutasi' });
  }

  if (req.body.length > 100) {
    return res.status(413).json({ error: 'Maksimal 100 mutasi per permintaan' });
  }

  const results: Array<Record<string, unknown>> = [];

  for (const raw of req.body) {
    const mutationId =
      raw && typeof raw.clientMutationId === 'string'
        ? raw.clientMutationId
        : null;

    const parsed = MutationSchema.safeParse(raw);

    if (!parsed.success) {
      results.push({
        clientMutationId: mutationId,
        status: 'failed',
        error: 'Payload mutasi tidak valid',
      });
      continue;
    }

    const data = parsed.data;

    try {
      // clientMutationId unik secara global menurut schema Prisma.
      // Jangan menganggap mutasi pengguna lain sebagai keberhasilan.
      const existing = await prisma.mutationLog.findUnique({
        where: { clientMutationId: data.clientMutationId },
      });

      if (existing) {
        results.push({
          clientMutationId: data.clientMutationId,
          status: existing.userId === userId
            ? 'already_processed'
            : 'failed',
          ...(existing.userId !== userId
            ? { error: 'clientMutationId sudah digunakan' }
            : {}),
        });
        continue;
      }

      await withSyncRetry(() => prisma.$transaction(async (tx) => {
        if (data.entityType === 'category') {
          if (data.operation === 'create') {
            await tx.category.create({
              data: {
                name: data.payload.name,
                userId,
                syncId: data.syncId,
              },
            });
          } else {
            const category = await tx.category.findFirst({
              where: { syncId: data.syncId, userId },
            });

            if (!category) throw new SyncError('Kategori tidak ditemukan');

            if (data.operation === 'update') {
              await tx.category.update({
                where: { id: category.id },
                data: { name: data.payload.name },
              });
            } else {
              await tx.category.update({
                where: { id: category.id },
                data: { isDeleted: true },
              });
            }
          }
        } else {
          if (data.operation === 'delete') {
            const task = await tx.task.findFirst({
              where: { syncId: data.syncId, userId },
            });

            if (!task) throw new Error('Task tidak ditemukan');

            await tx.task.update({
              where: { id: task.id },
              data: { isDeleted: true },
            });
          } else {
            const category = await tx.category.findFirst({
              where: {
                syncId: data.payload.categoryId,
                userId,
                isDeleted: false,
              },
            });

            if (!category) {
              throw new SyncError('Kategori belum tersedia di server');
            }

            const taskData = {
              title: data.payload.title,
              description: data.payload.description ?? null,
              priority: data.payload.priority,
              status: data.payload.status,
              dueDate: data.payload.dueDate
                ? new Date(data.payload.dueDate)
                : null,
              categoryId: category.id,
            };

            if (data.operation === 'create') {
              await tx.task.create({
                data: {
                  ...taskData,
                  syncId: data.syncId,
                  userId,
                },
              });
            } else {
              const task = await tx.task.findFirst({
                where: { syncId: data.syncId, userId },
              });

              if (!task) throw new SyncError('Task tidak ditemukan');

              await tx.task.update({
                where: { id: task.id },
                data: taskData,
              });
            }
          }
        }

        const sequence = await allocateSequence(tx, userId);

        await tx.mutationLog.create({
          data: {
            clientMutationId: data.clientMutationId,
            syncId: data.syncId,
            entityType: data.entityType,
            operation: data.operation,
            payload: data.payload as Prisma.InputJsonValue,
            userId,
          },
        });

        await tx.syncChange.create({
          data: {
            userId,
            sequence,
            entityType: data.entityType,
            operation: data.operation,
            syncId: data.syncId,
            payload: data.payload as Prisma.InputJsonValue,
          },
        });
      }));

      results.push({
        clientMutationId: data.clientMutationId,
        status: 'success',
      });
    } catch (error) {
      // Menangani pengiriman ulang yang beradu pada unique constraint.
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const existing = await prisma.mutationLog.findUnique({
          where: { clientMutationId: data.clientMutationId },
        });

        if (existing?.userId === userId) {
          results.push({
            clientMutationId: data.clientMutationId,
            status: 'already_processed',
          });
          continue;
        }
      }

      if (!(error instanceof SyncError)) {
        console.error(
          'Sync mutation failed:',
          error instanceof Error ? error.message : error,
        );
      }

      results.push({
        clientMutationId: data.clientMutationId,
        status: 'failed',
        error: error instanceof SyncError ? error.message : 'Operasi gagal',
      });
    }
  }

  return res.json(results);
});

app.get('/sync/pull', authenticate, async (req, res) => {
  const authReq = req as AuthRequest;
  const userId = authReq.userId!;

  const rawCursor = req.query.cursor;
  if (rawCursor !== undefined && typeof rawCursor !== 'string') {
    return res.status(400).json({ error: 'Cursor tidak valid' });
  }

  let cursor: bigint;
  try {
    cursor = rawCursor && rawCursor !== '0' ? BigInt(rawCursor) : BigInt(0);
  } catch {
    return res.status(400).json({ error: 'Cursor tidak valid' });
  }

  if (cursor < BigInt(0)) {
    return res.status(400).json({ error: 'Cursor tidak valid' });
  }

  try {
    const limit = Math.min(Math.max(Number(req.query.limit) || 50, 1), 100);

    const changes = await prisma.syncChange.findMany({
      where: {
        userId,
        sequence: { gt: cursor },
      },
      orderBy: { sequence: 'asc' },
      take: limit,
    });

    const formattedChanges = changes.map((c) => ({
      sequence: c.sequence.toString(),
      entityType: c.entityType,
      operation: c.operation,
      syncId: c.syncId,
      payload: c.payload,
      createdAt: c.createdAt.toISOString(),
    }));

    const nextCursor =
      formattedChanges.length > 0
        ? formattedChanges[formattedChanges.length - 1].sequence
        : cursor.toString();

    return res.json({
      changes: formattedChanges,
      nextCursor,
    });
  } catch (error) {
    console.error('Pull changes failed:', error);
    return res.status(500).json({ error: 'Gagal menarik perubahan sinkronisasi' });
  }
});

let server: ReturnType<typeof app.listen> | null = null;
let reminderTimer: ReturnType<typeof setInterval> | null = null;

function startReminderScheduler() {
  if (process.env.REMINDERS_ENABLED === '0') return;

  if (!isTokenCipherConfigured()) {
    console.warn(
      'TELEGRAM_TOKEN_KEY belum diatur; pengingat Telegram nonaktif.',
    );
    return;
  }

  reminderTimer = setInterval(() => {
    void runReminderCycle(prisma).catch((error) => {
      console.error(
        'Reminder cycle failed:',
        error instanceof Error ? error.message : error,
      );
    });
  }, 60_000);

  reminderTimer.unref?.();
}

if (process.env.NODE_ENV !== 'test') {
  server = app.listen(PORT, () => {
    console.log(`TaskBell API berjalan di port ${PORT}`);
  });
  startReminderScheduler();
}

async function shutdown() {
  if (reminderTimer) {
    clearInterval(reminderTimer);
    reminderTimer = null;
  }

  if (server) {
    server.close();
  }

  await prisma.$disconnect();
}

process.on('SIGINT', () => void shutdown());
process.on('SIGTERM', () => void shutdown());

export { app, prisma, shutdown };