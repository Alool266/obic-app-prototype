// Made by Dr Ali
// OBIC ID (WeChat-style vanity handle) — validation + once-per-year change rule.

export const OBIC_ID_MIN = 6;
export const OBIC_ID_MAX = 20;
/** Calendar year between changes after the first set. */
export const OBIC_ID_CHANGE_COOLDOWN_DAYS = 365;

const OBIC_ID_RE = /^[a-z][a-z0-9_]{5,19}$/;

export type ObicIdChangeDecision =
  | { ok: true; normalized: string; isFirstSet: boolean }
  | { ok: false; reason: 'invalid' | 'unchanged' | 'cooldown'; nextAt?: Date };

/** Normalize for storage / uniqueness (lowercase trim). */
export function normalizeObicId(raw: string): string {
  return raw.trim().toLowerCase();
}

export function isValidObicId(normalized: string): boolean {
  return (
    normalized.length >= OBIC_ID_MIN &&
    normalized.length <= OBIC_ID_MAX &&
    OBIC_ID_RE.test(normalized)
  );
}

/**
 * Decide whether an OBIC ID update is allowed.
 * - First set (current empty): always allowed if valid.
 * - Same value: unchanged (no cooldown tick).
 * - Change within 365 days of last change: blocked.
 */
export function decideObicIdChange(opts: {
  current: string | null | undefined;
  nextRaw: string;
  changedAt: Date | null | undefined;
  now?: Date;
}): ObicIdChangeDecision {
  const now = opts.now ?? new Date();
  const normalized = normalizeObicId(opts.nextRaw);
  if (!isValidObicId(normalized)) {
    return { ok: false, reason: 'invalid' };
  }

  const current = opts.current ? normalizeObicId(opts.current) : '';
  if (current === normalized) {
    return { ok: false, reason: 'unchanged' };
  }

  const isFirstSet = current.length === 0;
  if (isFirstSet) {
    return { ok: true, normalized, isFirstSet: true };
  }

  if (opts.changedAt) {
    const nextAt = new Date(opts.changedAt);
    nextAt.setUTCDate(nextAt.getUTCDate() + OBIC_ID_CHANGE_COOLDOWN_DAYS);
    if (now.getTime() < nextAt.getTime()) {
      return { ok: false, reason: 'cooldown', nextAt };
    }
  }

  return { ok: true, normalized, isFirstSet: false };
}

export function nextObicIdChangeAt(
  changedAt: Date | null | undefined,
): Date | null {
  if (!changedAt) return null;
  const next = new Date(changedAt);
  next.setUTCDate(next.getUTCDate() + OBIC_ID_CHANGE_COOLDOWN_DAYS);
  return next;
}
