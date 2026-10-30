// Made by Dr Ali
// Phase 5 AI feature flags — free-tier providers (Groq default); secrets from env only.

import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export type AiProvider =
  'groq' | 'gemini' | 'openai' | 'openrouter' | 'deepseek';

/** Vision and file-turn model. Same id for text and images (no separate vision SKU). */
export const DEEPSEEK_FLASH_MODEL = 'deepseek-flash';

const PROVIDER_DEFAULTS: Record<
  AiProvider,
  { baseUrl: string; model: string }
> = {
  // Free tier, OpenAI-compatible — https://console.groq.com/keys
  // qwen/qwen3.8-27b is currently the snappiest chat model on free Groq keys
  // (gpt-oss-20b works but is slower; llama-3.3 may be unavailable on some keys).
  groq: {
    baseUrl: 'https://api.groq.com/openai/v1',
    model: 'qwen/qwen3.8-27b',
  },
  // Free tier via AI Studio — OpenAI-compatible endpoint
  gemini: {
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    model: 'gemini-2.0-flash',
  },
  openai: {
    baseUrl: 'https://api.openai.com/v1',
    model: 'gpt-4o-mini',
  },
  openrouter: {
    baseUrl: 'https://openrouter.ai/api/v1',
    model: 'google/gemma-2-9b-it:free',
  },
  // https://api-docs.deepseek.com — vision uses this same model.
  deepseek: {
    baseUrl: 'https://api.deepseek.com',
    model: DEEPSEEK_FLASH_MODEL,
  },
};

@Injectable()
export class AiConfig {
  constructor(private readonly config: ConfigService) {}

  /** Explicit flag — trial/staging can leave unset/false until a key is ready. */
  get flagEnabled(): boolean {
    return this.truthy(this.config.get<string>('AI_ENABLED'));
  }

  /**
   * Provider: groq (default free) | gemini | openai | openrouter | deepseek.
   * All use OpenAI-compatible /chat/completions except we keep one client path.
   * Photo and file turns use DeepSeek even when text stays on another provider.
   */
  get provider(): AiProvider {
    const raw = (this.config.get<string>('AI_PROVIDER') ?? 'groq')
      .trim()
      .toLowerCase();
    if (raw === 'gemini' || raw === 'google') return 'gemini';
    if (raw === 'openai') return 'openai';
    if (raw === 'openrouter') return 'openrouter';
    if (raw === 'deepseek') return 'deepseek';
    return 'groq';
  }

  /**
   * Unified key: AI_API_KEY, else provider-specific, else legacy OPENAI_API_KEY.
   */
  /** Groq key for Whisper and image reading, even if chat uses another provider. */
  get groqApiKey(): string {
    const dedicated = (this.config.get<string>('GROQ_API_KEY') ?? '').trim();
    if (dedicated) return dedicated;
    if (this.provider === 'groq') return this.apiKey;
    return '';
  }

  get apiKey(): string {
    const unified = (this.config.get<string>('AI_API_KEY') ?? '').trim();
    if (unified) return unified;

    switch (this.provider) {
      case 'groq':
        return (
          this.config.get<string>('GROQ_API_KEY') ??
          this.config.get<string>('OPENAI_API_KEY') ??
          ''
        ).trim();
      case 'gemini':
        return (
          this.config.get<string>('GEMINI_API_KEY') ??
          this.config.get<string>('GOOGLE_API_KEY') ??
          this.config.get<string>('OPENAI_API_KEY') ??
          ''
        ).trim();
      case 'openrouter':
        return (
          this.config.get<string>('OPENROUTER_API_KEY') ??
          this.config.get<string>('OPENAI_API_KEY') ??
          ''
        ).trim();
      case 'openai':
        return (this.config.get<string>('OPENAI_API_KEY') ?? '').trim();
      case 'deepseek':
        return (
          this.config.get<string>('DEEPSEEK_API_KEY') ??
          this.config.get<string>('OPENAI_API_KEY') ??
          ''
        ).trim();
      default: {
        const _exhaustive: never = this.provider;
        return _exhaustive;
      }
    }
  }

