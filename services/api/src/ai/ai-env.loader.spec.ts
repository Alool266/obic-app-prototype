// Made by Dr Ali
import { mkdtempSync, writeFileSync, rmSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { loadOptionalAiEnvFiles } from './ai-env.loader';

describe('loadOptionalAiEnvFiles', () => {
  const prev = { ...process.env };
  let dir: string;

  afterEach(() => {
    process.env = { ...prev };
    if (dir) rmSync(dir, { recursive: true, force: true });
  });

  it('loads ai.env without overriding existing process.env', () => {
    dir = mkdtempSync(join(tmpdir(), 'obic-ai-'));
    writeFileSync(
      join(dir, 'ai.env'),
      'AI_API_KEY=from-file\nAI_PROVIDER=groq\n',
    );
    process.env.AI_API_KEY = 'already-set';
    delete process.env.AI_PROVIDER;

    const loaded = loadOptionalAiEnvFiles(dir);
    expect(loaded.some((p) => p.endsWith('ai.env'))).toBe(true);
    expect(process.env.AI_API_KEY).toBe('already-set');
    expect(process.env.AI_PROVIDER).toBe('groq');
  });
});
