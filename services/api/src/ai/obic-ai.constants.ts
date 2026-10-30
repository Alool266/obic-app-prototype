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

/** Secretary briefing follows the language selected in the app, including French. */
export type SummaryLang = 'ar' | 'en' | 'zh' | 'fr';

export function summaryLanguage(clientLocale?: string | null): SummaryLang {
  const v = (clientLocale ?? '').trim().toLowerCase();
  if (v.startsWith('ar')) return 'ar';
  if (v.startsWith('zh') || v.includes('cn') || v.includes('hans')) return 'zh';
  if (v.startsWith('fr')) return 'fr';
  return 'en';
}

export type HandoffLabels = {
  header: string;
  need: string;
  facts: string;
  urgency: string;
  low: string;
  medium: string;
  high: string;
  support: string;
  languageName: string;
};

export function handoffLabels(lang: SummaryLang): HandoffLabels {
  switch (lang) {
    case 'ar':
      return {
        header: '📋 ملخص للسكرتيرة',
        need: 'الحاجة',
        facts: 'أهم المعلومات',
        urgency: 'الاستعجال',
        low: 'منخفض',
        medium: 'متوسط',
        high: 'مرتفع',
        support: 'طلب دعم',
        languageName: 'Arabic',
      };
    case 'zh':
      return {
        header: '📋 给秘书的摘要',
        need: '需求',
        facts: '要点',
        urgency: '紧急程度',
        low: '低',
        medium: '中',
        high: '高',
        support: '客服请求',
        languageName: 'Chinese',
      };
    case 'fr':
      return {
        header: '📋 Résumé pour la secrétaire',
        need: 'Besoin',
        facts: 'Faits',
        urgency: 'Urgence',
        low: 'faible',
        medium: 'moyenne',
        high: 'élevée',
        support: 'Demande d’assistance',
        languageName: 'French',
      };
    case 'en':
      return {
        header: '📋 Summary for Secretary',
        need: 'Need',
        facts: 'Key facts',
        urgency: 'Urgency',
        low: 'low',
        medium: 'medium',
        high: 'high',
        support: 'Support request',
        languageName: 'English',
      };
    default: {
      const uncovered: never = lang;
      return uncovered;
    }
  }
}

/** True when the briefing is actually in the selected language, not an English template. */
export function briefingMatchesLanguage(text: string, lang: SummaryLang): boolean {
  const body = text.trim();
  if (body.length < 8) return false;
  switch (lang) {
    case 'ar':
      return /[\u0600-\u06FF]/.test(body);
    case 'zh':
      return /[\u4e00-\u9fff]/.test(body);
    case 'fr':
      return /Besoin|Faits|Urgence/i.test(body);
    case 'en':
      return true;
    default: {
      const uncovered: never = lang;
      return uncovered;
    }
  }
}