  /**
   * Key for photo, file, and support auto-reply turns.
   * Text-only assistant chat keeps using [apiKey] unless AI_PROVIDER is already deepseek.
   */
  get deepseekApiKey(): string {
    const dedicated = (
      this.config.get<string>('DEEPSEEK_API_KEY') ?? ''
    ).trim();
    if (dedicated) return dedicated;
    if (this.provider === 'deepseek') return this.apiKey;
    return '';
  }

  get hasDeepseekKey(): boolean {
    return this.deepseekApiKey.length > 0;
  }

  /**
   * Photo, file, and auto-reply model.
   * Defaults to deepseek-flash. Set DEEPSEEK_MODEL to a vision model on another host.
   */
  get deepseekVisionModel(): string {
    const explicit = (this.config.get<string>('DEEPSEEK_MODEL') ?? '').trim();
    if (explicit) return explicit;
    return DEEPSEEK_FLASH_MODEL;
  }

  get deepseekBaseUrl(): string {
    const dedicated = (
      this.config.get<string>('DEEPSEEK_BASE_URL') ?? ''
    ).trim();
    if (dedicated) return dedicated.replace(/\/$/, '');
    if (this.provider === 'deepseek') return this.baseUrl;
    return PROVIDER_DEFAULTS.deepseek.baseUrl;
  }

  get hasApiKey(): boolean {
    return this.apiKey.length > 0;
  }

  /**
   * AI is live only when both the feature flag and a server-side key are set.
   * Never enable from Flutter / client flags alone.
   */
  get enabled(): boolean {
    return this.flagEnabled && this.hasApiKey;
  }

  /** Auto-reply in support/order chat — on when AI is on unless explicitly disabled. */
  get autoReplyEnabled(): boolean {
    if (!this.enabled) return false;
    const raw = this.config.get<string>('AI_AUTO_REPLY');
    if (raw === undefined || raw === null || String(raw).trim() === '') {
      return true;
    }
    return this.truthy(raw);
  }

  get model(): string {
    const explicit = (
      this.config.get<string>('AI_MODEL') ??
      this.config.get<string>('OPENAI_MODEL') ??
      ''
    ).trim();
    if (explicit) return explicit;
    return PROVIDER_DEFAULTS[this.provider].model;
  }

  get baseUrl(): string {
    const u = (
      this.config.get<string>('AI_BASE_URL') ??
      this.config.get<string>('OPENAI_BASE_URL') ??
      ''
    ).trim();
    if (u) return u.replace(/\/$/, '');
    return PROVIDER_DEFAULTS[this.provider].baseUrl;
  }

  /** Max assistant turns per user per rolling minute. */
  get rateLimitPerMinute(): number {
    const n = Number(this.config.get<string>('AI_RATE_LIMIT_PER_MIN') ?? '12');
    return Number.isFinite(n) && n > 0 ? Math.min(n, 60) : 12;
  }

  /** Max completion tokens for assistant replies. */
  get maxTokens(): number {
    const n = Number(this.config.get<string>('AI_MAX_TOKENS') ?? '4096');
    return Number.isFinite(n) && n > 0 ? Math.min(n, 8192) : 4096;
  }

  /** Shorter cap for support/order auto-replies. */
  get autoReplyMaxTokens(): number {
    const n = Number(
      this.config.get<string>('AI_AUTO_REPLY_MAX_TOKENS') ?? '220',
    );
    return Number.isFinite(n) && n > 0 ? Math.min(n, 800) : 220;
  }

  /** Cap for WeChat-style message translation. */
  get translateMaxTokens(): number {
    const n = Number(
      this.config.get<string>('AI_TRANSLATE_MAX_TOKENS') ?? '800',
    );
    return Number.isFinite(n) && n > 0 ? Math.min(n, 2000) : 800;
  }

  private truthy(raw: string | undefined | null): boolean {
    const v = String(raw ?? '')
      .trim()
      .toLowerCase();
    return v === '1' || v === 'true' || v === 'yes' || v === 'on';
  }
}
