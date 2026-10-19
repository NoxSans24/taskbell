-- Tautan Telegram dan riwayat pengiriman pengingat.

-- CreateTable
CREATE TABLE "TelegramLink" (
    "userId" TEXT NOT NULL,
    "chatId" TEXT NOT NULL,
    "tokenCipher" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "lastVerifiedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TelegramLink_pkey" PRIMARY KEY ("userId")
);

-- CreateTable
CREATE TABLE "ReminderDelivery" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "taskSyncId" TEXT NOT NULL,
    "dueAt" TIMESTAMP(3) NOT NULL,
    "sentAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" TEXT NOT NULL,

    CONSTRAINT "ReminderDelivery_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ReminderDelivery_userId_taskSyncId_dueAt_key" ON "ReminderDelivery"("userId", "taskSyncId", "dueAt");

-- CreateIndex
CREATE INDEX "ReminderDelivery_userId_sentAt_idx" ON "ReminderDelivery"("userId", "sentAt");

-- AddForeignKey
ALTER TABLE "TelegramLink" ADD CONSTRAINT "TelegramLink_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReminderDelivery" ADD CONSTRAINT "ReminderDelivery_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
