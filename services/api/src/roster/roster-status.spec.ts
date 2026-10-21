// Made by Dr Ali

import {
  assertRosterDate,
  nextCancelledLeave,
  nextConfirmedLeave,
  nextJoin,
  nextLeaveRequest,
} from './roster-status';

describe('roster status', () => {
  it('records a first join and a join after someone has left', () => {
    expect(nextJoin(null)).toBe('active');
    expect(nextJoin('left')).toBe('active');
  });

  it('refuses a second join while the person is still employed', () => {
    expect(() => nextJoin('active')).toThrow('ALREADY_EMPLOYED');
    expect(() => nextJoin('leaving')).toThrow('ALREADY_EMPLOYED');
  });

  it('walks an open leave request to confirmed or cancelled', () => {
    expect(nextLeaveRequest('active')).toBe('leaving');
    expect(nextConfirmedLeave('leaving')).toBe('left');
    expect(nextCancelledLeave('leaving')).toBe('active');
    expect(() => nextLeaveRequest('left')).toThrow('LEAVE_NOT_OPEN');
    expect(() => nextConfirmedLeave('active')).toThrow('LEAVE_NOT_PENDING');
  });

  it('keeps a date inside the allowed window', () => {
    expect(() => assertRosterDate('2026-10-05', '2026-10-05', '2027-10-05')).not.toThrow();
    expect(() => assertRosterDate('2026-10-04', '2026-10-05', '2027-10-05')).toThrow(
      'ROSTER_DATE',
    );
  });
});
