// Made by Dr Ali

import {
  assertHandoverIds,
  assertHandoverParties,
  assertOptionalStaffId,
  HANDOVER_LIMIT,
} from './company-handover';

const STAFF = '6f0e2a10-0004-4000-8000-000000000001';

describe('company handover', () => {
  it('rejects a move to the same person', () => {
    expect(() => assertHandoverParties(STAFF, STAFF)).toThrow('HANDOVER_SAME');
    expect(() => assertHandoverParties(STAFF, `${STAFF.slice(0, -1)}2`)).not.toThrow();
  });

  it('keeps one copy of each contact and caps the batch', () => {
    expect(assertHandoverIds([STAFF, STAFF])).toEqual([STAFF]);
    expect(() => assertHandoverIds([])).toThrow('HANDOVER_EMPTY');
    const tooMany = Array.from(
      { length: HANDOVER_LIMIT + 1 },
      (_, index) => `6f0e2a10-0004-4000-8000-${index.toString(16).padStart(12, '0')}`,
    );
    expect(() => assertHandoverIds(tooMany)).toThrow('HANDOVER_COUNT');
  });

  it('accepts a blank staff filter and rejects a bad id', () => {
    expect(assertOptionalStaffId('  ')).toBeNull();
    expect(assertOptionalStaffId(STAFF)).toBe(STAFF);
    expect(() => assertOptionalStaffId('not-a-person')).toThrow('HANDOVER_STAFF');
  });
});
