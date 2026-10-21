// Made by Dr Ali

import { assertBookingWindow, bookingsOverlap } from './meeting-slot';

const at = (hour: number, minute = 0) =>
  new Date(Date.UTC(2026, 9, 5, hour, minute));

describe('meeting slots', () => {
  it('lets the next meeting start when the previous one ends', () => {
    expect(
      bookingsOverlap(
        { start: at(10), end: at(11) },
        { start: at(11), end: at(12) },
      ),
    ).toBe(false);
  });

  it('rejects a booking that starts during another', () => {
    expect(
      bookingsOverlap(
        { start: at(10), end: at(11) },
        { start: at(10, 30), end: at(11, 30) },
      ),
    ).toBe(true);
  });

  it('accepts 15 minutes and 8 hours, and rejects shorter, longer, past, or far ahead', () => {
    const now = at(9);
    expect(() =>
      assertBookingWindow({ start: at(10), end: at(10, 15), now }),
    ).not.toThrow();
    expect(() =>
      assertBookingWindow({ start: at(10), end: at(18), now }),
    ).not.toThrow();
    expect(() =>
      assertBookingWindow({ start: at(10), end: at(10, 14), now }),
    ).toThrow('BOOKING_LENGTH');
    expect(() =>
      assertBookingWindow({ start: at(8), end: at(9), now }),
    ).toThrow('BOOKING_PAST');
    expect(() =>
      assertBookingWindow({
        start: new Date(now.getTime() + 31 * 24 * 60 * 60 * 1000),
        end: new Date(now.getTime() + 31 * 24 * 60 * 60 * 1000 + 60 * 60 * 1000),
        now,
      }),
    ).toThrow('BOOKING_HORIZON');
  });
});
