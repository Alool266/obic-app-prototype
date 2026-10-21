// Made by Dr Ali
// A company calendar event on one China-time day. The app does not send an invitation.

export const CALENDAR_TITLE_MAX = 80;
export const CALENDAR_NOTE_MAX = 500;
export const CALENDAR_PER_DAY = 12;
export const CALENDAR_LIST_DAYS = 120;
const MIN_SPAN = 15;
const MAX_SPAN = 12 * 60;
const DATE_RE = /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/;
const CLOCK_RE = /^([01][0-9]|2[0-3]):([0-5][0-9])(?::[0-5][0-9])?$/;

export function normalizeCalendarTitle(value: string): string {
  const title = value.trim().replace(/\s+/g, ' ');
  if (!title || title.length > CALENDAR_TITLE_MAX) throw new Error('CALENDAR_TITLE');
  return title;
}

export function assertCalendarNote(value: string | null | undefined): string | null {
  const note = (value ?? '').trim();
  if (!note) return null;
  if (note.length > CALENDAR_NOTE_MAX) throw new Error('CALENDAR_NOTE');
  return note;
}

export function parseCalendarClock(value: string): number {
  const match = CLOCK_RE.exec(value.trim());
  if (!match) throw new Error('CALENDAR_CLOCK');
  return Number(match[1]) * 60 + Number(match[2]);
}

export function formatCalendarClock(minute: number): string {
  const hour = Math.floor(minute / 60);
  const rest = minute % 60;
  return `${String(hour).padStart(2, '0')}:${String(rest).padStart(2, '0')}`;
}

export function assertCalendarSpan(start: number, end: number): void {
  const length = end - start;
  if (length < MIN_SPAN || length > MAX_SPAN) throw new Error('CALENDAR_SPAN');
}

export function shiftCalendarDate(key: string, days: number): string {
  const [year, month, day] = key.split('-').map((part) => Number(part));
  const utc = new Date(Date.UTC(year, month - 1, day));
  utc.setUTCDate(utc.getUTCDate() + days);
  return utc.toISOString().slice(0, 10);
}

export function assertCalendarDate(date: string, earliest: string, latest: string): void {
  if (!isRealDate(date) || date < earliest || date > latest) throw new Error('CALENDAR_DATE');
}

export function calendarListRange(
  today: string,
  from: string | undefined,
  to: string | undefined,
): { from: string; to: string } {
  const start = (from ?? '').trim() || shiftCalendarDate(today, -7);
  const end = (to ?? '').trim() || shiftCalendarDate(today, 60);
  if (!isRealDate(start) || !isRealDate(end) || start > end) throw new Error('CALENDAR_RANGE');
  const a = Date.parse(`${start}T00:00:00Z`);
  const b = Date.parse(`${end}T00:00:00Z`);
  const days = Math.round((b - a) / 86400000);
  if (days > CALENDAR_LIST_DAYS) throw new Error('CALENDAR_RANGE');
  return { from: start, to: end };
}

function isRealDate(date: string): boolean {
  if (!DATE_RE.test(date)) return false;
  const [year, month, day] = date.split('-').map((part) => Number(part));
  const utc = new Date(Date.UTC(year, month - 1, day));
  return utc.getUTCFullYear() === year && utc.getUTCMonth() === month - 1 && utc.getUTCDate() === day;
}
