import request from 'supertest';
import jwt from 'jsonwebtoken';
import { app, prisma, shutdown } from '../index';
import { resetAllRateLimits } from '../rate_limit';
import { runReminderCycle } from '../reminders';
import { encryptToken } from '../token_cipher';
import crypto from 'crypto';

jest.setTimeout(30000);

describe('TaskBell Server API Suite', () => {
  const testRunId = crypto.randomUUID().slice(0, 8);
  const testEmail = `testuser_${testRunId}@example.com`;
  const testPassword = 'Password123!';
  let authToken = '';
  let testUserId = '';
  const categorySyncId = crypto.randomUUID();
  const taskSyncId = crypto.randomUUID();

  beforeAll(() => {
    resetAllRateLimits();
  });

  afterAll(async () => {
    // Bersihkan data test jika user sempat dibuat
    try {
      const user = await prisma.user.findUnique({ where: { email: testEmail } });
      if (user) {
        await prisma.syncChange.deleteMany({ where: { userId: user.id } });
        await prisma.mutationLog.deleteMany({ where: { userId: user.id } });
        await prisma.task.deleteMany({ where: { userId: user.id } });
        await prisma.category.deleteMany({ where: { userId: user.id } });
        await prisma.userSyncState.deleteMany({ where: { userId: user.id } });
        await prisma.user.delete({ where: { id: user.id } });
      }
    } catch {
      // ignore cleanup errors
    }
    await shutdown();
  });

  describe('Health Check', () => {
    it('should return status ok on GET /health', async () => {
      const res = await request(app).get('/health');
      expect(res.status).toBe(200);
      expect(res.body).toEqual({ status: 'ok' });
    });
  });

  describe('Authentication & Registration', () => {
    it('should reject invalid registration payload', async () => {
      const res = await request(app)
        .post('/auth/register')
        .send({ email: 'not-an-email', password: '123' });
      expect(res.status).toBe(400);
      expect(res.body.error).toBe('Data registrasi tidak valid');
    });

    it('should successfully register a new user', async () => {
      const res = await request(app)
        .post('/auth/register')
        .send({ email: testEmail, password: testPassword });
      expect(res.status).toBe(201);
      expect(res.body.user).toBeDefined();
      expect(res.body.user.email).toBe(testEmail);
      expect(res.body.token).toBeDefined();
      authToken = res.body.token;
      testUserId = res.body.user.id;
    });

    it('should reject duplicate registration with same email', async () => {
      const res = await request(app)
        .post('/auth/register')
        .send({ email: testEmail, password: testPassword });
      expect(res.status).toBe(409);
      expect(res.body.error).toBe('Email sudah terdaftar');
    });

    it('should reject login with wrong password', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: testEmail, password: 'WrongPassword999' });
      expect(res.status).toBe(401);
      expect(res.body.error).toBe('Email atau password salah');
    });

    it('should login successfully and return JWT token', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: testEmail, password: testPassword });
      expect(res.status).toBe(200);
      expect(res.body.token).toBeDefined();
      authToken = res.body.token;
    });

    it('should return the authenticated profile on GET /auth/me', async () => {
      const res = await request(app)
        .get('/auth/me')
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.status).toBe(200);
      expect(res.body.user.email).toBe(testEmail);
      expect(res.body.user.password).toBeUndefined();
    });

    it('should reject GET /auth/me without a token', async () => {
      const res = await request(app).get('/auth/me');
      expect(res.status).toBe(401);
    });

    it('should reject a token forged with the example secret', async () => {
      const forged = jwt.sign(
        { userId: crypto.randomUUID() },
        'replace_with_a_secure_random_secret_at_least_32_characters_long',
      );
      const res = await request(app)
        .get('/sync/pull')
        .set('Authorization', `Bearer ${forged}`);
      expect(res.status).toBe(401);
    });
  });

  describe('Auth Middleware Protection', () => {
    it('should reject request without bearer token', async () => {
      const res = await request(app).post('/sync/push').send([]);
      expect(res.status).toBe(401);
      expect(res.body.error).toBe('Bearer token diperlukan');
    });

    it('should reject request with invalid bearer token', async () => {
      const res = await request(app)
        .post('/sync/push')
        .set('Authorization', 'Bearer invalid_token_value')
        .send([]);
      expect(res.status).toBe(401);
    });
  });

  describe('Sync Push & Pull Workflows', () => {
    it('should reject non-array payload on POST /sync/push', async () => {
      const res = await request(app)
        .post('/sync/push')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ clientMutationId: crypto.randomUUID() });
      expect(res.status).toBe(400);
      expect(res.body.error).toBe('Body harus berupa array mutasi');
    });

    it('should push a category create mutation successfully', async () => {
      const categoryMutationId = crypto.randomUUID();
      const res = await request(app)
        .post('/sync/push')
        .set('Authorization', `Bearer ${authToken}`)
        .send([
          {
            clientMutationId: categoryMutationId,
            syncId: categorySyncId,
            entityType: 'category',
            operation: 'create',
            payload: { name: `Kuliah ${testRunId}` },
          },
        ]);

      expect(res.status).toBe(200);
      expect(res.body).toHaveLength(1);
      expect(res.body[0].clientMutationId).toBe(categoryMutationId);
      expect(res.body[0].status).toBe('success');
    });

    it('should handle idempotency on duplicate mutation', async () => {
      const duplicateMutationId = crypto.randomUUID();
      const payload = [
        {
          clientMutationId: duplicateMutationId,
          syncId: crypto.randomUUID(),
          entityType: 'category',
          operation: 'create',
          payload: { name: `Work ${testRunId}` },
        },
      ];

      // Kirim pertama
      const res1 = await request(app)
        .post('/sync/push')
        .set('Authorization', `Bearer ${authToken}`)
        .send(payload);
      expect(res1.body[0].status).toBe('success');

      // Kirim kedua (duplikasi)
      const res2 = await request(app)
        .post('/sync/push')
        .set('Authorization', `Bearer ${authToken}`)
        .send(payload);
      expect(res2.body[0].status).toBe('already_processed');
    });

    it('should push a task create mutation successfully', async () => {
      const taskMutationId = crypto.randomUUID();
      const res = await request(app)
        .post('/sync/push')
        .set('Authorization', `Bearer ${authToken}`)
        .send([
          {
            clientMutationId: taskMutationId,
            syncId: taskSyncId,
            entityType: 'task',
            operation: 'create',
            payload: {
              title: 'Mengerjakan Laporan Akhir',
              description: 'Detail tugas pengujian otomatis',
              categoryId: categorySyncId,
              priority: 2,
              status: 0,
              dueDate: new Date(Date.now() + 86400000).toISOString(),
            },
          },
        ]);

      expect(res.status).toBe(200);
      expect(res.body).toHaveLength(1);
      expect(res.body[0].status).toBe('success');
    });

    it('should pull changes and return cursor on GET /sync/pull', async () => {
      const res = await request(app)
        .get('/sync/pull?cursor=0&limit=50')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.changes).toBeDefined();
      expect(Array.isArray(res.body.changes)).toBe(true);
      expect(res.body.changes.length).toBeGreaterThanOrEqual(2);
      expect(res.body.nextCursor).toBeDefined();

      // Pastikan struktur item sesuai kontrak
      const firstChange = res.body.changes[0];
      expect(firstChange.sequence).toBeDefined();
      expect(firstChange.entityType).toBeDefined();
      expect(firstChange.operation).toBeDefined();
      expect(firstChange.syncId).toBeDefined();
    });

    it('should reject a non-numeric cursor with 400', async () => {
      const res = await request(app)
        .get('/sync/pull?cursor=abc')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(400);
      expect(res.body.error).toBe('Cursor tidak valid');
    });

    it('should reject a negative cursor with 400', async () => {
      const res = await request(app)
        .get('/sync/pull?cursor=-5')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(400);
      expect(res.body.error).toBe('Cursor tidak valid');
    });
  });

  describe('Transport & Abuse Protection', () => {
    it('should not grant CORS to unknown origins', async () => {
      const res = await request(app)
        .get('/health')
        .set('Origin', 'https://evil.example');

      expect(res.headers['access-control-allow-origin']).toBeUndefined();
    });

    it('should grant CORS to localhost during development', async () => {
      const res = await request(app)
        .get('/health')
        .set('Origin', 'http://localhost:5173');

      expect(res.headers['access-control-allow-origin']).toBe(
        'http://localhost:5173',
      );
    });

    it('should set basic security headers', async () => {
      const res = await request(app).get('/health');

      expect(res.headers['x-content-type-options']).toBe('nosniff');
      expect(res.headers['x-frame-options']).toBe('DENY');
    });

    it('should rate limit repeated failed logins', async () => {
      const statuses: number[] = [];

      for (let i = 0; i < 14; i += 1) {
        const res = await request(app)
          .post('/auth/login')
          .send({ email: testEmail, password: `wrong-${i}` });
        statuses.push(res.status);
      }

      expect(statuses).toContain(429);

      const limited = await request(app)
        .post('/auth/login')
        .send({ email: testEmail, password: testPassword });

      expect(limited.status).toBe(429);
      expect(limited.headers['retry-after']).toBeDefined();
    });
  });

  describe('Concurrent Sync', () => {
    it('assigns unique sequence numbers for parallel pushes', async () => {
      const total = 8;
      const requests = Array.from({ length: total }, (_, index) =>
        request(app)
          .post('/sync/push')
          .set('Authorization', `Bearer ${authToken}`)
          .send([
            {
              clientMutationId: crypto.randomUUID(),
              syncId: crypto.randomUUID(),
              entityType: 'category',
              operation: 'create',
              payload: { name: `Paralel ${index} ${testRunId}` },
            },
          ]),
      );

      const responses = await Promise.all(requests);

      expect(responses.every((res) => res.status === 200)).toBe(true);

      const statuses = responses.flatMap((res) =>
        (res.body as Array<{ status: string }>).map((item) => item.status),
      );
      expect(statuses).toHaveLength(total);
      expect(statuses.every((status) => status === 'success')).toBe(true);

      const pull = await request(app)
        .get('/sync/pull?cursor=0&limit=100')
        .set('Authorization', `Bearer ${authToken}`);

      const sequences = (pull.body.changes as Array<{ sequence: string }>).map(
        (change) => change.sequence,
      );

      expect(new Set(sequences).size).toBe(sequences.length);
      expect(sequences.length).toBeGreaterThanOrEqual(total);
    }, 30000);

    it('processes the same mutation id idempotently when sent twice', async () => {
      const clientMutationId = crypto.randomUUID();
      const syncId = crypto.randomUUID();
      const payload = [
        {
          clientMutationId,
          syncId,
          entityType: 'category',
          operation: 'create',
          payload: { name: `Idempoten ${testRunId}` },
        },
      ];

      const send = () =>
        request(app)
          .post('/sync/push')
          .set('Authorization', `Bearer ${authToken}`)
          .send(payload);

      const [first, second] = await Promise.all([send(), send()]);
      const statuses = [
        ...(first.body as Array<{ status: string }>),
        ...(second.body as Array<{ status: string }>),
      ].map((item) => item.status);

      expect(statuses.filter((status) => status === 'success')).toHaveLength(1);

      const pull = await request(app)
        .get('/sync/pull?cursor=0&limit=100')
        .set('Authorization', `Bearer ${authToken}`);

      const matches = (pull.body.changes as Array<{ syncId: string }>).filter(
        (change) => change.syncId === syncId,
      );

      expect(matches).toHaveLength(1);
    }, 30000);
  });

  describe('Telegram Reminders', () => {
    const dueDate = new Date();
    const reminderSyncId = crypto.randomUUID();

    beforeAll(async () => {
      await prisma.telegramLink.upsert({
        where: { userId: testUserId },
        update: {
          chatId: '123456789',
          tokenCipher: encryptToken(
            '123456789:ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghi',
          ),
          enabled: true,
        },
        create: {
          userId: testUserId,
          chatId: '123456789',
          tokenCipher: encryptToken(
            '123456789:ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghi',
          ),
          enabled: true,
        },
      });

      const res = await request(app)
        .post('/sync/push')
        .set('Authorization', `Bearer ${authToken}`)
        .send([
          {
            clientMutationId: crypto.randomUUID(),
            syncId: reminderSyncId,
            entityType: 'task',
            operation: 'create',
            payload: {
              title: 'Tugas pengingat',
              description: null,
              categoryId: categorySyncId,
              priority: 1,
              status: 0,
              dueDate: dueDate.toISOString(),
            },
          },
        ]);

      expect(res.body[0].status).toBe('success');
    });

    afterAll(async () => {
      await prisma.reminderDelivery.deleteMany({
        where: { userId: testUserId },
      });
      await prisma.telegramLink.deleteMany({ where: { userId: testUserId } });
      await prisma.syncChange.deleteMany({ where: { syncId: reminderSyncId } });
      await prisma.mutationLog.deleteMany({
        where: { syncId: reminderSyncId },
      });
      await prisma.task.deleteMany({ where: { syncId: reminderSyncId } });
    });

    it('sends a reminder once and records the delivery', async () => {
      const send = jest.fn().mockResolvedValue({ ok: true });

      const first = await runReminderCycle(prisma, { now: dueDate, send });

      expect(first.sent).toBe(1);
      expect(send).toHaveBeenCalledTimes(1);
      expect(send).toHaveBeenCalledWith(
        expect.objectContaining({
          chatId: '123456789',
          text: expect.stringContaining('Tugas pengingat'),
        }),
      );

      const second = await runReminderCycle(prisma, { now: dueDate, send });

      expect(second.sent).toBe(0);
      expect(second.skipped).toBeGreaterThanOrEqual(1);
      expect(send).toHaveBeenCalledTimes(1);

      const deliveries = await prisma.reminderDelivery.count({
        where: { userId: testUserId, taskSyncId: reminderSyncId },
      });
      expect(deliveries).toBe(1);
    });

    it('does not record a delivery when sending fails', async () => {
      await prisma.reminderDelivery.deleteMany({
        where: { userId: testUserId },
      });

      const failing = jest
        .fn()
        .mockResolvedValue({ ok: false, status: 500, retryable: true });

      const result = await runReminderCycle(prisma, {
        now: dueDate,
        send: failing,
      });

      expect(result.failed).toBe(1);

      const deliveries = await prisma.reminderDelivery.count({
        where: { userId: testUserId, taskSyncId: reminderSyncId },
      });
      expect(deliveries).toBe(0);

      const retry = await runReminderCycle(prisma, {
        now: dueDate,
        send: jest.fn().mockResolvedValue({ ok: true }),
      });
      expect(retry.sent).toBe(1);
    });

    it('rejects malformed Telegram credentials', async () => {
      const res = await request(app)
        .put('/telegram/link')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ botToken: 'bukan-token', chatId: 'abc' });

      expect(res.status).toBe(400);
      expect(res.body.error).toBe('Data Telegram tidak valid');
    });

    it('reports the linked chat with a masked id', async () => {
      const res = await request(app)
        .get('/telegram/link')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.connected).toBe(true);
      expect(res.body.chatId).toMatch(/^\*{4}\d{4}$/);
    });
  });
});
