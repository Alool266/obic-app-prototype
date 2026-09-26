// Made by Dr Ali
// WeChat-style Channel visibility: official = public; personal = friends + owner.

import { UserRole } from '../common/enums/user-role.enum';
import { Channel } from './channel.entity';
import { ChannelVideo } from './channel-video.entity';

export type ChannelFeedTab = 'follow' | 'nearby' | 'friends' | 'hot';

export function isChannelFeedTab(raw: string): raw is ChannelFeedTab {
  return (
    raw === 'follow' ||
    raw === 'nearby' ||
    raw === 'friends' ||
    raw === 'hot'
  );
}

/**
 * Personal channel content is friends-only (owner always).
 * Official OBIC channel is public (including guests).
 */
export function canViewerSeeChannelContent(opts: {
  channel: Pick<Channel, 'official' | 'ownerUserId'>;
  viewerId: string | null | undefined;
  friendOwnerIds: Set<string>;
}): boolean {
  if (opts.channel.official) return true;
  const ownerId = opts.channel.ownerUserId;
  if (!ownerId) return false;
  if (!opts.viewerId) return false;
  if (opts.viewerId === ownerId) return true;
  return opts.friendOwnerIds.has(ownerId);
}

export function canViewerSeeVideo(opts: {
  video: Pick<ChannelVideo, 'authorId' | 'channelId'>;
  channel: Pick<Channel, 'official' | 'ownerUserId'>;
  viewerId: string | null | undefined;
  friendOwnerIds: Set<string>;
}): boolean {
  return canViewerSeeChannelContent({
    channel: opts.channel,
    viewerId: opts.viewerId,
    friendOwnerIds: opts.friendOwnerIds,
  });
}

/** Staff who may post on the official OBIC channel. */
export function canPostOnOfficial(
  role: UserRole | string | undefined | null,
): boolean {
  return role === UserRole.SuperAdmin || role === UserRole.Employee;
}
