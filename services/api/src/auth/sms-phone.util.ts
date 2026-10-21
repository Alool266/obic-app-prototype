// Made by Dr Ali
// OTP mobiles: mainland China +86, Saudi Arabia +966, Yemen +967.

export type SmsCountry = 'CN' | 'SA' | 'YE';

export const SMS_PHONE_COUNTRIES_MSG = 'SMS_PHONE_COUNTRIES';

const CN_LOCAL = /^1[3-9]\d{9}$/;
const SA_LOCAL = /^5\d{8}$/;
const YE_LOCAL = /^7\d{8}$/;

export function smsCountryOf(e164: string): SmsCountry | null {
  if (e164.startsWith('+86')) return 'CN';
  if (e164.startsWith('+966')) return 'SA';
  if (e164.startsWith('+967')) return 'YE';
  return null;
}

/** Normalize to +86 / +966 / +967, or null when it is not one of those mobiles. */
export function normalizeSmsMobile(raw?: string | null): string | null {
  if (!raw?.trim()) return null;
  const trimmed = raw.trim();
  let digits = trimmed.replace(/[^\d]/g, '');
  const hadCountryCode = trimmed.startsWith('+') || digits.startsWith('00');
  if (digits.startsWith('00')) digits = digits.slice(2);

  const fromCode = matchPrefixed(digits);
  if (fromCode) return fromCode;
  // A leading + that is not 86, 966, or 967 is another country.
  if (hadCountryCode) return null;

  if (CN_LOCAL.test(digits)) return `+86${digits}`;
  const local = digits.replace(/^0+/, '');
  if (SA_LOCAL.test(local)) return `+966${local}`;
  if (YE_LOCAL.test(local)) return `+967${local}`;
  return null;
}

function matchPrefixed(digits: string): string | null {
  if (digits.startsWith('86')) {
    const local = digits.slice(2).replace(/^0+/, '');
    if (CN_LOCAL.test(local)) return `+86${local}`;
  }
  if (digits.startsWith('966')) {
    const local = digits.slice(3).replace(/^0+/, '');
    if (SA_LOCAL.test(local)) return `+966${local}`;
  }
  if (digits.startsWith('967')) {
    const local = digits.slice(3).replace(/^0+/, '');
    if (YE_LOCAL.test(local)) return `+967${local}`;
  }
  return null;
}
