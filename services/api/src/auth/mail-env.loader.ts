// Made by Dr Ali
// Optional Resend / Twilio env from local files (never commit secrets).

import { config as loadEnv } from 'dotenv';
import { existsSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const KEYS = [
  'RESEND_API_KEY',
  'RESEND_FROM',
  'TWILIO_ACCOUNT_SID',
  'TWILIO_AUTH_TOKEN',
  'TWILIO_FROM_NUMBER',
  'VERIFICATION_DEBUG',
] as const;

/**
 * Loads verification mail/SMS vars from:
 * - services/api/mail.env
 * - ~/.config/obic/mail.env
 * Does not override already-set process.env keys.
 */
export function loadOptionalMailEnvFiles(cwd = process.cwd()): string[] {
  const candidates = [
    join(cwd, 'mail.env'),
    join(homedir(), '.config', 'obic', 'mail.env'),
  ];
  const loaded: string[] = [];
  for (const path of candidates) {
    if (!existsSync(path)) continue;
    const before = Object.fromEntries(
      KEYS.map((k) => [k, process.env[k]]),
    );
    loadEnv({ path, override: false });
    const changed = KEYS.some((k) => process.env[k] !== before[k]);
    if (changed) loaded.push(path);
  }
  return loaded;
}
