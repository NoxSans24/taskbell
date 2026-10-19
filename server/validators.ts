import { z } from 'zod';

const UuidSchema = z.string().uuid();

const CategoryPayload = z.object({
  name: z.string().trim().min(1).max(100),
});

const TaskPayload = z.object({
  title: z.string().trim().min(1).max(250),
  description: z.string().max(5000).nullable().optional(),
  categoryId: UuidSchema,
  priority: z.number().int().min(0).max(2),
  status: z.number().int().min(0).max(1),
  dueDate: z.string().datetime().nullable().optional(),
});

const BaseMutation = z.object({
  clientMutationId: UuidSchema,
  syncId: UuidSchema,
});

export const MutationSchema = z.union([
  BaseMutation.extend({
    entityType: z.literal('category'),
    operation: z.literal('create'),
    payload: CategoryPayload,
  }),
  BaseMutation.extend({
    entityType: z.literal('category'),
    operation: z.literal('update'),
    payload: CategoryPayload,
  }),
  BaseMutation.extend({
    entityType: z.literal('category'),
    operation: z.literal('delete'),
    payload: z.record(z.unknown()),
  }),
  BaseMutation.extend({
    entityType: z.literal('task'),
    operation: z.literal('create'),
    payload: TaskPayload,
  }),
  BaseMutation.extend({
    entityType: z.literal('task'),
    operation: z.literal('update'),
    payload: TaskPayload,
  }),
  BaseMutation.extend({
    entityType: z.literal('task'),
    operation: z.literal('delete'),
    payload: z.record(z.unknown()),
  }),
]);

export const RegisterSchema = z.object({
  email: z.string().trim().email().max(254),
  password: z.string().min(8).max(72),
});

export const LoginSchema = z.object({
  email: z.string().trim().email().max(254),
  password: z.string().min(1).max(72),
});

export const TelegramLinkSchema = z.object({
  botToken: z
    .string()
    .trim()
    .regex(/^\d{6,12}:[A-Za-z0-9_-]{30,64}$/, 'Format token bot tidak valid'),
  chatId: z
    .string()
    .trim()
    .regex(/^-?\d{3,20}$/, 'Format Chat ID tidak valid'),
});