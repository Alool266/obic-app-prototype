// Made by Dr Ali
// Unit tests for Moments notify recipient filter (global + per-friend mute).

import {
  filterMomentNotifyRecipients,
  shouldReceiveMomentNotify,
} from './moment-notify-filter';

describe('filterMomentNotifyRecipients', () => {
  it('keeps recipients with no prefs (default notify on)', () => {
    expect(
      filterMomentNotifyRecipients(['a', 'b'], 'author', [], []),
    ).toEqual(['a', 'b']);
  });

  it('excludes author', () => {
    expect(
      filterMomentNotifyRecipients(['author', 'a'], 'author', [], []),
    ).toEqual(['a']);
  });

  it('excludes muteUpdates and notifyEnabled=false', () => {
    expect(
      filterMomentNotifyRecipients(
        ['muted-all', 'off', 'ok'],
        'author',
        [
          { userId: 'muted-all', notifyEnabled: false, muteUpdates: true },
          { userId: 'off', notifyEnabled: false, muteUpdates: false },
          { userId: 'ok', notifyEnabled: true, muteUpdates: false },
        ],
        [],
      ),
    ).toEqual(['ok']);
  });

  it('excludes per-friend mute for this author', () => {
    expect(
      filterMomentNotifyRecipients(
        ['friend', 'other'],
        'author',
        [{ userId: 'friend', notifyEnabled: true, muteUpdates: false }],
        [{ userId: 'friend', mutedFriendId: 'author' }],
      ),
    ).toEqual(['other']);
  });
});

describe('shouldReceiveMomentNotify', () => {
  it('false for self', () => {
    expect(shouldReceiveMomentNotify('me', 'me', null, false)).toBe(false);
  });

  it('false when friend muted', () => {
    expect(shouldReceiveMomentNotify('me', 'friend', null, true)).toBe(false);
  });

  it('false when global mute', () => {
    expect(
      shouldReceiveMomentNotify(
        'me',
        'friend',
        { userId: 'me', notifyEnabled: false, muteUpdates: true },
        false,
      ),
    ).toBe(false);
  });

  it('true by default', () => {
    expect(shouldReceiveMomentNotify('me', 'friend', null, false)).toBe(true);
  });
});
