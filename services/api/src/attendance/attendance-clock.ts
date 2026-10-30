// Made by Dr Ali
// Company clock: one calendar day in the company timezone, then on time, late, or early.

export const PUNCH_KINDS = ['in', 'out'] as const;
export type PunchKind = (typeof PUNCH_KINDS)[number];

export const PUNCH_MARKS = ['on_time', 'late', 'early', 'off_day'] as const;
export type PunchMark = (typeof PUNCH_MARKS)[number];

export type ClockRule = {
  timezone: string;
  startMinute: number;
  endMinute: number;
  graceMinutes: number;
  weekdays: number[];
};

export type ZonedParts = {
  workDate: string;
  weekday: number;
  minuteOfDay: number;
};

const WEEKDAY_INDEX: Record<string, number> = {
  Mon: 1,
  Tue: 2,
  Wed: 3,
  Thu: 4,
  Fri: 5,
  Sat: 6,
  Sun: 7,
};

export function isValidTimezone(timezone: string): boolean {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: timezone }).format();
    return true;
  } catch {
    return false;
  }
}

export function assertClockRule(rule: ClockRule): void {
  if (!isValidTimezone(rule.timezone)) {
    throw new Error('INVALID_TIMEZONE');
  }
  const minutesOk = (value: number) =>
    Number.isInteger(value) && value >= 0 && value <= 1439;
  if (
    !minutesOk(rule.startMinute) ||
    !minutesOk(rule.endMinute) ||
    !Number.isInteger(rule.graceMinutes) ||
    rule.graceMinutes < 0 ||
    rule.graceMinutes > 180 ||
    rule.startMinute >= rule.endMinute
  ) {
    throw new Error('INVALID_RULE');
  }
  const days = new Set(rule.weekdays);
  if (days.size !== rule.weekdays.length || days.size < 1) {
    throw new Error('INVALID_RULE');
  }
  for (const day of rule.weekdays) {
    if (!Number.isInteger(day) || day < 1 || day > 7) {
      throw new Error('INVALID_RULE');
    }
  }
}

export function zonedParts(instant: Date, timezone: string): ZonedParts {
  if (!isValidTimezone(timezone)) {
    throw new Error('INVALID_TIMEZONE');
  }
  const workDate = new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(instant);
  const weekdayName = new Intl.DateTimeFormat('en-US', {
    timeZone: timezone,
    weekday: 'short',
  }).format(instant);
  const weekday = WEEKDAY_INDEX[weekdayName];
  if (!weekday) {
    throw new Error('INVALID_TIMEZONE');
  }
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: timezone,
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(instant);
  const hour = Number(parts.find((part) => part.type === 'hour')?.value);
  const minute = Number(parts.find((part) => part.type === 'minute')?.value);
  const hourOfDay = hour === 24 ? 0 : hour;
  return {
    workDate,
    weekday,
    minuteOfDay: hourOfDay * 60 + minute,
  };
}

/** A punch on a rest day stays off_day. Otherwise late is after start plus grace. */
export function classifyPunch(input: {
  kind: PunchKind;
  weekday: number;
  minuteOfDay: number;
  rule: ClockRule;
}): PunchMark {
  if (!input.rule.weekdays.includes(input.weekday)) {
    return 'off_day';
  }
  switch (input.kind) {
    case 'in':
      return input.minuteOfDay >
        input.rule.startMinute + input.rule.graceMinutes
        ? 'late'
        : 'on_time';
    case 'out':
      return input.minuteOfDay < input.rule.endMinute ? 'early' : 'on_time';
    default: {
      const neverKind: never = input.kind;
      throw new Error(neverKind);
    }
  }
}

export function shiftDateKey(key: string, days: number): string {
  const [year, month, day] = key.split('-').map((part) => Number(part));
  const utc = new Date(Date.UTC(year, month - 1, day));
  utc.setUTCDate(utc.getUTCDate() + days);
  return utc.toISOString().slice(0, 10);
}

export function formatMinute(minute: number): string {
  const hour = Math.floor(minute / 60);
  const rest = minute % 60;
  return `${String(hour).padStart(2, '0')}:${String(rest).padStart(2, '0')}`;
}

export function formatWeekdays(days: number[]): string {
  return [...new Set(days)].sort((a, b) => a - b).join(',');
}

export function parseWeekdays(raw: string): number[] {
  return raw
    .split(',')
    .map((part) => Number(part.trim()))
    .filter((day) => Number.isInteger(day));
}
