// Made by Dr Ali
// Optional local APNs settings — never committed. The .p8 stays in ~/.config/obic.

import { existsSync, readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

/**
 * Paths checked for push settings (first wins per key; never overrides process.env).
 * - services/api/apns.env and ~/.config/obic/apns.env for APNS_*
 * - services/api/fcm.env and ~/.config/obic/fcm.env for FCM_*
 */
export function apnsEnvCandidatePaths(cwd = process.cwd()): string[] {
  return [
    join(cwd, 'apns.env'),
    join(homedir(), '.config', 'obic', 'apns.env'),
    join(cwd, 'fcm.env'),
    join(homedir(), '.config', 'obic', 'fcm.env'),
  ];
}

/** Parse APNS_* and FCM_* lines into process.env when the key is unset. */
export function loadOptionalApnsEnvFiles(cwd = process.cwd()): string[] {
  const loaded: string[] = [];
  for (const path of apnsEnvCandidatePaths(cwd)) {
    if (!existsSync(path)) continue;
    try {
      const text = readFileSync(path, 'utf8');
      for (const line of text.split(/\r?\n/)) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith('#')) continue;
        const eq = trimmed.indexOf('=');
        if (eq <= 0) continue;
        const key = trimmed.slice(0, eq).trim();
        if (!key.startsWith('APNS_') && !key.startsWith('FCM_')) continue;
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
