// Made by Dr Ali

import { assertTagSelection, normalizeTagName, tagNameKey } from './company-tag';

describe('company tag', () => {
  it('collapses a tag name and treats case as the same tag', () => {
    expect(normalizeTagName('  Key   account ')).toBe('Key account');
    expect(tagNameKey('VIP')).toBe(tagNameKey('vip'));
    expect(() => normalizeTagName('   ')).toThrow('TAG_NAME');
  });

  it('keeps at most eight known tags and allows an empty set', () => {
    const allowed = new Set(['a', 'b']);
    expect(assertTagSelection(['a', 'a', 'b'], allowed)).toEqual(['a', 'b']);
    expect(assertTagSelection([], allowed)).toEqual([]);
    expect(() => assertTagSelection(['c'], allowed)).toThrow('TAG_UNKNOWN');
    expect(() => assertTagSelection(['1', '2', '3', '4', '5', '6', '7', '8', '9'], new Set(['1', '2', '3', '4', '5', '6', '7', '8', '9']))).toThrow(
      'TAG_COUNT',
    );
  });
});
