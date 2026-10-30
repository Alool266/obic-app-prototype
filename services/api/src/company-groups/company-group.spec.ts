// Made by Dr Ali

import { assertGroupMembers, assertGroupNote, groupNameKey, normalizeGroupName } from './company-group';

describe('company group', () => {
  it('collapses a group name and treats case as the same group', () => {
    expect(normalizeGroupName('  Fair   buyers ')).toBe('Fair buyers');
    expect(groupNameKey('VIP')).toBe(groupNameKey('vip'));
    expect(assertGroupNote('  ')).toBeNull();
  });

  it('keeps contacts that belong to the owner and allows an empty group', () => {
    const allowed = new Set(['a', 'b']);
    expect(assertGroupMembers(['a', 'a'], allowed)).toEqual(['a']);
    expect(assertGroupMembers([], allowed)).toEqual([]);
    expect(() => assertGroupMembers(['c'], allowed)).toThrow('GROUP_MEMBER');
  });
});
