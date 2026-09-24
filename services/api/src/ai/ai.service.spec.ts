// Made by Dr Ali
import { AiConfig } from './ai.config';
import { AiService } from './ai.service';

describe('AiService', () => {
  const config = {
    enabled: false,
    autoReplyEnabled: false,
    apiKey: '',
    hasApiKey: false,
    flagEnabled: false,
    provider: 'groq',
    model: 'qwen/qwen3.8-27b',
    baseUrl: 'https://api.groq.com/openai/v1',
    rateLimitPerMinute: 2,
    maxTokens: 100,
    autoReplyMaxTokens: 80,
    translateMaxTokens: 200,
  } as unknown as AiConfig;

  const grounding = {
    retrieve: jest.fn(() => 'Grounded OBIC facts:\n- stub'),
  };

  const aiSettings = {
    getGlobalAutoReplyFlag: jest.fn(async () => true),
    isGlobalAutoReplyEnabled: jest.fn(async () => true),
  };

  const make = (cfg: AiConfig = config) =>
    new AiService(cfg, grounding as never, aiSettings as never);

  it('status reports disabled without key/flag', () => {
    const svc = make();
    expect(svc.status()).toEqual({
      enabled: false,
      autoReplyEnabled: false,
      provider: null,
      model: null,
    });
  });

  it('disabledCopy is localized', () => {
    const svc = make();
    expect(svc.disabledCopy('ar')).toContain('أوبك');
    expect(svc.disabledCopy('zh')).toContain('OBIC AI');
    expect(svc.disabledCopy('en')).toContain('not enabled');
  });

  it('rate-limits per user', () => {
    const on = {
      ...config,
      enabled: true,
      rateLimitPerMinute: 2,
    } as unknown as AiConfig;
    const svc = make(on);
    svc.assertRateLimit('u1');
    svc.assertRateLimit('u1');
    expect(() => svc.assertRateLimit('u1')).toThrow(/rate limit/i);
    // Other users are independent.
    svc.assertRateLimit('u2');
  });

  it('normalize locale helpers', () => {
    const svc = make();
    expect(svc.resolveLocale('ar-SA')).toBe('ar');
    expect(svc.resolveLocale('zh-CN')).toBe('zh');
    expect(svc.resolveLocale('en-US')).toBe('en');
  });

  it('system prompt requires matching user message language', () => {
    const svc = make();
    const prompt = svc.buildSystemPrompt('en');
    expect(prompt).toMatch(/user's latest message language/i);
    expect(prompt).toMatch(/any/i);
    expect(prompt).toContain('Friend chats have no AI');
    expect(prompt).toMatch(/catalog context|invented prices/i);
  });

  it('auto_reply prompt forbids forcing English', () => {
    const svc = make();
    const prompt = svc.buildSystemPrompt('en', undefined, 'auto_reply');
    expect(prompt).toMatch(/mirror the customer/i);
    expect(prompt).toMatch(/never force English/i);
    expect(prompt).toMatch(/auto-reply/i);
  });

  it('translate returns empty for blank text without calling provider', async () => {
    const on = {
      ...config,
      enabled: true,
      apiKey: 'gsk-test',
    } as unknown as AiConfig;
    const svc = make(on);
    const res = await svc.translate({
      userId: 'u1',
      text: '   ',
      targetLocale: 'en',
      messageId: 'm1',
    });
    expect(res).toEqual({
      translation: '',
      cached: true,
      targetLocale: 'en',
    });
  });

  it('resolveReplyLocale prefers message script over client locale', () => {
    const svc = make();
    expect(svc.resolveReplyLocale('مرحبا بالدعم', 'en')).toBe('ar');
    expect(svc.resolveReplyLocale('你好', 'en')).toBe('zh');
    expect(svc.resolveReplyLocale('hello', 'zh')).toBe('zh');
    expect(svc.resolveReplyLocale('hello', null)).toBe('en');
  });
});
