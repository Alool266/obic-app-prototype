// Made by Dr Ali
import { isChinaMobile, normalizeChinaMobile } from './china-phone.util';
import {
  isChinaCohort,
  isChinaRegionCode,
  needsEmailVerification,
  needsPhoneVerification,
  normalizeRegionCode,
  PHONE_VERIFICATION_REQUIRED_MSG,
} from './china-cohort.util';

describe('china-cohort.util', () => {
  it('normalizes country names to ISO', () => {
    expect(normalizeRegionCode('cn')).toBe('CN');
    expect(normalizeRegionCode('China')).toBe('CN');
    expect(normalizeRegionCode('Hong Kong')).toBe('HK');
    expect(normalizeRegionCode('Macau')).toBe('MO');
    expect(isChinaRegionCode('YE')).toBe(false);
  });

  it('flags China cohort from country or CN phone', () => {
    expect(isChinaCohort({ country: 'CN', phone: null })).toBe(true);
    expect(isChinaCohort({ country: 'YE', phone: '+8613812345678' })).toBe(
      true,
    );
    expect(isChinaCohort({ country: 'YE', phone: null })).toBe(false);
    // Language alone is not a cohort signal (no locale field on user).
    expect(isChinaCohort({ country: 'US', phone: null })).toBe(false);
  });

  it('needsEmailVerification for China cohort until email verified', () => {
    expect(
      needsEmailVerification({
        country: 'CN',
        phone: null,
        emailVerifiedAt: null,
      }),
    ).toBe(true);
    expect(
      needsEmailVerification({
        country: 'CN',
        phone: '+8613812345678',
        emailVerifiedAt: new Date(),
      }),
    ).toBe(false);
    expect(
      needsEmailVerification({
        country: 'YE',
        phone: null,
        emailVerifiedAt: null,
      }),
    ).toBe(false);
  });

  it('needsPhoneVerification until CN mobile verified', () => {
    expect(
      needsPhoneVerification({
        country: 'CN',
        phone: null,
        phoneVerifiedAt: null,
      }),
    ).toBe(true);
    expect(
      needsPhoneVerification({
        country: 'CN',
        phone: '+8613812345678',
        phoneVerifiedAt: null,
      }),
    ).toBe(true);
    expect(
      needsPhoneVerification({
        country: 'CN',
        phone: '+8613812345678',
        phoneVerifiedAt: new Date(),
      }),
    ).toBe(false);
    expect(
      needsPhoneVerification({
        country: 'YE',
        phone: null,
        phoneVerifiedAt: null,
      }),
    ).toBe(false);
    expect(isChinaMobile('+8613812345678')).toBe(true);
    expect(normalizeChinaMobile('13812345678')).toBe('+8613812345678');
    expect(PHONE_VERIFICATION_REQUIRED_MSG).toBe('PHONE_VERIFICATION_REQUIRED');
  });
});
