// Made by Dr Ali
// Liveness / readiness — no auth; safe for load balancers.

import { Controller, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource } from 'typeorm';
import { RedisService } from '../redis/redis.service';

@Controller('health')
export class HealthController {
  constructor(
    private readonly dataSource: DataSource,
    private readonly config: ConfigService,
    private readonly redis: RedisService,
  ) {}

  @Get()
  async check() {
    let database: 'up' | 'down' = 'down';
    try {
      if (this.dataSource.isInitialized) {
        await this.dataSource.query('SELECT 1');
        database = 'up';
      }
    } catch {
      database = 'down';
    }

    const redis = await this.redis.ping();

    const aiRaw = String(this.config.get<string>('AI_ENABLED') ?? '')
      .trim()
      .toLowerCase();
    const aiFlag =
      aiRaw === 'true' || aiRaw === '1' || aiRaw === 'yes' || aiRaw === 'on';
    const provider = (
      this.config.get<string>('AI_PROVIDER') ?? 'groq'
    )
      .trim()
      .toLowerCase();
    const hasAiKey = Boolean(
      (
        this.config.get<string>('AI_API_KEY') ??
        this.config.get<string>('GROQ_API_KEY') ??
        this.config.get<string>('GEMINI_API_KEY') ??
        this.config.get<string>('OPENROUTER_API_KEY') ??
        this.config.get<string>('OPENAI_API_KEY') ??
        ''
      ).trim(),
    );

    return {
      status: database === 'up' ? 'ok' : 'degraded',
      service: 'obic-api',
      database,
      redis,
      // Confirm env is loaded without leaking secrets.
      hasJwtSecret: Boolean(this.config.get<string>('JWT_SECRET')),
      /** Phase 5 — AI on only when flag + key; never expose the key. */
      ai: aiFlag && hasAiKey ? 'on' : 'off',
      aiProvider: aiFlag && hasAiKey ? provider || 'groq' : null,
      /** Phase 5 — Agora voice/video when App ID + certificate set (never expose cert). */
      agora:
        Boolean((this.config.get<string>('AGORA_APP_ID') ?? '').trim()) &&
        Boolean(
          (this.config.get<string>('AGORA_APP_CERTIFICATE') ?? '').trim(),
        )
          ? 'on'
          : 'off',
      /** Socket.IO /realtime namespace — authenticated push for chat + badges. */
      realtime: 'on',
      credit: 'Made by Dr Ali',
    };
  }
}
