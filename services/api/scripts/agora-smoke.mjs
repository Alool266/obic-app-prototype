#!/usr/bin/env node
// Made by Dr Ali
// Smoke-test Phase 5 Agora env (never prints secrets).
// Usage (from services/api):
//   node scripts/agora-smoke.mjs

import { existsSync, readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

function loadEnvFile(path, agoraOnly = false) {
  if (!existsSync(path)) return;
  for (const line of readFileSync(path, 'utf8').split(/\r?\n/)) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const eq = t.indexOf('=');
    if (eq <= 0) continue;
    const k = t.slice(0, eq).trim();
    if (agoraOnly && !k.startsWith('AGORA_')) continue;
    let v = t.slice(eq + 1).trim();
    if (
      (v.startsWith('"') && v.endsWith('"')) ||
      (v.startsWith("'") && v.endsWith("'"))
    ) {
      v = v.slice(1, -1);
    }
    if (process.env[k] === undefined || process.env[k] === '') {
      process.env[k] = v;
    }
  }
}

const cwd = process.cwd();
loadEnvFile(join(cwd, '.env'));
loadEnvFile(join(cwd, 'agora.env'), true);
loadEnvFile(join(homedir(), '.config', 'obic', 'agora.env'), true);
loadEnvFile(join(homedir(), '.config', 'obic', 'ai.env'), true);
loadEnvFile(join(cwd, '../../.env'));

const appId = (process.env.AGORA_APP_ID || '').trim();
const cert = (process.env.AGORA_APP_CERTIFICATE || '').trim();
const consoleUrl = 'https://console.agora.io/';

if (!appId || !cert) {
  console.error(`
Agora smoke: keys not set.

Get a free App ID (~2 min):
  1. Open ${consoleUrl}
  2. Sign up → Create project → copy App ID
  3. Enable App Certificate → copy certificate
  4. Save locally (gitignored), e.g.:

mkdir -p ~/.config/obic
cat > ~/.config/obic/agora.env <<'EOF'
AGORA_APP_ID=your_app_id
AGORA_APP_CERTIFICATE=your_certificate
EOF

Also set the same two vars on Render for the trial API.
Never put the certificate in Flutter / the APK.
`);
  process.exit(1);
}

try {
  const { createRequire } = await import('module');
  const require = createRequire(import.meta.url);
  const { RtcRole, RtcTokenBuilder } = require('agora-token');
  const channel = 'obic_smoke_channel';
  const uid = 42;
  const expire = Math.floor(Date.now() / 1000) + 600;
  const token = RtcTokenBuilder.buildTokenWithUid(
    appId,
    cert,
    channel,
    uid,
    RtcRole.PUBLISHER,
    expire,
    expire,
  );
  console.log('Agora smoke: OK');
  console.log(`  appId length: ${appId.length}`);
  console.log(`  certificate set: yes (not printed)`);
  console.log(`  sample token length: ${token.length}`);
  console.log(`  channel: ${channel}`);
} catch (e) {
  console.error('Agora smoke: token mint failed —', e?.message || e);
  process.exit(1);
}
