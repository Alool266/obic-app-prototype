import { normalizeSmsMobile, smsCountryOf } from './sms-phone.util';

describe('normalizeSmsMobile', () => {
  it('accepts China, Saudi Arabia, and Yemen', () => {
    expect(normalizeSmsMobile('+8613812345678')).toBe('+8613812345678');
    expect(normalizeSmsMobile('13812345678')).toBe('+8613812345678');
    expect(normalizeSmsMobile('+966512345678')).toBe('+966512345678');
    expect(normalizeSmsMobile('0512345678')).toBe('+966512345678');
    expect(normalizeSmsMobile('+967712345678')).toBe('+967712345678');
    expect(normalizeSmsMobile('0712345678')).toBe('+967712345678');
  });

  it('rejects other countries', () => {
    expect(normalizeSmsMobile('+14155552671')).toBeNull();
    expect(normalizeSmsMobile('+85291234567')).toBeNull();
  });

  it('labels the country', () => {
    expect(smsCountryOf('+8613812345678')).toBe('CN');
    expect(smsCountryOf('+966512345678')).toBe('SA');
    expect(smsCountryOf('+967712345678')).toBe('YE');
  });
});
