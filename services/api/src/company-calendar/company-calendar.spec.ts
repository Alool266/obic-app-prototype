// Made by Dr Ali

import {
  assertCalendarDate,
  assertCalendarNote,
  assertCalendarSpan,
  calendarListRange,
  formatCalendarClock,
  normalizeCalendarTitle,
  parseCalendarClock,
} from './company-calendar';

describe('company calendar', () => {
  it('collapses a title and drops a blank note', () => {
    expect(normalizeCalendarTitle('  Team   standup ')).toBe('Team standup');
    expect(() => normalizeCalendarTitle('  ')).toThrow('CALENDAR_TITLE');
    expect(assertCalendarNote('  ')).toBeNull();
    expect(() => assertCalendarNote('x'.repeat(501))).toThrow('CALENDAR_NOTE');
  });

  it('reads a clock and keeps an event between 15 minutes and 12 hours', () => {
    expect(parseCalendarClock('09:30')).toBe(9 * 60 + 30);
    expect(formatCalendarClock(9 * 60 + 30)).toBe('09:30');
    expect(() => parseCalendarClock('9:30')).toThrow('CALENDAR_CLOCK');
    expect(() => assertCalendarSpan(9 * 60, 9 * 60 + 10)).toThrow('CALENDAR_SPAN');
    expect(() => assertCalendarSpan(9 * 60, 9 * 60 + 15)).not.toThrow();
  });

  it('keeps a date inside the window and a short list range', () => {
    expect(() => assertCalendarDate('2026-10-05', '2026-09-05', '2027-04-03')).not.toThrow();
    expect(() => assertCalendarDate('2026-02-31', '2026-01-01', '2026-12-31')).toThrow('CALENDAR_DATE');
    expect(calendarListRange('2026-10-05', '', '').from).toBe('2026-09-28');
    expect(() => calendarListRange('2026-10-05', '2026-01-01', '2026-08-01')).toThrow('CALENDAR_RANGE');
  });
});
