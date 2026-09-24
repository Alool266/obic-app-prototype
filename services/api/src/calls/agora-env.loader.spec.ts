// Made by Dr Ali
import { mkdtempSync, writeFileSync, rmSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { loadOptionalAgoraEnvFiles } from './agora-env.loader';

describe('loadOptionalAgoraEnvFiles', () => {
  const prev = { ...process.env };
  let dir: string;

  afterEach(() => {
    process.env = { ...prev };
    if (dir) rmSync(dir, { recursive: true, force: true });
  });

  it('loads AGORA_* without overriding existing process.env', () => {
    dir = mkdtempSync(join(tmpdir(), 'obic-agora-'));
    writeFileSync(
      join(dir, 'agora.env'),
      'AGORA_APP_ID=from-file\nAGORA_APP_CERTIFICATE=cert-from-file\nAI_API_KEY=ignore-me\n',
    );
    process.env.AGORA_APP_ID = 'already-set';
    delete process.env.AGORA_APP_CERTIFICATE;

    const loaded = loadOptionalAgoraEnvFiles(dir);
    expect(loaded.some((p) => p.endsWith('agora.env'))).toBe(true);
    expect(process.env.AGORA_APP_ID).toBe('already-set');
    expect(process.env.AGORA_APP_CERTIFICATE).toBe('cert-from-file');
    // Non-AGORA keys in agora.env are ignored by this loader.
    expect(process.env.AI_API_KEY).toBe(prev.AI_API_KEY);
  });
});
