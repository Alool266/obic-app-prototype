// Made by Dr Ali
// Phase 5 — OBIC AI system identity (server-only; never ship keys to Flutter).

/** Fixed UUID for the OBIC AI bot user (seeded on first use). */
export const OBIC_AI_USER_ID = 'a1000000-0000-4000-8000-000000000001';

export const OBIC_AI_EMAIL = 'obic-ai@system.local';

export const OBIC_AI_DISPLAY_NAME = 'OBIC AI';

/** App / fallback locales for prompts (AR / EN / 中文). Reply language still follows the user's message. */
export type AiLocale = 'ar' | 'en' | 'zh';

export function normalizeAiLocale(raw?: string | null): AiLocale {
  const v = (raw ?? '').trim().toLowerCase();
  if (v.startsWith('ar')) return 'ar';
  if (v.startsWith('zh') || v.includes('cn') || v.includes('hans')) return 'zh';
  return 'en';
}

/**
 * Detect script from message text for preferred-locale fallback.
 * Latin / other scripts → null (caller may use app locale or en).
 */
export function detectLocaleFromText(text?: string | null): AiLocale | null {
  const t = text ?? '';
  if (/[\u0600-\u06FF]/.test(t)) return 'ar';
  if (/[\u4e00-\u9fff]/.test(t)) return 'zh';
  return null;
}

/**
 * Preferred locale for prompts / canned notices:
 * 1) Arabic/Chinese script in the message wins
 * 2) else optional client/app locale
 * 3) else English
 *
 * The LLM system prompt still requires matching the user's full message language
 * (French, Spanish, etc.) — this value is only the fallback when unclear.
 */
export function resolveReplyLocale(
  messageText?: string | null,
  clientLocale?: string | null,
): AiLocale {
  return (
    detectLocaleFromText(messageText) ??
    normalizeAiLocale(clientLocale ?? 'en')
  );
}
