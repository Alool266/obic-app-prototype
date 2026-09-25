// Made by Dr Ali
// OBIC ID validation + once-per-year change rule.

import {
  OBIC_ID_CHANGE_COOLDOWN_DAYS,
  decideObicIdChange,
  isValidObicId,
  normalizeObicId,
  nextObicIdChangeAt,
} from './obic-id.util';

describe('obic-id util', () => {
  it('normalizes to lowercase', () => {
    expect(normalizeObicId('  Ali_Boss ')).toBe('ali_boss');
  });

  it('accepts WeChat-like handles', () => {
    expect(isValidObicId('alicn1')).toBe(true);
    expect(isValidObicId('a12345')).toBe(true);
    expect(isValidObicId('obic_user_01')).toBe(true);
  });

  it('rejects invalid handles', () => {
    expect(isValidObicId('ab')).toBe(false);
    expect(isValidObicId('1abcde')).toBe(false);
    expect(isValidObicId('ali-boss')).toBe(false);
    expect(isValidObicId('ali boss')).toBe(false);
  });

  it('allows first set freely', () => {
    const d = decideObicIdChange({
      current: null,
      nextRaw: 'MyObic1',
      changedAt: null,
    });
    expect(d).toEqual({
      ok: true,
      normalized: 'myobic1',
      isFirstSet: true,
    });
  });

  it('treats same id as unchanged', () => {
    const d = decideObicIdChange({
      current: 'myobic1',
      nextRaw: 'MyObic1',
      changedAt: new Date('2024-01-01T00:00:00Z'),
    });
    expect(d).toEqual({ ok: false, reason: 'unchanged' });
  });

  it('blocks change within 365 days', () => {
    const changedAt = new Date('2025-01-01T00:00:00Z');
    const now = new Date('2025-06-01T00:00:00Z');
    const d = decideObicIdChange({
      current: 'oldid1',
      nextRaw: 'newid1',
      changedAt,
      now,
    });
    expect(d.ok).toBe(false);
    if (!d.ok) {
      expect(d.reason).toBe('cooldown');
      expect(d.nextAt?.toISOString()).toBe(
        nextObicIdChangeAt(changedAt)?.toISOString(),
      );
    }
  });

  it('allows change after cooldown', () => {
    const changedAt = new Date('2024-01-01T00:00:00Z');
    const now = new Date(changedAt);
    now.setUTCDate(now.getUTCDate() + OBIC_ID_CHANGE_COOLDOWN_DAYS);
    const d = decideObicIdChange({
      current: 'oldid1',
      nextRaw: 'newid1',
      changedAt,
      now,
    });
    expect(d).toEqual({
      ok: true,
      normalized: 'newid1',
      isFirstSet: false,
    });
  });
});
