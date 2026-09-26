// Made by Dr Ali
// China cohort — CN / HK / MO region or China mainland mobile.

import { UserRole } from '../common/enums/user-role.enum';
import { isChinaMobile } from './china-phone.util';
import { User } from '../users/user.entity';

const CHINA_REGION_CODES = new Set(['CN', 'HK', 'MO']);

/** SuperAdmin is never blocked by China email/phone verification gates. */
export function isVerificationExempt(
  user: Pick<User, 'role'> | { role?: string | null },
): boolean {
  return user.role === UserRole.SuperAdmin;
}

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
 * Locale / UI language is never a signal (diaspora may use Chinese UI abroad).
 */
export function isChinaCohort(user: Pick<User, 'country' | 'phone'>): boolean {
  if (isChinaRegionCode(user.country)) return true;
  if (isChinaMobile(user.phone)) return true;
  return false;
}

/**
 * China cohort must verify email before full use (Resend OTP).
 * Non-China users are not newly forced — register/login email rules stay as-is.
 * SuperAdmin is exempt (staff desk must not be blocked by China gates).
 */
export function needsEmailVerification(
  user: Pick<User, 'country' | 'phone' | 'emailVerifiedAt'> &
    Partial<Pick<User, 'role'>>,
): boolean {
  if (isVerificationExempt(user)) return false;
  if (!isChinaCohort(user)) return false;
  return !user.emailVerifiedAt;
}

/**
 * China cohort must have a verified China mainland mobile before full use.
 * SuperAdmin is exempt.
 */
export function needsPhoneVerification(
  user: Pick<User, 'country' | 'phone' | 'phoneVerifiedAt'> &
    Partial<Pick<User, 'role'>>,
): boolean {
  if (isVerificationExempt(user)) return false;
  if (!isChinaCohort(user)) return false;
  if (!user.phone || !isChinaMobile(user.phone)) return true;
  return !user.phoneVerifiedAt;
}

export const EMAIL_VERIFICATION_REQUIRED_MSG =
  'EMAIL_VERIFICATION_REQUIRED';

export const PHONE_VERIFICATION_REQUIRED_MSG =
  'PHONE_VERIFICATION_REQUIRED';
