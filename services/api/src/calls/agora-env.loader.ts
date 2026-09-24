// Made by Dr Ali
// Optional local Agora secrets — never committed. Prefer process env, then these files.

import { existsSync, readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

/**
 * Paths checked for Agora keys (first wins per key; never overrides existing process.env).
 * - services/api/agora.env
 * - ~/.config/obic/agora.env
 * - ~/.config/obic/ai.env (same folder — AGORA_* lines allowed)
 */
export function agoraEnvCandidatePaths(cwd = process.cwd()): string[] {
  return [
    join(cwd, 'agora.env'),
    join(homedir(), '.config', 'obic', 'agora.env'),
    join(homedir(), '.config', 'obic', 'ai.env'),
  ];
}

/** Parse KEY=VALUE lines into process.env when the key is unset. */
export function loadOptionalAgoraEnvFiles(cwd = process.cwd()): string[] {
  const loaded: string[] = [];
  for (const path of agoraEnvCandidatePaths(cwd)) {
    if (!existsSync(path)) continue;
    try {
      const text = readFileSync(path, 'utf8');
      for (const line of text.split(/\r?\n/)) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith('#')) continue;
        const eq = trimmed.indexOf('=');
        if (eq <= 0) continue;
        const key = trimmed.slice(0, eq).trim();
        if (!key.startsWith('AGORA_')) continue;
        let value = trimmed.slice(eq + 1).trim();
        if (
          (value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))
        ) {
          value = value.slice(1, -1);
        }
        if (!key) continue;
        if (process.env[key] === undefined || process.env[key] === '') {
          process.env[key] = value;
        }
      }
      loaded.push(path);
    } catch {
      // Soft-fail: missing perms should not block API boot.
    }
  }
  return loaded;
}
