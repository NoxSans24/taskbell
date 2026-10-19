import { PrismaClient } from '@prisma/client';
import { decryptToken } from './token_cipher';

const CATCH_UP_MS = 10 * 60 * 1000;
const LOOK_AHEAD_MS = 60 * 1000;
const MAX_PER_USER_PER_RUN = 10;

export interface TelegramSendInput {
  botToken: string;
  chatId: string;
  text: string;
}

export interface TelegramSendResult {
  ok: boolean;
  status?: number;
  retryable?: boolean;
}

export type TelegramSender = (
  input: TelegramSendInput,
) => Promise<TelegramSendResult>;

export async function sendTelegramMessage(
  input: TelegramSendInput,
): Promise<TelegramSendResult> {
  try {
    const response = await fetch(
      `https://api.telegram.org/bot${input.botToken}/sendMessage`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chat_id: input.chatId,
          text: input.text,
          disable_web_page_preview: true,
        }),
        signal: AbortSignal.timeout(10_000),
      },
    );

    return {
      ok: response.ok,
      status: response.status,
      retryable: response.status === 429 || response.status >= 500,
    };
  } catch {
    return { ok: false, retryable: true };
  }
}

export interface ReminderCycleResult {
  sent: number;
  failed: number;
  skipped: number;
}

/// Mengirim pengingat untuk tugas yang tenggatnya jatuh pada jendela waktu
/// saat ini. Pengiriman yang gagal karena gangguan sementara tidak dicatat,
/// sehingga dicoba lagi pada siklus berikutnya. Kegagalan autentikasi
/// menonaktifkan tautan agar tidak mencoba terus-menerus.
export async function runReminderCycle(
  prisma: PrismaClient,
  options: {
    now?: Date;
    send?: TelegramSender;
    maxPerUser?: number;
  } = {},
): Promise<ReminderCycleResult> {
  const now = options.now ?? new Date();
  const send = options.send ?? sendTelegramMessage;
  const maxPerUser = options.maxPerUser ?? MAX_PER_USER_PER_RUN;

  const windowStart = new Date(now.getTime() - CATCH_UP_MS);
  const windowEnd = new Date(now.getTime() + LOOK_AHEAD_MS);

  const links = await prisma.telegramLink.findMany({
    where: { enabled: true },
  });

  let sent = 0;
  let failed = 0;
  let skipped = 0;

  for (const link of links) {
    const botToken = decryptToken(link.tokenCipher);
    if (!botToken) {
      skipped += 1;
      continue;
    }

    const tasks = await prisma.task.findMany({
      where: {
        userId: link.userId,
        isDeleted: false,
        status: 0,
        dueDate: { gte: windowStart, lte: windowEnd },
      },
      orderBy: { dueDate: 'asc' },
      take: maxPerUser,
    });

    for (const task of tasks) {
      const dueAt = task.dueDate;
      if (!dueAt) continue;

      const alreadySent = await prisma.reminderDelivery.findUnique({
        where: {
          userId_taskSyncId_dueAt: {
            userId: link.userId,
            taskSyncId: task.syncId,
            dueAt,
          },
        },
      });

      if (alreadySent) {
        skipped += 1;
        continue;
      }

      const result = await send({
        botToken,
        chatId: link.chatId,
        text: `⏰ Pengingat TaskBell: ${task.title}`,
      });

      if (result.ok) {
        try {
          await prisma.reminderDelivery.create({
            data: {
              userId: link.userId,
              taskSyncId: task.syncId,
              dueAt,
              status: 'sent',
            },
          });
        } catch {
          // Pengiriman paralel dapat membuat baris yang sama; abaikan.
        }
        sent += 1;
        continue;
      }

      failed += 1;

      if (result.status === 401 || result.status === 403) {
        await prisma.telegramLink
          .update({
            where: { userId: link.userId },
            data: { enabled: false },
          })
          .catch(() => undefined);
        break;
      }
    }
  }

  return { sent, failed, skipped };
}
