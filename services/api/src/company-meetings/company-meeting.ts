// Made by Dr Ali
// A richer meeting: time, agenda, attendees, and notes. It does not start a call.

export const MEETING_TITLE_MAX = 80;
export const MEETING_AGENDA_MAX = 1000;
export const MEETING_NOTES_MAX = 2000;
export const MEETING_ATTENDEE_LIMIT = 12;
export const MEETING_PER_DAY = 12;

export function normalizeMeetingTitle(value: string): string {
  const title = value.trim().replace(/\s+/g, ' ');
  if (!title || title.length > MEETING_TITLE_MAX) throw new Error('MEETING_TITLE');
  return title;
}

export function assertMeetingText(
  value: string | null | undefined,
  max: number,
  code: 'MEETING_AGENDA' | 'MEETING_NOTES',
): string | null {
  const text = (value ?? '').trim();
  if (!text) return null;
  if (text.length > max) throw new Error(code);
  return text;
}

export function assertMeetingAttendees(
  ids: readonly string[],
  organizerId: string,
  allowed: ReadonlySet<string>,
): string[] {
  const unique: string[] = [];
  const seen = new Set<string>();
  for (const id of ids) {
    if (id === organizerId || seen.has(id)) continue;
    if (!allowed.has(id)) throw new Error('MEETING_ATTENDEE');
    seen.add(id);
    unique.push(id);
  }
  if (unique.length === 0) throw new Error('MEETING_ATTENDEE');
  if (unique.length > MEETING_ATTENDEE_LIMIT) throw new Error('MEETING_COUNT');
  return unique;
}
