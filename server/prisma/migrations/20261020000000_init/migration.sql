-- Baseline migrasi TaskBell.
-- Dibuat dari prisma/schema.prisma saat proyek sudah memiliki database
-- development yang dibuat lewat `prisma db push`.
--
-- Untuk database baru: `npm run db:deploy`.
-- Untuk database lama yang sudah sinkron: tandai baseline ini sebagai sudah
-- diterapkan dengan `npx prisma migrate resolve --applied 20261020000000_init`.

-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Task" (
    "id" TEXT NOT NULL,
    "syncId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "categoryId" TEXT NOT NULL,
    "priority" INTEGER NOT NULL,
    "status" INTEGER NOT NULL,
    "dueDate" TIMESTAMP(3),
    "isDeleted" BOOLEAN NOT NULL DEFAULT false,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "Task_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Category" (
    "id" TEXT NOT NULL,
    "syncId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "isDeleted" BOOLEAN NOT NULL DEFAULT false,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "Category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MutationLog" (
    "id" TEXT NOT NULL,
    "clientMutationId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "syncId" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "operation" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MutationLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SyncChange" (
    "id" SERIAL NOT NULL,
    "userId" TEXT NOT NULL,
    "sequence" BIGINT NOT NULL,
    "entityType" TEXT NOT NULL,
    "operation" TEXT NOT NULL,
    "syncId" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SyncChange_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserSyncState" (
    "userId" TEXT NOT NULL,
    "sequence" BIGINT NOT NULL DEFAULT 0,

    CONSTRAINT "UserSyncState_pkey" PRIMARY KEY ("userId")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Task_syncId_key" ON "Task"("syncId");

-- CreateIndex
CREATE UNIQUE INDEX "Category_syncId_key" ON "Category"("syncId");

-- CreateIndex
CREATE UNIQUE INDEX "Category_name_userId_key" ON "Category"("name", "userId");

-- CreateIndex
CREATE UNIQUE INDEX "MutationLog_clientMutationId_key" ON "MutationLog"("clientMutationId");

-- CreateIndex
CREATE INDEX "SyncChange_userId_sequence_idx" ON "SyncChange"("userId", "sequence");

-- CreateIndex
CREATE UNIQUE INDEX "SyncChange_userId_sequence_key" ON "SyncChange"("userId", "sequence");

-- AddForeignKey
ALTER TABLE "Task" ADD CONSTRAINT "Task_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Task" ADD CONSTRAINT "Task_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Category" ADD CONSTRAINT "Category_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MutationLog" ADD CONSTRAINT "MutationLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SyncChange" ADD CONSTRAINT "SyncChange_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserSyncState" ADD CONSTRAINT "UserSyncState_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
