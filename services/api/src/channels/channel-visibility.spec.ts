// Made by Dr Ali
import { UserRole } from '../common/enums/user-role.enum';
import {
  canPostOnOfficial,
  canViewerSeeChannelContent,
} from './channel-visibility';

describe('channel-visibility', () => {
  const official = { official: true, ownerUserId: null as string | null };
  const personal = {
    official: false,
    ownerUserId: 'owner-1',
  };

  it('official is public to guests', () => {
    expect(
      canViewerSeeChannelContent({
        channel: official,
        viewerId: null,
        friendOwnerIds: new Set(),
      }),
    ).toBe(true);
  });

  it('personal hidden from guests and strangers', () => {
    expect(
      canViewerSeeChannelContent({
        channel: personal,
        viewerId: null,
        friendOwnerIds: new Set(),
      }),
    ).toBe(false);
    expect(
      canViewerSeeChannelContent({
        channel: personal,
        viewerId: 'stranger',
        friendOwnerIds: new Set(['other']),
      }),
    ).toBe(false);
  });

  it('personal visible to owner and friends', () => {
    expect(
      canViewerSeeChannelContent({
        channel: personal,
        viewerId: 'owner-1',
        friendOwnerIds: new Set(),
      }),
    ).toBe(true);
    expect(
      canViewerSeeChannelContent({
        channel: personal,
        viewerId: 'friend-1',
        friendOwnerIds: new Set(['owner-1']),
      }),
    ).toBe(true);
  });

  it('only staff may post on official', () => {
    expect(canPostOnOfficial(UserRole.Customer)).toBe(false);
    expect(canPostOnOfficial(UserRole.Employee)).toBe(true);
    expect(canPostOnOfficial(UserRole.SuperAdmin)).toBe(true);
  });
});
