// Made by Dr Ali
// Phase 5 — OpenAI-compatible chat completions (Groq / Gemini / OpenRouter / OpenAI).
// No PII in logs; keys stay server-side.

import {
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { createHash } from 'crypto';
import { AiConfig } from './ai.config';
import { AiGroundingService } from './ai-grounding.service';
import { AiSettingsService } from './ai-settings.service';
import {
  AiLocale,
  normalizeAiLocale,
  resolveReplyLocale as resolveReplyLocaleHelper,
} from './obic-ai.constants';

export type ChatTurn = { role: 'system' | 'user' | 'assistant'; content: string };

type RateBucket = { count: number; resetAt: number };
type TranslateCacheEntry = { text: string; at: number };

const TRANSLATE_CACHE_MAX = 400;
const TRANSLATE_CACHE_TTL_MS = 6 * 60 * 60 * 1000;

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly buckets = new Map<string, RateBucket>();
  private readonly translateCache = new Map<string, TranslateCacheEntry>();

  constructor(
    private readonly cfg: AiConfig,
    private readonly grounding: AiGroundingService,
    private readonly aiSettings: AiSettingsService,
  ) {}

  status() {
    return {
      enabled: this.cfg.enabled,
      autoReplyEnabled: this.cfg.autoReplyEnabled,
      provider: this.cfg.enabled ? this.cfg.provider : null,
      model: this.cfg.enabled ? this.cfg.model : null,
    };
  }

  /** Status including DB global auto-reply flag (async). */
  async statusAsync() {
    const base = this.status();
    const globalAutoReply = await this.aiSettings.getGlobalAutoReplyFlag();
    return {
      ...base,
      globalAutoReplyEnabled: globalAutoReply,
      /** Effective: env/key gate AND DB global flag. */
      autoReplyEnabled: base.autoReplyEnabled && globalAutoReply,
    };
  }

  disabledCopy(locale: AiLocale): string {
    switch (locale) {
      case 'ar':
        return 'مساعد أوبك غير متاح حالياً. تواصل مع الدعم من رسائل الفريق.';
      case 'zh':
        return 'OBIC AI 暂未开启。请通过客服消息联系人工支持。';
      default:
        return 'OBIC AI is not enabled yet. Please chat with staff from Messages.';
    }
  }

  assertRateLimit(userId: string): void {
    const limit = this.cfg.rateLimitPerMinute;
    const now = Date.now();
    let bucket = this.buckets.get(userId);
    if (!bucket || bucket.resetAt <= now) {
      bucket = { count: 0, resetAt: now + 60_000 };
      this.buckets.set(userId, bucket);
    }
    bucket.count += 1;
    if (bucket.count > limit) {
      throw new HttpException(
        'AI rate limit exceeded — try again in a minute',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  buildSystemPrompt(
    locale: AiLocale,
    extraContext?: string,
    purpose: 'assistant' | 'auto_reply' = 'assistant',
  ): string {
    const preferred =
      locale === 'ar'
        ? 'Arabic'
        : locale === 'zh'
          ? 'Simplified Chinese'
          : 'English';
    // Keep prompts short — fewer input tokens = faster Groq responses.
    const lines = [
      'You are OBIC AI for OBIC (China travel & business).',
      `Reply in the user's latest message language (any). If unclear, use ${preferred}.`,
      'Be brief and helpful. No invented prices, seats, or booking confirmations.',
      'When catalog context lists a price, use that price; if unsure or no match, say staff/order will confirm.',
      'Never ask for passwords, OTP, full card numbers, or government IDs.',
      'For account/payment/order edits: use app Orders/Messages or staff chat.',
      'Friend chats have no AI — never claim otherwise.',
    ];
    if (purpose === 'auto_reply') {
      lines.push(
        'Short support/order auto-reply only.',
        "Mirror the customer's latest message language exactly; never force English.",
        'Do not claim you transferred to a human unless Talk to staff ran.',
        'For visa/order status with a case number: say staff will follow up; check Orders/Messages. Do not invent status.',
      );
    }
    if (extraContext?.trim()) {
      lines.push(`Context:\n${extraContext.trim()}`);
    }
    return lines.join('\n');
  }

  async complete(opts: {
    userId: string;
    locale: AiLocale;
    userMessage: string;
    history?: Array<{ role: 'user' | 'assistant'; content: string }>;
    extraContext?: string;
    purpose: 'assistant' | 'auto_reply';
    /** When true (default), inject FAQ + catalog snippets for this message. */
    ground?: boolean;
  }): Promise<string> {
    if (!this.cfg.enabled) {
      throw new ServiceUnavailableException(this.disabledCopy(opts.locale));
    }

    this.assertRateLimit(opts.userId);

    const grounded =
      opts.ground === false
        ? ''
        : this.grounding.retrieve(opts.userMessage, opts.locale);
    const extra = [grounded, opts.extraContext?.trim()]
      .filter(Boolean)
      .join('\n\n');

    const messages: ChatTurn[] = [
      {
        role: 'system',
        content: this.buildSystemPrompt(
          opts.locale,
          extra || undefined,
          opts.purpose,
        ),
      },
    ];
    // Cap history for latency (client also clips).
    const history = (opts.history ?? []).slice(-6);
    for (const turn of history) {
      const content = turn.content.trim().slice(0, 2000);
      if (!content) continue;
      messages.push({ role: turn.role, content });
    }
    messages.push({
      role: 'user',
      content: opts.userMessage.trim().slice(0, 3000),
    });

    const maxTokens =
      opts.purpose === 'auto_reply'
        ? this.cfg.autoReplyMaxTokens
        : this.cfg.maxTokens;

    const started = Date.now();
    try {
      const reply = await this.callChatCompletions(messages, {
        maxTokens,
        temperature: opts.purpose === 'auto_reply' ? 0.3 : 0.4,
      });
      this.logger.log(
        `ai_ok purpose=${opts.purpose} provider=${this.cfg.provider} ms=${Date.now() - started} locale=${opts.locale}`,
      );
      return reply;
    } catch (err) {
      const status =
        err instanceof HttpException ? err.getStatus() : 'err';
      this.logger.warn(
        `ai_fail purpose=${opts.purpose} provider=${this.cfg.provider} ms=${Date.now() - started} status=${status}`,
      );
      throw err;
    }
  }

  /**
   * WeChat-style translate — free Groq path. Cache by messageId|text|target.
   * Friend chats call this only (no auto-reply).
   */
  async translate(opts: {
    userId: string;
    text: string;
    targetLocale: AiLocale;
    messageId?: string | null;
  }): Promise<{ translation: string; cached: boolean; targetLocale: AiLocale }> {
    if (!this.cfg.enabled) {
      throw new ServiceUnavailableException(
        this.disabledCopy(opts.targetLocale),
      );
    }

    const text = opts.text.trim().slice(0, 4000);
    if (!text) {
      return {
        translation: '',
        cached: true,
        targetLocale: opts.targetLocale,
      };
    }

    const cacheKey = this.translateCacheKey(
      opts.messageId,
      text,
      opts.targetLocale,
    );
    const hit = this.translateCacheGet(cacheKey);
    if (hit != null) {
      return {
        translation: hit,
        cached: true,
        targetLocale: opts.targetLocale,
      };
    }

    this.assertRateLimit(opts.userId);

    const lang =
      opts.targetLocale === 'ar'
        ? 'Arabic'
        : opts.targetLocale === 'zh'
          ? 'Simplified Chinese'
          : 'English';

    const messages: ChatTurn[] = [
      {
        role: 'system',
        content:
          `Translate into ${lang}. Output only the translation — no quotes, labels, or commentary. ` +
          'If already in the target language, return the text unchanged.',
      },
      { role: 'user', content: text },
    ];

    const started = Date.now();
    try {
      const translation = await this.callChatCompletions(messages, {
        maxTokens: Math.min(
          this.cfg.translateMaxTokens,
          Math.max(120, Math.ceil(text.length * 1.2)),
        ),
        temperature: 0.1,
      });
      this.translateCacheSet(cacheKey, translation);
      this.logger.log(
        `ai_ok purpose=translate provider=${this.cfg.provider} ms=${Date.now() - started} locale=${opts.targetLocale} cached=0`,
      );
      return {
        translation,
        cached: false,
        targetLocale: opts.targetLocale,
      };
    } catch (err) {
      const status =
        err instanceof HttpException ? err.getStatus() : 'err';
      this.logger.warn(
        `ai_fail purpose=translate provider=${this.cfg.provider} ms=${Date.now() - started} status=${status}`,
      );
      throw err;
    }
  }

  /** OpenAI-compatible /chat/completions (Groq, Gemini OpenAI bridge, OpenRouter, OpenAI). */
  private async callChatCompletions(
    messages: ChatTurn[],
    opts?: { maxTokens?: number; temperature?: number },
  ): Promise<string> {
    const url = `${this.cfg.baseUrl}/chat/completions`;
    const headers: Record<string, string> = {
      Authorization: `Bearer ${this.cfg.apiKey}`,
      'Content-Type': 'application/json',
    };
    // OpenRouter recommends these; harmless elsewhere.
    if (this.cfg.provider === 'openrouter') {
      headers['HTTP-Referer'] = 'https://obic.app';
      headers['X-Title'] = 'OBIC AI';
    }

    let res: Response;
    try {
      res = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          model: this.cfg.model,
          messages,
          max_tokens: opts?.maxTokens ?? this.cfg.maxTokens,
          temperature: opts?.temperature ?? 0.4,
        }),
      });
    } catch {
      throw new ServiceUnavailableException('AI provider unreachable');
    }

    if (!res.ok) {
      // Do not forward provider error bodies (may contain snippets).
      if (res.status === 401 || res.status === 403) {
        throw new ServiceUnavailableException('AI provider auth failed');
      }
      if (res.status === 429) {
        throw new HttpException(
          'AI provider busy — try again shortly',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      throw new ServiceUnavailableException('AI provider error');
    }

    const data = (await res.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const text = data.choices?.[0]?.message?.content?.trim() ?? '';
    if (!text) {
      throw new ServiceUnavailableException('AI returned an empty reply');
    }
    return text.slice(0, 8000);
  }

  private translateCacheKey(
    messageId: string | null | undefined,
    text: string,
    target: AiLocale,
  ): string {
    const idPart =
      messageId && messageId.trim()
        ? messageId.trim()
        : createHash('sha256').update(text).digest('hex').slice(0, 24);
    return `${idPart}:${target}`;
  }

  private translateCacheGet(key: string): string | null {
    const entry = this.translateCache.get(key);
    if (!entry) return null;
    if (Date.now() - entry.at > TRANSLATE_CACHE_TTL_MS) {
      this.translateCache.delete(key);
      return null;
    }
    return entry.text;
  }

  private translateCacheSet(key: string, text: string): void {
    if (this.translateCache.size >= TRANSLATE_CACHE_MAX) {
      // Drop oldest ~20% (Map insertion order).
      const drop = Math.max(1, Math.floor(TRANSLATE_CACHE_MAX * 0.2));
      let i = 0;
      for (const k of this.translateCache.keys()) {
        this.translateCache.delete(k);
        i += 1;
        if (i >= drop) break;
      }
    }
    this.translateCache.set(key, { text, at: Date.now() });
  }

  resolveLocale(raw?: string | null): AiLocale {
    return normalizeAiLocale(raw);
  }

  /** Preferred locale from message script + optional client locale (assistant / auto-reply). */
  resolveReplyLocale(
    messageText?: string | null,
    clientLocale?: string | null,
  ): AiLocale {
    return resolveReplyLocaleHelper(messageText, clientLocale);
  }
}
