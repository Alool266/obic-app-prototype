// Made by Dr Ali
// Global AI auto-reply setting (DB) with short cache. Env still gates AI itself.

import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  AI_AUTO_REPLY_GLOBAL_KEY,
  AppSetting,
} from './app-setting.entity';
import { AiConfig } from './ai.config';

const CACHE_TTL_MS = 15_000;

@Injectable()
export class AiSettingsService {
  private readonly logger = new Logger(AiSettingsService.name);
  private cache: { enabled: boolean; at: number } | null = null;

  constructor(
    private readonly cfg: AiConfig,
    @InjectRepository(AppSetting)
    private readonly settings: Repository<AppSetting>,
  ) {}

  /**
   * Effective global auto-reply: AI on + env AI_AUTO_REPLY + DB flag.
   */
  async isGlobalAutoReplyEnabled(): Promise<boolean> {
    if (!this.cfg.autoReplyEnabled) return false;
    return this.readDbFlag();
  }

  /** DB flag only (for Admin UI). Default true when unset. */
  async getGlobalAutoReplyFlag(): Promise<boolean> {
    return this.readDbFlag();
  }

  async setGlobalAutoReplyFlag(enabled: boolean): Promise<boolean> {
    const value = enabled ? 'true' : 'false';
    let row = await this.settings.findOne({
      where: { key: AI_AUTO_REPLY_GLOBAL_KEY },
    });
    if (!row) {
      row = this.settings.create({
        key: AI_AUTO_REPLY_GLOBAL_KEY,
        value,
      });
    } else {
      row.value = value;
    }
    await this.settings.save(row);
    this.cache = { enabled, at: Date.now() };
    this.logger.log(`ai_auto_reply_global enabled=${enabled}`);
    return enabled;
  }

  private async readDbFlag(): Promise<boolean> {
    const now = Date.now();
    if (this.cache && now - this.cache.at < CACHE_TTL_MS) {
      return this.cache.enabled;
    }
    const row = await this.settings.findOne({
      where: { key: AI_AUTO_REPLY_GLOBAL_KEY },
    });
    // Missing row → enabled (migration seeds true).
    const enabled =
      !row ||
      ['1', 'true', 'yes', 'on'].includes(
        String(row.value).trim().toLowerCase(),
      );
    this.cache = { enabled, at: now };
    return enabled;
  }
}
