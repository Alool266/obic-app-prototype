// Made by Dr Ali

import {
  assertMeetingAttendees,
  assertMeetingText,
  MEETING_AGENDA_MAX,
  normalizeMeetingTitle,
} from './company-meeting';

const ALI = '6f0e2a10-0006-4000-8000-000000000001';
const SARA = '6f0e2a10-0006-4000-8000-000000000002';

describe('company meeting', () => {
  it('collapses a title and keeps a blank agenda empty', () => {
    expect(normalizeMeetingTitle('  Weekly   review ')).toBe('Weekly review');
    expect(() => normalizeMeetingTitle('  ')).toThrow('MEETING_TITLE');
    expect(assertMeetingText('  ', MEETING_AGENDA_MAX, 'MEETING_AGENDA')).toBeNull();
    expect(() => assertMeetingText('x'.repeat(MEETING_AGENDA_MAX + 1), MEETING_AGENDA_MAX, 'MEETING_AGENDA')).toThrow(
      'MEETING_AGENDA',
    );
  });

  it('drops the organizer and keeps the other staff once', () => {
    const allowed = new Set([ALI, SARA]);
    expect(assertMeetingAttendees([ALI, SARA, SARA], ALI, allowed)).toEqual([SARA]);
    expect(() => assertMeetingAttendees([ALI], ALI, allowed)).toThrow('MEETING_ATTENDEE');
  });

  it('stops at 12 people besides the organizer', () => {
    const ids = Array.from(
      { length: 13 },
      (_, index) => `6f0e2a10-0006-4000-8000-${String(index + 2).padStart(12, '0')}`,
    );
    expect(() => assertMeetingAttendees(ids, ALI, new Set(ids))).toThrow('MEETING_COUNT');
  });
});
