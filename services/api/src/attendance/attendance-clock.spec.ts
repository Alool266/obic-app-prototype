// Made by Dr Ali

import {
  assertClockRule,
  classifyPunch,
  shiftDateKey,
  zonedParts,
  type ClockRule,
} from './attendance-clock';

const office: ClockRule = {
  timezone: 'Asia/Shanghai',
  startMinute: 9 * 60,
  endMinute: 18 * 60,
  graceMinutes: 0,
  weekdays: [1, 2, 3, 4, 5],
};

describe('attendance clock', () => {
  it('reads the company calendar, not the server timezone', () => {
    const parts = zonedParts(
      new Date('2026-10-05T01:30:00.000Z'),
      'Asia/Shanghai',
    );
    expect(parts).toEqual({
      workDate: '2026-10-05',
      weekday: 1,
      minuteOfDay: 9 * 60 + 30,
    });
  });

  it('keeps a punch after midnight on the next company day', () => {
    const parts = zonedParts(
      new Date('2026-10-04T16:30:00.000Z'),
      'Asia/Shanghai',
    );
    expect(parts.workDate).toBe('2026-10-05');
    expect(parts.minuteOfDay).toBe(30);
  });

  it('marks a clock-in after the start as late, and the grace minute as on time', () => {
    expect(
      classifyPunch({
        kind: 'in',
        weekday: 1,
        minuteOfDay: 9 * 60 + 1,
        rule: office,
      }),
    ).toBe('late');
    expect(
      classifyPunch({
        kind: 'in',
        weekday: 1,
        minuteOfDay: 9 * 60 + 10,
        rule: { ...office, graceMinutes: 10 },
      }),
    ).toBe('on_time');
  });

  it('marks a clock-out before the end as early', () => {
    expect(
      classifyPunch({
        kind: 'out',
        weekday: 1,
        minuteOfDay: 17 * 60 + 59,
        rule: office,
      }),
    ).toBe('early');
    expect(
      classifyPunch({
        kind: 'out',
        weekday: 1,
        minuteOfDay: 18 * 60,
        rule: office,
      }),
    ).toBe('on_time');
  });

  it('marks a rest-day punch as off the schedule', () => {
    expect(
      classifyPunch({
        kind: 'in',
        weekday: 6,
        minuteOfDay: 9 * 60,
        rule: office,
      }),
    ).toBe('off_day');
  });

  it('rejects a day that ends before it starts', () => {
    expect(() =>
      assertClockRule({ ...office, startMinute: 18 * 60, endMinute: 9 * 60 }),
    ).toThrow('INVALID_RULE');
  });

  it('shifts a date key without crossing into the wrong month', () => {
    expect(shiftDateKey('2026-10-01', -1)).toBe('2026-09-30');
  });
});
