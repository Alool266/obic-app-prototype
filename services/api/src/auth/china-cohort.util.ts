// Made by Dr Ali
// China cohort — CN / HK / MO region or China mainland mobile.

import { isChinaMobile } from './china-phone.util';
import { User } from '../users/user.entity';

const CHINA_REGION_CODES = new Set(['CN', 'HK', 'MO']);

/** Normalize profile country / ISO code → uppercase alpha-2 when possible. */
export function normalizeRegionCode(raw?: string | null): string | null {
  if (!raw?.trim()) return null;
  const t = raw.trim();
  const upper = t.toUpperCase();
  if (/^[A-Z]{2}$/.test(upper)) return upper;
  const lower = t.toLowerCase();
  if (
    lower === 'china' ||
    lower === 'prc' ||
    lower.includes('中国') ||
    lower.includes('mainland')
  ) {
    return 'CN';
  }
  if (
    lower === 'hong kong' ||
    lower === 'hongkong' ||
    lower.includes('香港')
  ) {
    return 'HK';
  }
  if (lower === 'macao' || lower === 'macau' || lower.includes('澳门')) {
    return 'MO';
  }
  return null;
}

export function isChinaRegionCode(raw?: string | null): boolean {
  const code = normalizeRegionCode(raw);
  return code != null && CHINA_REGION_CODES.has(code);
}

/**
 * User is in the China verification cohort when:
 * - profile country is CN/HK/MO (or common names), or
 * - account already has a China mainland mobile (+86).
 */
export function isChinaCohort(user: Pick<User, 'country' | 'phone'>): boolean {
  if (isChinaRegionCode(user.country)) return true;
  if (isChinaMobile(user.phone)) return true;
  return false;
}

/**
 * China cohort must have a verified China mainland mobile before full use.
 */
export function needsPhoneVerification(
  user: Pick<User, 'country' | 'phone' | 'phoneVerifiedAt'>,
): boolean {
  if (!isChinaCohort(user)) return false;
  if (!user.phone || !isChinaMobile(user.phone)) return true;
  return !user.phoneVerifiedAt;
}

export const PHONE_VERIFICATION_REQUIRED_MSG =
  'PHONE_VERIFICATION_REQUIRED';
