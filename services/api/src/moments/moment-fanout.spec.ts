// Made by Dr Ali
import { momentNotifyCandidateMode } from './moment-fanout';

describe('moment fan-out mode', () => {
  it('staff/official → all users; customers → friends only', () => {
    expect(momentNotifyCandidateMode(true)).toBe('all');
    expect(momentNotifyCandidateMode(false)).toBe('friends');
  });
});
