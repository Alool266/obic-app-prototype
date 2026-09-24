// Made by Dr Ali
import { AiConfig } from './ai.config';

describe('AiConfig', () => {
  function make(env: Record<string, string | undefined>) {
    return new AiConfig({
      get: (key: string) => env[key],
    } as never);
  }

  it('stays off unless AI_ENABLED and a key are set', () => {
    expect(make({}).enabled).toBe(false);
    expect(make({ AI_ENABLED: 'true' }).enabled).toBe(false);
    expect(make({ AI_API_KEY: 'gsk-test' }).enabled).toBe(false);
    expect(
      make({ AI_ENABLED: 'true', AI_API_KEY: 'gsk-test' }).enabled,
    ).toBe(true);
  });

  it('defaults to groq free-tier base URL and model', () => {
    const cfg = make({ AI_ENABLED: 'true', AI_API_KEY: 'gsk-test' });
    expect(cfg.provider).toBe('groq');
    expect(cfg.baseUrl).toBe('https://api.groq.com/openai/v1');
    expect(cfg.model).toBe('qwen/qwen3.8-27b');
  });

  it('keeps snappy token defaults', () => {
    const cfg = make({ AI_ENABLED: 'true', AI_API_KEY: 'gsk-test' });
    expect(cfg.maxTokens).toBe(400);
    expect(cfg.autoReplyMaxTokens).toBe(220);
    expect(cfg.translateMaxTokens).toBe(800);
  });

  it('accepts AI_PROVIDER=gemini with GEMINI_API_KEY', () => {
    const cfg = make({
      AI_ENABLED: 'true',
      AI_PROVIDER: 'gemini',
      GEMINI_API_KEY: 'AIza-test',
    });
    expect(cfg.enabled).toBe(true);
    expect(cfg.provider).toBe('gemini');
    expect(cfg.baseUrl).toContain('generativelanguage.googleapis.com');
    expect(cfg.model).toBe('gemini-2.0-flash');
  });

  it('falls back to legacy OPENAI_API_KEY', () => {
    const cfg = make({
      AI_ENABLED: 'true',
      AI_PROVIDER: 'openai',
      OPENAI_API_KEY: 'sk-test',
    });
    expect(cfg.enabled).toBe(true);
    expect(cfg.apiKey).toBe('sk-test');
    expect(cfg.baseUrl).toBe('https://api.openai.com/v1');
  });

  it('auto-reply follows AI master switch and AI_AUTO_REPLY', () => {
    const on = make({ AI_ENABLED: 'true', AI_API_KEY: 'gsk-test' });
    expect(on.autoReplyEnabled).toBe(true);
    const off = make({
      AI_ENABLED: 'true',
      AI_API_KEY: 'gsk-test',
      AI_AUTO_REPLY: 'false',
    });
    expect(off.autoReplyEnabled).toBe(false);
  });
});
