// Made by Dr Ali
import { firstBannedHit, normalizeForFilter } from './word-matcher';

describe('word matcher', () => {
  it('normalizes case and extra spaces', () => {
    expect(normalizeForFilter('  Sell   Cocaine  ')).toBe('sell cocaine');
  });

  it('hits a banned English phrase', () => {
    expect(
      firstBannedHit('I can sell cocaine tonight', ['sell cocaine']),
    ).toBe('sell cocaine');
  });

  it('hits Arabic without needing Latin', () => {
    expect(
      firstBannedHit('عرض هيروين رخيص', ['هيروين']),
    ).toBe('هيروين');
  });

  it('ignores clean chat', () => {
    expect(
      firstBannedHit('Hotel in Guangzhou please', ['sell cocaine', 'هيروين']),
    ).toBeNull();
  });

  it('hits hate and violence phrases', () => {
    expect(
      firstBannedHit('this is a hate crime', ['hate crime']),
    ).toBe('hate crime');
    expect(
      firstBannedHit('تحريض على العنف الآن', ['تحريض على العنف']),
    ).toBe('تحريض على العنف');
  });
});
