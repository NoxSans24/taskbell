import { NextFunction, Request, Response } from 'express';

interface Bucket {
  count: number;
  resetAt: number;
}

export interface RateLimitOptions {
  windowMs: number;
  max: number;
  message: string;
  keyGenerator?: (req: Request) => string;
}

const activeBuckets: Array<Map<string, Bucket>> = [];

/// Mengosongkan seluruh penghitung. Dipakai oleh pengujian.
export function resetAllRateLimits(): void {
  for (const buckets of activeBuckets) {
    buckets.clear();
  }
}

export function clientIp(req: Request): string {
  return req.ip ?? req.socket.remoteAddress ?? 'unknown';
}

/// Pembatas laju sederhana berbasis memori (satu instance).
/// Untuk deployment multi-instance, ganti dengan penyimpanan bersama (Redis).
export function createRateLimiter(options: RateLimitOptions) {
  const buckets = new Map<string, Bucket>();
  activeBuckets.push(buckets);

  const cleanup = setInterval(() => {
    const now = Date.now();
    for (const [key, bucket] of buckets) {
      if (bucket.resetAt <= now) buckets.delete(key);
    }
  }, Math.max(options.windowMs, 60_000));

  // Jangan menahan proses tetap hidup hanya karena timer pembersihan.
  cleanup.unref?.();

  return function rateLimiter(
    req: Request,
    res: Response,
    next: NextFunction,
  ) {
    const key = options.keyGenerator
      ? options.keyGenerator(req)
      : clientIp(req);

    const now = Date.now();
    const bucket = buckets.get(key);

    if (!bucket || bucket.resetAt <= now) {
      buckets.set(key, { count: 1, resetAt: now + options.windowMs });
      return next();
    }

    if (bucket.count >= options.max) {
      const retryAfter = Math.max(
        1,
        Math.ceil((bucket.resetAt - now) / 1000),
      );
      res.setHeader('Retry-After', String(retryAfter));
      return res.status(429).json({ error: options.message });
    }

    bucket.count += 1;
    return next();
  };
}
