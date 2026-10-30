// Made by Dr Ali

import {
  assertContactName,
  assertContactText,
  normalizeContactPhone,
} from './company-contact';

describe('company contact', () => {
  it('keeps a name and drops a blank phone', () => {
    expect(assertContactName('  North Shop  ')).toBe('North Shop');
    expect(normalizeContactPhone('   ')).toBeNull();
  });

  it('stores a phone as digits', () => {
    expect(normalizeContactPhone('+86 138-0000-0000')).toBe('+8613800000000');
    expect(() => normalizeContactPhone('123')).toThrow('CONTACT_PHONE');
  });

  it('drops a blank organization and rejects a long note', () => {
    expect(assertContactText('  ', 80, 'CONTACT_ORG')).toBeNull();
    expect(() => assertContactText('x'.repeat(501), 500, 'CONTACT_NOTE')).toThrow('CONTACT_NOTE');
  });
});
