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
    retrieveForMessage: jest.fn(async () => 'Grounded OBIC facts:\n- stub'),
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
    expect(prompt).toMatch(/full customer catalog/i);
    expect(prompt).toMatch(/French/);
    expect(prompt).toContain('Friend chats have no AI');
    expect(prompt).toMatch(/catalog context|invented prices/i);
    expect(prompt).toMatch(/staff admin tools/i);
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

  function liveCfg(extra: Record<string, unknown> = {}) {
    return {
      ...config,
      enabled: true,
      hasApiKey: true,
      apiKey: 'gsk-test',
      flagEnabled: true,
      hasDeepseekKey: true,
      deepseekApiKey: 'sk-ds-test',
      deepseekBaseUrl: 'https://api.deepseek.com',
      deepseekVisionModel: 'deepseek-flash',
      ...extra,
    } as unknown as AiConfig;
  }

  function mockReply() {
    return jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        choices: [{ message: { content: 'Listed in the catalog.' } }],
      }),
    } as Response);
  }

  it('keeps text-only turns on the current provider', async () => {
    const fetchMock = mockReply();
    const svc = make(liveCfg());
    await svc.complete({
      userId: 'u-text',
      locale: 'en',
      userMessage: 'hotel near the branch',
      purpose: 'assistant',
    });
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    const body = JSON.parse(String(init.body)) as {
      model: string;
      max_tokens: number;
      reasoning_effort?: string;
      messages: Array<{ content: unknown }>;
    };
    expect(url).toBe('https://api.groq.com/openai/v1/chat/completions');
    expect(init.headers).toMatchObject({ Authorization: 'Bearer gsk-test' });
    expect(body.model).toBe('qwen/qwen3.8-27b');
    expect(body.max_tokens).toBe(100);
    expect(body.reasoning_effort).toBe('none');
    expect(typeof body.messages.at(-1)?.content).toBe('string');
    fetchMock.mockRestore();
  });

  it('retries once when the provider returns an error', async () => {
    const fetchMock = jest
      .spyOn(global, 'fetch')
      .mockResolvedValueOnce({
        ok: false,
        status: 503,
        json: async () => ({}),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          choices: [{ message: { content: 'Back online.' } }],
        }),
      } as Response);
    const svc = make(liveCfg());
    const reply = await svc.complete({
      userId: 'u-retry',
      locale: 'en',
      userMessage: 'hi',
      purpose: 'assistant',
    });
    expect(reply).toBe('Back online.');
    expect(fetchMock).toHaveBeenCalledTimes(2);
    fetchMock.mockRestore();
  });

  it('uses the fastest gemini thinking level that still returns a full answer', async () => {
    const fetchMock = mockReply();
    const minimalSvc = make(
      liveCfg({
        model: 'gemini-3-flash',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      }),
    );
    await minimalSvc.complete({
      userId: 'u-gem-min',
      locale: 'en',
      userMessage: 'Explain the visa steps',
      purpose: 'assistant',
    });
    const minimal = JSON.parse(
      String((fetchMock.mock.calls[0] as [string, RequestInit])[1].body),
    ) as { reasoning_effort?: string; max_tokens: number };
    expect(minimal.reasoning_effort).toBe('minimal');
    expect(minimal.max_tokens).toBe(100);

    const flashSvc = make(
      liveCfg({
        model: 'gemini-3.8-flash',
        baseUrl: 'https://api.apipod.ai/v1',
        deepseekVisionModel: 'gemini-3.8-flash',
        deepseekBaseUrl: 'https://api.apipod.ai/v1',
      }),
    );
    await flashSvc.complete({
      userId: 'u-gem-38',
      locale: 'en',
      userMessage: 'Explain how to book a hotel',
      purpose: 'assistant',
    });
    const low = JSON.parse(
      String((fetchMock.mock.calls[1] as [string, RequestInit])[1].body),
    ) as { reasoning_effort?: string; max_tokens: number };
    expect(low.reasoning_effort).toBe('low');
    expect(low.max_tokens).toBe(100);

    await flashSvc.complete({
      userId: 'u-gem-photo',
      locale: 'en',
      userMessage: '',
      purpose: 'assistant',
      attachment: {
        kind: 'image',
        mime: 'image/jpeg',
        filename: 'visa.jpg',
        bytes: Buffer.from([0xff, 0xd8, 0xff, 0xd9]),
      },
    });
    const photo = JSON.parse(
      String((fetchMock.mock.calls[2] as [string, RequestInit])[1].body),
    ) as {
      model: string;
      reasoning_effort?: string;
      max_tokens: number;
      messages: Array<{ content: unknown }>;
    };
    expect(photo.model).toBe('gemini-3.8-flash');
    expect(photo.reasoning_effort).toBe('low');
    expect(photo.max_tokens).toBe(100);
    const user = photo.messages.at(-1)?.content as Array<{
      type: string;
      text?: string;
    }>;
    expect(user[0]?.text).toMatch(/Describe what is in it/i);
    fetchMock.mockRestore();
  });

  it('sends auto-reply through the vision route when that key is set', async () => {
    const fetchMock = mockReply();
    const svc = make(liveCfg());
    await svc.complete({
      userId: 'u-auto',
      locale: 'en',
      userMessage: 'Where is my order?',
      purpose: 'auto_reply',
    });
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    const body = JSON.parse(String(init.body)) as { model: string };
    expect(url).toBe('https://api.deepseek.com/chat/completions');
    expect(init.headers).toMatchObject({
      Authorization: 'Bearer sk-ds-test',
    });
    expect(body.model).toBe('deepseek-flash');
    fetchMock.mockRestore();
  });

  it('sends a photo to deepseek-flash as an image part', async () => {
    const fetchMock = mockReply();
    const svc = make(liveCfg());
    await svc.complete({
      userId: 'u-photo',
      locale: 'en',
      userMessage: 'Which listed service is this?',
      purpose: 'assistant',
      attachment: {
        kind: 'image',
        mime: 'image/jpeg',
        filename: 'visa.jpg',
        bytes: Buffer.from([0xff, 0xd8, 0xff, 0xd9]),
      },
    });
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    const body = JSON.parse(String(init.body)) as {
      model: string;
      messages: Array<{ role: string; content: unknown }>;
    };
    expect(url).toBe('https://api.deepseek.com/chat/completions');
    expect(init.headers).toMatchObject({
      Authorization: 'Bearer sk-ds-test',
    });
    expect(body.model).toBe('deepseek-flash');
    const system = String(body.messages[0]?.content);
    expect(system).toMatch(/user-supplied/);
    expect(system).toMatch(/must not invent services/);
    expect(system).toMatch(/full customer catalog/i);
    const user = body.messages.at(-1)?.content as Array<{
      type: string;
      image_url?: { url: string };
    }>;
    expect(user).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ type: 'text' }),
        expect.objectContaining({
          type: 'image_url',
          image_url: {
            url: expect.stringMatching(/^data:image\/jpeg;base64,/),
          },
        }),
      ]),
    );
    fetchMock.mockRestore();
  });

  it('sends extracted file text to deepseek-flash, not an image', async () => {
    const fetchMock = mockReply();
    const svc = make(liveCfg());
    await svc.complete({
      userId: 'u-file',
      locale: 'en',
      userMessage: 'Is this price in the catalog?',
      purpose: 'assistant',
      attachment: {
        kind: 'file',
        filename: 'fees.csv',
        bytes: Buffer.from('service,price\nvisa,100\n'),
        extension: 'csv',
      },
    });
    const [, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    const body = JSON.parse(String(init.body)) as {
      model: string;
      messages: Array<{ content: unknown }>;
    };
    expect(body.model).toBe('deepseek-flash');
    const user = body.messages.at(-1)?.content;
    expect(typeof user).toBe('string');
    expect(String(user)).toContain('visa,100');
    expect(String(user)).toMatch(/user-supplied/i);
    expect(String(user)).not.toContain('image_url');
    expect(grounding.retrieveForMessage).toHaveBeenCalled();
    fetchMock.mockRestore();
  });

  it('returns not configured when the DeepSeek key is missing', async () => {
    const fetchMock = jest.spyOn(global, 'fetch');
    const svc = make(liveCfg({ hasDeepseekKey: false, deepseekApiKey: '' }));
    await expect(
      svc.complete({
        userId: 'u-missing',
        locale: 'en',
        userMessage: 'What is this?',
        purpose: 'assistant',
        attachment: {
          kind: 'image',
          mime: 'image/png',
          filename: 'a.png',
          bytes: Buffer.from([0x89, 0x50, 0x4e, 0x47]),
        },
      }),
    ).rejects.toThrow(/not configured/i);
    expect(fetchMock).not.toHaveBeenCalled();
    fetchMock.mockRestore();
  });
});
