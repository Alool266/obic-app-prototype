// Made by Dr Ali
// Optional Redis client — connect when configured; never crash local API if Redis is down.

import {
  Injectable,
  Logger,
  OnModuleDestroy,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

export type RedisStatus = 'up' | 'down' | 'skipped';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis | null = null;
  private status: RedisStatus = 'skipped';

  constructor(private readonly config: ConfigService) {}

  /** Call once during module bootstrap (before throttler wires storage). */
  async connect(): Promise<void> {
    const url = this.config.get<string>('REDIS_URL')?.trim();
    const host = this.config.get<string>('REDIS_HOST')?.trim();
    if (!url && !host) {
      this.status = 'skipped';
      this.logger.log(
        'Redis not configured (REDIS_URL / REDIS_HOST unset) — rate limits stay in-memory; health reports skipped',
      );
      return;
    }

    const port = Number(this.config.get<string>('REDIS_PORT') ?? 6379);
    const opts = {
      maxRetriesPerRequest: 1,
      enableReadyCheck: true,
      lazyConnect: true,
      // Fail fast in local/staging when Redis is briefly down.
      connectTimeout: 3_000,
      retryStrategy: () => null,
    } as const;

    const redis = url
      ? new Redis(url, opts)
      : new Redis({ host: host!, port, ...opts });

    redis.on('error', (err) => {
      // Avoid unhandled error spam; status refreshed via ping/health.
      this.logger.debug(`Redis error: ${err.message}`);
    });

    try {
      await redis.connect();
      const pong = await redis.ping();
      if (pong !== 'PONG') {
        throw new Error(`unexpected PING reply: ${pong}`);
      }
      this.client = redis;
      this.status = 'up';
      this.logger.log('Redis connected — used for rate-limit store + services cache');
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.warn(
        `Redis unavailable (${msg}) — continuing without Redis (in-memory throttle, no list cache)`,
      );
      this.status = 'down';
      try {
        redis.disconnect();
      } catch {
        /* ignore */
      }
      this.client = null;
    }
  }

  getStatus(): RedisStatus {
    return this.status;
  }

  isReady(): boolean {
    return this.status === 'up' && this.client != null;
  }

  /** Shared ioredis client when up; otherwise null. */
  getClient(): Redis | null {
    return this.client;
  }

  async ping(): Promise<RedisStatus> {
    if (this.status === 'skipped') return 'skipped';
    if (!this.client) {
      this.status = 'down';
      return 'down';
    }
    try {
      const pong = await this.client.ping();
      this.status = pong === 'PONG' ? 'up' : 'down';
    } catch {
      this.status = 'down';
    }
    return this.status;
  }

  async getJson<T>(key: string): Promise<T | null> {
    if (!this.isReady() || !this.client) return null;
    try {
      const raw = await this.client.get(key);
      if (!raw) return null;
      return JSON.parse(raw) as T;
    } catch {
      return null;
    }
  }

  async setJson(key: string, value: unknown, ttlSeconds: number): Promise<void> {
    if (!this.isReady() || !this.client) return;
    try {
      await this.client.set(key, JSON.stringify(value), 'EX', ttlSeconds);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.debug(`Redis setJson failed: ${msg}`);
    }
  }

  async del(key: string): Promise<void> {
    if (!this.isReady() || !this.client) return;
    try {
      await this.client.del(key);
    } catch {
      /* ignore */
    }
  }

  /** Delete keys matching a glob-style pattern (e.g. `obic:v1:services:active:*`). */
  async delByPattern(pattern: string): Promise<void> {
    if (!this.isReady() || !this.client) return;
    try {
      let cursor = '0';
      do {
        const [next, keys] = await this.client.scan(
          cursor,
          'MATCH',
          pattern,
          'COUNT',
          100,
        );
        cursor = next;
        if (keys.length > 0) await this.client.del(...keys);
      } while (cursor !== '0');
    } catch {
      /* ignore */
    }
  }

  async onModuleDestroy() {
    if (this.client) {
      try {
        await this.client.quit();
      } catch {
        this.client.disconnect();
      }
      this.client = null;
    }
  }
}
