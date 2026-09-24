#!/usr/bin/env node
// Made by Dr Ali
// Smoke-test Phase 5 AI provider (Groq default). Does not print the API key.
// Usage (from services/api):
//   node scripts/ai-smoke.mjs
// Reads AI_* from env, .env, ai.env, or ~/.config/obic/ai.env

import { existsSync, readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

function loadEnvFile(path) {
  if (!existsSync(path)) return;
  for (const line of readFileSync(path, 'utf8').split(/\r?\n/)) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const eq = t.indexOf('=');
    if (eq <= 0) continue;
    const k = t.slice(0, eq).trim();
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
loadEnvFile(join(cwd, 'ai.env'));
loadEnvFile(join(homedir(), '.config', 'obic', 'ai.env'));
loadEnvFile(join(cwd, '../../.env'));

const provider = (process.env.AI_PROVIDER || 'groq').trim().toLowerCase();
const defaults = {
  groq: {
    base: 'https://api.groq.com/openai/v1',
    model: 'qwen/qwen3.8-27b',
  },
  gemini: {
    base: 'https://generativelanguage.googleapis.com/v1beta/openai',
    model: 'gemini-2.0-flash',
  },
  openai: { base: 'https://api.openai.com/v1', model: 'gpt-4o-mini' },
  openrouter: {
    base: 'https://openrouter.ai/api/v1',
    model: 'google/gemma-2-9b-it:free',
  },
};
const preset = defaults[provider] || defaults.groq;
const base = (
  process.env.AI_BASE_URL ||
  process.env.OPENAI_BASE_URL ||
  preset.base
).replace(/\/$/, '');
const model = process.env.AI_MODEL || process.env.OPENAI_MODEL || preset.model;
const key = (
  process.env.AI_API_KEY ||
  process.env.GROQ_API_KEY ||
  process.env.GEMINI_API_KEY ||
  process.env.OPENROUTER_API_KEY ||
  process.env.OPENAI_API_KEY ||
  ''
).trim();

if (!key) {
  console.error(`
AI smoke: no API key found.

Get a free Groq key (≈2 min, no card):
  1. Open https://console.groq.com/keys
  2. Sign in → Create API Key
  3. Save locally (gitignored), e.g.:

mkdir -p ~/.config/obic
cat > ~/.config/obic/ai.env <<'EOF'
AI_ENABLED=true
AI_PROVIDER=groq
AI_API_KEY=gsk_paste_here
EOF

Then re-run: node scripts/ai-smoke.mjs
`);
  process.exit(2);
}

try {
  const url = `${base}/chat/completions`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      messages: [
        {
          role: 'system',
          content: 'You are OBIC AI smoke test. Reply with exactly: OK',
        },
        { role: 'user', content: 'ping' },
      ],
      max_tokens: 20,
      temperature: 0,
    }),
  });
  const text = await res.text();
  if (!res.ok) {
    console.error(
      `AI smoke FAIL provider=${provider} model=${model} status=${res.status}`,
    );
    console.error(text.slice(0, 400));
    process.exit(1);
  }
  let reply = '';
  try {
    reply = JSON.parse(text)?.choices?.[0]?.message?.content?.trim() || '';
  } catch {
    reply = text.slice(0, 120);
  }
  console.log(
    `AI smoke OK provider=${provider} model=${model} reply=${JSON.stringify(reply.slice(0, 80))}`,
  );
} catch (err) {
  console.error('AI smoke error:', err?.message || err);
  process.exit(1);
}
