// Made by Dr Ali
// Phase 5 — OpenAI-compatible chat completions (Groq / Gemini / OpenRouter / OpenAI).
// No PII in logs; keys stay server-side.

import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { createHash } from 'crypto';
import {
  AI_ATTACHMENT_NOT_CONFIGURED,
  AI_ATTACHMENT_PROMPT_LINE,
  AI_ATTACHMENT_TOO_LARGE,
  AI_ATTACHMENT_MAX_BYTES,
  ParsedAiAttachment,
  buildFileUserText,
  extractFileText,
} from './ai-attachment';
import { AiConfig } from './ai.config';
import { AiGroundingService } from './ai-grounding.service';
import { AiSettingsService } from './ai-settings.service';
import {
  AiLocale,
  normalizeAiLocale,
  resolveReplyLocale as resolveReplyLocaleHelper,
} from './obic-ai.constants';

type ChatContentPart =
  | { type: 'text'; text: string }
  | { type: 'image_url'; image_url: { url: string } };

export type ChatTurn = {
  role: 'system' | 'user' | 'assistant';
  content: string | ChatContentPart[];
};

type CompletionRoute = {
  baseUrl: string;
  apiKey: string;
  model: string;
  providerLabel: string;
};

export type CompleteOpts = {
  userId: string;
  locale: AiLocale;
  userMessage: string;
  history?: Array<{ role: 'user' | 'assistant'; content: string }>;
  extraContext?: string;
  purpose: 'assistant' | 'auto_reply' | 'handoff_summary';
  /** When true (default), inject FAQ + catalog snippets for this message. */
  ground?: boolean;
  /** Photo or extracted file. Text-only turns leave this unset. */
  attachment?: ParsedAiAttachment;
};

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
    purpose: 'assistant' | 'auto_reply' | 'handoff_summary' = 'assistant',
  ): string {
    const preferred =
      locale === 'ar'
        ? 'Arabic'
        : locale === 'zh'
          ? 'Simplified Chinese'
          : 'English';
    // Keep prompts short — fewer input tokens = faster Groq responses.
    const lines = [
      'You are OBIC AI for the OBIC app.',
      'You can see a photo and read a PDF, Excel, or CSV when the user attaches one. If they ask whether you can see images, say yes and tell them to attach the photo.',
      'When the user sends a photo with no question, describe what is in it and answer as a full assistant. On a later message, use the photo and the earlier turns — you already saw what they sent.',
      'You cover the full customer catalog in Context: every category and sub-service (property, transport, travel, healthcare, food, shopping, education, logistics, government, business, and listed items such as visas, hotels, delivery, and daily China help), plus Offers and branches.',
      `Reply in the user's latest message language (any, including Arabic, English, Chinese, and French). If unclear, use ${preferred}.`,
      purpose === 'assistant'
        ? 'Reply in one to three short sentences. Add steps only when the user asks how.'
        : 'Be brief and helpful.',
      'No invented services, prices, seats, or booking confirmations.',
      'When catalog context lists a price, use that price; if the service is not in the catalog, say it is not listed and staff/order can confirm.',
      'Do not mention staff admin tools, internal desks, or employee directories.',
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
    if (purpose === 'handoff_summary') {
      lines.push(
        'Write a brief handoff briefing FOR THE BRANCH SECRETARY (staff-only note).',
        'The user message names the language and the exact three labels. Use only that language and those labels.',
        'Exactly three lines. One urgency word after the urgency label.',
        'No greeting, no customer-facing fluff, no invented facts.',
        'Do not use the English labels Need, Key facts, or Urgency unless the user message says the language is English.',
      );
    }
    if (extraContext?.trim()) {
      lines.push(`Context:\n${extraContext.trim()}`);
    }
    return lines.join('\n');
  }

  async complete(opts: CompleteOpts): Promise<string> {
    const { messages, maxTokens, temperature, route } =
      await this.prepareChat(opts);
    const started = Date.now();
    try {
      const reply = await this.callChatCompletions(messages, {
        maxTokens,
        temperature,
        route,
      });
      this.logger.log(
        `ai_ok purpose=${opts.purpose} provider=${route.providerLabel} model=${route.model} attachment=${opts.attachment?.kind ?? 'none'} ms=${Date.now() - started} locale=${opts.locale}`,
      );
      return reply;
    } catch (err) {
      const status = err instanceof HttpException ? err.getStatus() : 'err';
      this.logger.warn(
        `ai_fail purpose=${opts.purpose} provider=${route.providerLabel} model=${route.model} attachment=${opts.attachment?.kind ?? 'none'} ms=${Date.now() - started} status=${status}`,
      );
      throw err;
    }
  }

  /**
   * Streaming variant of complete() — yields reply text as the provider
   * produces it, so the app renders token-by-token instead of waiting for
   * the whole answer. Retries once only when nothing was emitted yet.
   */
  async *streamComplete(opts: CompleteOpts): AsyncGenerator<string> {
    const { messages, maxTokens, temperature, route } =
      await this.prepareChat(opts);
    const started = Date.now();
    let emitted = false;
    try {
      for await (const delta of this.postChatStream(messages, route, {
        maxTokens,
        temperature,
      })) {
        emitted = true;
        yield delta;
      }
      this.logger.log(
        `ai_ok purpose=${opts.purpose} provider=${route.providerLabel} model=${route.model} stream=1 ms=${Date.now() - started} locale=${opts.locale}`,
      );
    } catch (err) {
      if (!emitted && this.retryableProviderError(err)) {
        this.logger.warn(
          `ai_retry provider=${route.providerLabel} model=${route.model} stream=1`,
        );
        yield* this.postChatStream(messages, route, {
          maxTokens,
          temperature,
        });
        return;
      }
      const status = err instanceof HttpException ? err.getStatus() : 'err';
      this.logger.warn(
        `ai_fail purpose=${opts.purpose} provider=${route.providerLabel} model=${route.model} stream=1 ms=${Date.now() - started} status=${status}`,
      );
      throw err;
    }
  }

  /** Shared prompt assembly for complete() and streamComplete(). */
  private async prepareChat(opts: CompleteOpts): Promise<{
    messages: ChatTurn[];
    maxTokens: number;
    temperature: number;
    route: CompletionRoute;
  }> {
    if (!this.cfg.enabled) {
      throw new ServiceUnavailableException(this.disabledCopy(opts.locale));
    }

    const attachment = opts.attachment;
    const route = this.routeFor(opts.purpose, attachment);
    if (attachment && attachment.bytes.length > AI_ATTACHMENT_MAX_BYTES) {
      throw new BadRequestException(AI_ATTACHMENT_TOO_LARGE);
    }

    this.assertRateLimit(opts.userId);

    // The reply follows the language of the user's latest message, not the
    // app UI locale: Arabic script → Arabic, Han script → Chinese. For
    // Latin scripts the explicit mirror directive below decides (French…).
    const effectiveLocale =
      opts.purpose === 'assistant'
        ? this.resolveReplyLocale(opts.userMessage, opts.locale)
        : opts.locale;

    const fileText =
      attachment?.kind === 'file' ? await extractFileText(attachment) : null;
    const retrievalQuery = [
      opts.userMessage.trim(),
      fileText?.text.slice(0, 500) ?? '',
    ]
      .filter(Boolean)
      .join('\n')
      .slice(0, 2000);

    const grounded =
      opts.ground === false || opts.purpose === 'handoff_summary'
        ? ''
        : await this.grounding.retrieveForMessage(
            retrievalQuery || opts.userMessage,
            effectiveLocale,
          );
    const extra = [grounded, opts.extraContext?.trim()]
      .filter(Boolean)
      .join('\n\n');

    let system = this.buildSystemPrompt(
      effectiveLocale,
      extra || undefined,
      opts.purpose,
    );
    if (attachment) {
      system = `${system}\n${AI_ATTACHMENT_PROMPT_LINE}`;
    }
    if (opts.purpose === 'assistant') {
      system +=
        effectiveLocale === 'ar'
          ? '\nThe user is writing in Arabic. Reply in Arabic only.'
          : effectiveLocale === 'zh'
            ? '\nThe user is writing in Chinese. Reply in Simplified Chinese only.'
            : "\nReply strictly in the same language as the user's latest message. Never answer in English when the user wrote French or any other language.";
    }
    const messages: ChatTurn[] = [{ role: 'system', content: system }];
    // Cap history for latency (client also clips).
    const history = (opts.history ?? []).slice(-6);
    for (const turn of history) {
      const content = turn.content.trim().slice(0, 2000);
      if (!content) continue;
      messages.push({ role: turn.role, content });
    }
    messages.push({
      role: 'user',
      content: this.userContent(
        effectiveLocale,
        opts.userMessage,
        attachment,
        fileText,
      ),
    });

    const maxTokens =
      opts.purpose === 'auto_reply'
        ? this.cfg.autoReplyMaxTokens
        : opts.purpose === 'handoff_summary'
          ? Math.min(this.cfg.autoReplyMaxTokens, 280)
          : Math.min(this.cfg.maxTokens, 480);

    return {
      messages,
      maxTokens,
      temperature: opts.purpose === 'auto_reply' ? 0.3 : 0.4,
      route,
    };
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
  }): Promise<{
    translation: string;
    cached: boolean;
    targetLocale: AiLocale;
  }> {
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
      const status = err instanceof HttpException ? err.getStatus() : 'err';
      this.logger.warn(
        `ai_fail purpose=translate provider=${this.cfg.provider} ms=${Date.now() - started} status=${status}`,
      );
      throw err;
    }
  }

  /** Staff question over company document excerpts. Catalog grounding stays off. */
  async completeFromCompanyFiles(opts: {
    userId: string;
    question: string;
    excerpts: string;
  }): Promise<string> {
    if (!this.cfg.enabled) {
      throw new ServiceUnavailableException(this.disabledCopy('en'));
    }
    this.assertRateLimit(opts.userId);
    const route = this.textRoute();
    const messages: ChatTurn[] = [
      {
        role: 'system',
        content: [
          'You answer one staff question using only the company document excerpts.',
          'If the excerpts do not contain the answer, reply exactly: The company documents do not say.',
          'Do not use the customer catalog, prices, or outside knowledge.',
          'Name the document title you used.',
          'Reply in the language of the question. Stay under 800 characters.',
        ].join('\n'),
      },
      {
        role: 'user',
        content: `Question:\n${opts.question.trim().slice(0, 300)}\n\nDocuments:\n${opts.excerpts.trim().slice(0, 4000)}`,
      },
    ];
    const started = Date.now();
    try {
      const reply = await this.callChatCompletions(messages, {
        maxTokens: 400,
        temperature: 0.2,
        route,
      });
      this.logger.log(
        `ai_ok purpose=company_files provider=${route.providerLabel} model=${route.model} ms=${Date.now() - started}`,
      );
      return reply.trim().slice(0, 2000);
    } catch (err) {
      const status = err instanceof HttpException ? err.getStatus() : 'err';
      this.logger.warn(
        `ai_fail purpose=company_files provider=${route.providerLabel} model=${route.model} ms=${Date.now() - started} status=${status}`,
      );
      throw err;
    }
  }

  /**
   * Assistant text stays on the configured provider.
   * Photos, files, and support auto-reply use the vision key when it is set.
   */
  private routeFor(
    purpose: 'assistant' | 'auto_reply' | 'handoff_summary',
    attachment: ParsedAiAttachment | undefined,
  ): CompletionRoute {
    const autoReplyOnVision =
      purpose === 'auto_reply' && this.cfg.hasDeepseekKey;
    if (attachment || autoReplyOnVision) return this.attachmentRoute();
    return this.textRoute();
  }

  private textRoute(): CompletionRoute {
    return {
      baseUrl: this.cfg.baseUrl,
      apiKey: this.cfg.apiKey,
      model: this.cfg.model,
      providerLabel: this.cfg.provider,
    };
  }

  private attachmentRoute(): CompletionRoute {
    if (!this.cfg.hasDeepseekKey) {
      throw new ServiceUnavailableException(AI_ATTACHMENT_NOT_CONFIGURED);
    }
    return {
      baseUrl: this.cfg.deepseekBaseUrl,
      apiKey: this.cfg.deepseekApiKey,
      model: this.cfg.deepseekVisionModel,
      providerLabel: 'deepseek',
    };
  }

  private userContent(
    locale: AiLocale,
    userMessage: string,
    attachment: ParsedAiAttachment | undefined,
    fileText: { text: string; truncated: boolean } | null,
  ): string | ChatContentPart[] {
    const question = userMessage.trim().slice(0, 3000);
    if (!attachment) return question;
    if (attachment.kind === 'image') {
      const text = question || this.defaultAttachmentQuestion(locale, 'image');
      return [
        { type: 'text', text },
        {
          type: 'image_url',
          image_url: {
            url: `data:${attachment.mime};base64,${attachment.bytes.toString('base64')}`,
          },
        },
      ];
    }
    return buildFileUserText({
      question: question || this.defaultAttachmentQuestion(locale, 'file'),
      filename: attachment.filename,
      extracted: fileText?.text ?? '',
      truncated: fileText?.truncated ?? false,
    });
  }

  private defaultAttachmentQuestion(
    locale: AiLocale,
    kind: 'image' | 'file',
  ): string {
    if (kind === 'image') {
      switch (locale) {
        case 'ar':
          return 'أرسلت هذه الصورة بدون تعليق. صف ما فيها بوضوح، ثم أجب كمساعد كامل.';
        case 'zh':
          return '用户只发了这张图片，没有文字。请清楚描述图里的内容，并像完整的助手一样回答。';
        case 'en':
          return 'The user sent this photo with no caption. Describe what is in it, then answer as a full assistant.';
        default: {
          const _exhaustive: never = locale;
          return _exhaustive;
        }
      }
    }
    switch (locale) {
      case 'ar':
        return 'اقرأ هذا الملف.';
      case 'zh':
        return '请看这个文件。';
      case 'en':
        return 'Look at this file.';
      default: {
        const _exhaustive: never = locale;
        return _exhaustive;
      }
    }
  }

  /** One slow or 5xx reply is retried once. Auth failures are not. */
  private retryableProviderError(err: unknown): boolean {
    if (!(err instanceof HttpException)) return false;
    if (err.getStatus() === 401 || err.getStatus() === 403) return false;
    return !/auth failed/i.test(err.message);
  }

  /** OpenAI-compatible /chat/completions (Groq, Gemini OpenAI bridge, OpenRouter, OpenAI, DeepSeek). */
  private async callChatCompletions(
    messages: ChatTurn[],
    opts?: {
      maxTokens?: number;
      temperature?: number;
      route?: CompletionRoute;
    },
  ): Promise<string> {
    const route = opts?.route ?? this.textRoute();
    try {
      return await this.postChat(messages, route, opts, 12_000);
    } catch (err) {
      if (!this.retryableProviderError(err)) throw err;
      this.logger.warn(
        `ai_retry provider=${route.providerLabel} model=${route.model}`,
      );
      return await this.postChat(messages, route, opts, 12_000);
    }
  }

  private async postChat(
    messages: ChatTurn[],
    route: CompletionRoute,
    opts: { maxTokens?: number; temperature?: number } | undefined,
    timeoutMs: number,
  ): Promise<string> {
    const url = `${route.baseUrl}/chat/completions`;
    const headers: Record<string, string> = {
      Authorization: `Bearer ${route.apiKey}`,
      'Content-Type': 'application/json',
    };
    // OpenRouter recommends these; harmless elsewhere.
    if (route.providerLabel === 'openrouter') {
      headers['HTTP-Referer'] = 'https://obic.app';
      headers['X-Title'] = 'OBIC AI';
    }

    let res: Response;
    try {
      res = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          model: route.model,
          messages,
          max_tokens: opts?.maxTokens ?? this.cfg.maxTokens,
          temperature: opts?.temperature ?? 0.4,
          ...this.completionExtras(route.model),
        }),
        signal: AbortSignal.timeout(timeoutMs),
      });
    } catch {
      throw new ServiceUnavailableException('AI provider unreachable');
    }

    if (!res.ok) {
      throw this.providerHttpError(res.status, route);
    }

    const data = (await res.json()) as {
      choices?: Array<{
        message?: {
          content?: string | Array<{ type?: string; text?: string }>;
        };
      }>;
    };
    const text = this.replyText(data);
    if (!text) {
      throw new ServiceUnavailableException('AI returned an empty reply');
    }
    return text.slice(0, 32000);
  }

  /** Map an upstream HTTP failure to a client error (never forwards bodies). */
  private providerHttpError(
    status: number,
    route: CompletionRoute,
  ): HttpException {
    // Status only — provider bodies can echo the prompt.
    this.logger.warn(
      `ai_upstream status=${status} provider=${route.providerLabel} model=${route.model}`,
    );
    if (status === 401 || status === 403) {
      return new ServiceUnavailableException('AI provider auth failed');
    }
    if (status === 429) {
      return new HttpException(
        'AI provider busy — try again shortly',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    return new ServiceUnavailableException('AI provider error');
  }

  /**
   * Streaming chat completion — parses the provider's SSE `data:` lines and
   * yields content deltas as they arrive (OpenAI-compatible stream=true).
   */
  private async *postChatStream(
    messages: ChatTurn[],
    route: CompletionRoute,
    opts: { maxTokens?: number; temperature?: number } | undefined,
  ): AsyncGenerator<string> {
    const url = `${route.baseUrl}/chat/completions`;
    const headers: Record<string, string> = {
      Authorization: `Bearer ${route.apiKey}`,
      'Content-Type': 'application/json',
    };
    if (route.providerLabel === 'openrouter') {
      headers['HTTP-Referer'] = 'https://obic.app';
      headers['X-Title'] = 'OBIC AI';
    }

    let res: Response;
    try {
      res = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          model: route.model,
          messages,
          max_tokens: opts?.maxTokens ?? this.cfg.maxTokens,
          temperature: opts?.temperature ?? 0.4,
          stream: true,
          ...this.completionExtras(route.model),
        }),
        signal: AbortSignal.timeout(60_000),
      });
    } catch {
      throw new ServiceUnavailableException('AI provider unreachable');
    }

    if (!res.ok || !res.body) {
      throw this.providerHttpError(res.status, route);
    }

    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      let idx = buffer.indexOf('\n');
      while (idx >= 0) {
        const line = buffer.slice(0, idx).trim();
        buffer = buffer.slice(idx + 1);
        const delta = this.streamDelta(line);
        if (delta) yield delta;
        idx = buffer.indexOf('\n');
      }
    }
    const tail = this.streamDelta(buffer.trim());
    if (tail) yield tail;
  }

  /** One SSE line → content delta ('' for keep-alives / [DONE] / junk). */
  private streamDelta(line: string): string {
    if (!line.startsWith('data:')) return '';
    const payload = line.slice(5).trim();
    if (!payload || payload === '[DONE]') return '';
    try {
      const data = JSON.parse(payload) as {
        choices?: Array<{
          delta?: {
            content?: string | Array<{ type?: string; text?: string }>;
          };
        }>;
      };
      const content = data.choices?.[0]?.delta?.content;
      if (typeof content === 'string') return content;
      if (Array.isArray(content)) {
        return content
          .map((part) => (typeof part?.text === 'string' ? part.text : ''))
          .join('');
      }
    } catch {
      // Partial JSON line — providers frame on newlines; ignore.
    }
    return '';
  }

  /**
   * Drop the hidden thinking pass when the model allows it, so the answer
   * starts immediately. Assistant replies are capped so they finish quickly.
   * Gemini 3.7/3.8 Flash reject "minimal" and "none" (the request fails).
   * "low" is their fastest accepted level and is what kept thinking from
   * spending the whole completion budget on an empty reply.
   */
  private completionExtras(model: string): { reasoning_effort?: string } {
    if (/gemini/i.test(model)) {
      return { reasoning_effort: this.geminiReasoningEffort(model) };
    }
    // Qwen 3.6/3.8 think by default. Instruct mode still writes the full
    // answer; it only skips the reasoning tokens before that answer.
    if (/qwen3\.[68](?:[^\d]|$)/i.test(model)) {
      return { reasoning_effort: 'none' };
    }
    return {};
  }

  private geminiReasoningEffort(model: string): 'none' | 'minimal' | 'low' {
    if (/gemini-3\.[78](?:[^\d]|$)/i.test(model)) return 'low';
    if (/gemini-2\.5-flash/i.test(model)) return 'none';
    if (/gemini-2\.5-pro/i.test(model)) return 'low';
    if (/gemini-3(?:[.\-]|$)/i.test(model) && !/pro/i.test(model)) {
      return 'minimal';
    }
    return 'low';
  }

  private replyText(data: {
    choices?: Array<{
      message?: {
        content?: string | Array<{ type?: string; text?: string }>;
      };
    }>;
  }): string {
    const content = data.choices?.[0]?.message?.content;
    if (typeof content === 'string') return content.trim();
    if (!Array.isArray(content)) return '';
    return content
      .map((part) => (typeof part?.text === 'string' ? part.text : ''))
      .join('')
      .trim();
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

  /** Spoken words in a voice note. Empty text means no clear speech. */
  async transcribe(opts: {
    userId: string;
    dataBase64: string;
    mime: string;
  }): Promise<{ text: string }> {
    const key = this.cfg.groqApiKey;
    if (!key) {
      throw new ServiceUnavailableException('Voice transcription is not configured');
    }
    this.assertRateLimit(opts.userId);
    const bytes = Buffer.from(opts.dataBase64, 'base64');
    if (!bytes.length || bytes.length > 8_000_000) {
      throw new BadRequestException('Audio is empty or too large');
    }
    const packed = multipartBody([
      { name: 'model', value: 'whisper-large-v3-turbo' },
      { name: 'response_format', value: 'json' },
      {
        name: 'file',
        file: {
          filename: 'voice.m4a',
          mime: opts.mime || 'audio/mp4',
          data: bytes,
        },
      },
    ]);
    const res = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${key}`,
        'content-type': `multipart/form-data; boundary=${packed.boundary}`,
      },
      body: new Uint8Array(packed.body),
    });
    if (!res.ok) {
      throw new ServiceUnavailableException('Could not convert that voice message');
    }
    const json = (await res.json()) as { text?: string };
    return { text: (json.text ?? '').trim() };
  }

  /**
   * Text regions in a photo, as fractions of the image.
   * Used to cover each line with a translation in the same place.
   */
  async seeText(opts: {
    userId: string;
    dataBase64: string;
    mime: string;
  }): Promise<{
    blocks: Array<{ text: string; x: number; y: number; w: number; h: number; angle: number }>;
  }> {
    const key = this.cfg.groqApiKey;
    if (!key) {
      throw new ServiceUnavailableException('Image reading is not configured');
    }
    this.assertRateLimit(opts.userId);
    const mime = opts.mime.startsWith('image/') ? opts.mime : 'image/jpeg';
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${key}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'meta-llama/llama-4-scout-17b-16e-instruct',
        temperature: 0,
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text:
                  'Read every piece of text in this photo. Include big titles, small print, prices, vertical text, and text on tilted or angled signs. Do not skip Chinese, Arabic, English, or any other language. Reply with JSON only, no markdown: {"blocks":[{"text":"","x":0,"y":0,"w":0,"h":0,"angle":0}]}. x,y,w,h are fractions of the image width and height from the top left, between 0 and 1, tight around each line. angle is degrees, clockwise, 0 when the line is horizontal. Keep the original characters. If there is no text, return {"blocks":[]}.',
              },
              {
                type: 'image_url',
                image_url: { url: `data:${mime};base64,${opts.dataBase64}` },
              },
            ],
          },
        ],
      }),
    });
    if (!res.ok) {
      throw new ServiceUnavailableException('Could not read text in that photo');
    }
    const json = (await res.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const raw = json.choices?.[0]?.message?.content ?? '';
    return { blocks: parseTextBlocks(raw) };
  }

  /**
   * Read a passport bio page into structured fields (boss M04). The model
   * only reads — it never approves anything. Callers store the raw fields
   * with confidences and route mismatches to a human reviewer.
   */
  async extractPassportFields(opts: {
    userId: string;
    dataBase64: string;
    mime: string;
  }): Promise<{ raw: string; model: string; provider: string }> {
    this.assertRateLimit(opts.userId);
    const mime = opts.mime.startsWith('image/') ? opts.mime : 'image/jpeg';
    // Use whichever vision-capable route this deployment actually has:
    // DeepSeek photo key → Groq key → the configured chat provider.
    const candidates: CompletionRoute[] = [];
    if (this.cfg.hasDeepseekKey) candidates.push(this.attachmentRoute());
    if (this.cfg.groqApiKey) {
      candidates.push({
        baseUrl: 'https://api.groq.com/openai/v1',
        apiKey: this.cfg.groqApiKey,
        model: 'meta-llama/llama-4-scout-17b-16e-instruct',
        providerLabel: 'groq',
      });
    }
    if (this.cfg.hasApiKey) candidates.push(this.textRoute());
    if (candidates.length === 0) {
      throw new ServiceUnavailableException('Image reading is not configured');
    }
    const prompt =
      'This photo should be a passport bio page. Extract these fields exactly as printed: fullName, passportNumber, nationality, dateOfBirth, sex, issueDate, expiryDate. Dates as YYYY-MM-DD. If a field is not readable, use null. Also give a confidence 0..1 per field. Reply with JSON only, no markdown: {"fields":{"fullName":null,"passportNumber":null,"nationality":null,"dateOfBirth":null,"sex":null,"issueDate":null,"expiryDate":null},"confidence":{"fullName":0}}. Do not invent values. If it is not a passport, return all fields null.';
    let lastError: unknown = null;
    for (const route of candidates) {
      try {
        const res = await fetch(`${route.baseUrl}/chat/completions`, {
          method: 'POST',
          headers: {
            authorization: `Bearer ${route.apiKey}`,
            'content-type': 'application/json',
          },
          body: JSON.stringify({
            model: route.model,
            temperature: 0,
            messages: [
              {
                role: 'user',
                content: [
                  { type: 'text', text: prompt },
                  {
                    type: 'image_url',
                    image_url: {
                      url: `data:${mime};base64,${opts.dataBase64}`,
                    },
                  },
                ],
              },
            ],
          }),
        });
        if (!res.ok) throw new Error(`vision route ${route.providerLabel}: ${res.status}`);
        const json = (await res.json()) as {
          choices?: Array<{ message?: { content?: string } }>;
        };
        return {
          raw: json.choices?.[0]?.message?.content ?? '',
          model: route.model,
          provider: route.providerLabel,
        };
      } catch (err) {
        lastError = err;
      }
    }
    this.logger.warn(
      `Passport reading failed on all routes: ${lastError instanceof Error ? lastError.message : 'unknown'}`,
    );
    throw new ServiceUnavailableException('Could not read that document photo');
  }
}

function multipartBody(
  fields: Array<{
    name: string;
    value?: string;
    file?: { filename: string; mime: string; data: Buffer };
  }>,
): { body: Buffer; boundary: string } {
  const boundary = `obic${Date.now().toString(16)}`;
  const chunks: Buffer[] = [];
  for (const field of fields) {
    chunks.push(Buffer.from(`--${boundary}\r\n`));
    if (field.file) {
      chunks.push(
        Buffer.from(
          `Content-Disposition: form-data; name="${field.name}"; filename="${field.file.filename}"\r\nContent-Type: ${field.file.mime}\r\n\r\n`,
        ),
      );
      chunks.push(field.file.data);
      chunks.push(Buffer.from('\r\n'));
    } else {
      chunks.push(
        Buffer.from(
          `Content-Disposition: form-data; name="${field.name}"\r\n\r\n${field.value ?? ''}\r\n`,
        ),
      );
    }
  }
  chunks.push(Buffer.from(`--${boundary}--\r\n`));
  return { body: Buffer.concat(chunks), boundary };
}

function parseTextBlocks(raw: string): Array<{
  text: string;
  x: number;
  y: number;
  w: number;
  h: number;
  angle: number;
}> {
  const start = raw.indexOf('{');
  const end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) return [];
  try {
    const parsed = JSON.parse(raw.slice(start, end + 1)) as {
      blocks?: unknown;
    };
    if (!Array.isArray(parsed.blocks)) return [];
    const out = [];
    for (const row of parsed.blocks) {
      if (!row || typeof row !== 'object') continue;
      const item = row as Record<string, unknown>;
      const text = typeof item.text === 'string' ? item.text.trim() : '';
      const x = Number(item.x);
      const y = Number(item.y);
      const w = Number(item.w);
      const h = Number(item.h);
      const angle = Number(item.angle);
      if (!text || ![x, y, w, h].every((n) => Number.isFinite(n))) continue;
      out.push({
        text: text.slice(0, 400),
        x: Math.min(1, Math.max(0, x)),
        y: Math.min(1, Math.max(0, y)),
        w: Math.min(1, Math.max(0.01, w)),
        h: Math.min(1, Math.max(0.008, h)),
        angle: Number.isFinite(angle) ? angle : 0,
      });
      if (out.length >= 80) break;
    }
    return out;
  } catch {
    return [];
  }
}
