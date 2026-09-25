// Made by Dr Ali
// China mainland mobile only: +86 / 1[3-9]xxxxxxxxx (11 digits).

/** Normalize to E.164-ish +86xxxxxxxxxxx or null if empty. */
export function normalizeChinaMobile(raw?: string | null): string | null {
  if (!raw?.trim()) return null;
  let digits = raw.trim().replace(/[^\d+]/g, '');
  if (digits.startsWith('+')) {
    digits = digits.slice(1);
  }
  // 0086…
  if (digits.startsWith('0086')) {
    digits = digits.slice(4);
  } else if (digits.startsWith('86') && digits.length === 13) {
    digits = digits.slice(2);
  }
  // Local 11-digit CN mobile
  if (/^1[3-9]\d{9}$/.test(digits)) {
    return `+86${digits}`;
  }
  return null;
}

export function isChinaMobile(raw?: string | null): boolean {
  return normalizeChinaMobile(raw) !== null;
}

export const CHINA_PHONE_ONLY_MSG =
  'Phone verification supports China numbers only for now';
