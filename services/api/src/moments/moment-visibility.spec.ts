// Made by Dr Ali
// WeChat Moments visibility ACL unit tests.

import {
  MOMENT_VISIBILITY_EXCLUDE,
  MOMENT_VISIBILITY_FRIENDS,
  MOMENT_VISIBILITY_PARTIAL,
  MOMENT_VISIBILITY_PRIVATE,
  MOMENT_VISIBILITY_PUBLIC,
  canViewerSeeMoment,
  isMomentPublic,
  momentNotifyAudienceIds,
  momentVisibilityForRole,
} from './moment-visibility';

describe('moment visibility (WeChat 朋友圈)', () => {
  it('staff → public; customer → friends', () => {
    expect(momentVisibilityForRole(true)).toBe(MOMENT_VISIBILITY_PUBLIC);
    expect(momentVisibilityForRole(false)).toBe(MOMENT_VISIBILITY_FRIENDS);
  });

  it('public admin moment visible to stranger (guest + non-friend)', () => {
    const adminMoment = {
      authorId: 'admin',
      visibility: MOMENT_VISIBILITY_PUBLIC,
      notifyAll: true,
    };
    expect(isMomentPublic(adminMoment)).toBe(true);
    expect(canViewerSeeMoment(adminMoment, null, new Set())).toBe(true);
    expect(canViewerSeeMoment(adminMoment, 'stranger', new Set())).toBe(true);
  });

  it('user A friends moment visible to mutual friend B', () => {
    const aMoment = {
      authorId: 'user-a',
      visibility: MOMENT_VISIBILITY_FRIENDS,
      notifyAll: false,
    };
    const friendsOfB = new Set(['user-a']);
    expect(canViewerSeeMoment(aMoment, 'user-b', friendsOfB)).toBe(true);
    expect(canViewerSeeMoment(aMoment, 'user-a', new Set())).toBe(true);
  });

  it('user A friends moment NOT visible to non-friend C', () => {
    const aMoment = {
      authorId: 'user-a',
      visibility: MOMENT_VISIBILITY_FRIENDS,
      notifyAll: false,
    };
    expect(canViewerSeeMoment(aMoment, 'user-c', new Set(['other']))).toBe(
      false,
    );
    expect(canViewerSeeMoment(aMoment, null, new Set())).toBe(false);
  });

  it('soft-deleted moments are hidden', () => {
    expect(
      canViewerSeeMoment(
        {
          authorId: 'admin',
          visibility: MOMENT_VISIBILITY_PUBLIC,
          deletedAt: new Date(),
        },
        'anyone',
        new Set(),
      ),
    ).toBe(false);
  });

  it('legacy notifyAll still counts as public', () => {
    expect(
      isMomentPublic({ visibility: MOMENT_VISIBILITY_FRIENDS, notifyAll: true }),
    ).toBe(true);
  });

  it('private — author only', () => {
    const m = {
      authorId: 'a',
      visibility: MOMENT_VISIBILITY_PRIVATE,
    };
    expect(canViewerSeeMoment(m, 'a', new Set())).toBe(true);
    expect(canViewerSeeMoment(m, 'friend', new Set(['a']))).toBe(false);
  });

  it('partial — only allowed friends', () => {
    const m = {
      authorId: 'a',
      visibility: MOMENT_VISIBILITY_PARTIAL,
      allowedUserIds: ['b'],
    };
    expect(canViewerSeeMoment(m, 'b', new Set(['a']))).toBe(true);
    expect(canViewerSeeMoment(m, 'c', new Set(['a']))).toBe(false);
    expect(canViewerSeeMoment(m, 'a', new Set())).toBe(true);
  });

  it('exclude — friends except denied', () => {
    const m = {
      authorId: 'a',
      visibility: MOMENT_VISIBILITY_EXCLUDE,
      deniedUserIds: ['c'],
    };
    expect(canViewerSeeMoment(m, 'b', new Set(['a']))).toBe(true);
    expect(canViewerSeeMoment(m, 'c', new Set(['a']))).toBe(false);
  });

  it('mute (不看他) hides non-public from muted author', () => {
    const m = {
      authorId: 'a',
      visibility: MOMENT_VISIBILITY_FRIENDS,
    };
    expect(
      canViewerSeeMoment(m, 'b', new Set(['a']), {
        mutedAuthorIds: new Set(['a']),
      }),
    ).toBe(false);
    // Author still sees own.
    expect(
      canViewerSeeMoment(m, 'a', new Set(), {
        mutedAuthorIds: new Set(['a']),
      }),
    ).toBe(true);
  });

  it('hide-from (不让他看) blocks viewer', () => {
    const m = {
      authorId: 'a',
      visibility: MOMENT_VISIBILITY_FRIENDS,
    };
    expect(
      canViewerSeeMoment(m, 'b', new Set(['a']), {
        authorsHidingViewer: new Set(['a']),
      }),
    ).toBe(false);
  });

  it('notify audience respects privacy modes', () => {
    expect(
      momentNotifyAudienceIds(MOMENT_VISIBILITY_PRIVATE, ['b', 'c'], [], []),
    ).toEqual([]);
    expect(
      momentNotifyAudienceIds(
        MOMENT_VISIBILITY_PARTIAL,
        ['b', 'c'],
        ['b'],
        [],
      ),
    ).toEqual(['b']);
    expect(
      momentNotifyAudienceIds(
        MOMENT_VISIBILITY_EXCLUDE,
        ['b', 'c'],
        [],
        ['c'],
      ),
    ).toEqual(['b']);
    expect(
      momentNotifyAudienceIds(MOMENT_VISIBILITY_PUBLIC, ['b'], [], []),
    ).toBe('all');
  });
});
