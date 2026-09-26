// Made by Dr Ali
// Channels — per-user + official OBIC, feed tabs, follow, engagement.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { UserRole } from '../common/enums/user-role.enum';
import { FriendsService } from '../friends/friends.service';
import { ModerationService } from '../moderation/moderation.service';
import { ReportTargetType } from '../moderation/content-report.entity';
import { User } from '../users/user.entity';
import { Channel } from './channel.entity';
import { ChannelFollow } from './channel-follow.entity';
import { ChannelVideo } from './channel-video.entity';
import { ChannelVideoComment } from './channel-video-comment.entity';
import { ChannelVideoLike } from './channel-video-like.entity';
import {
  canPostOnOfficial,
  canViewerSeeChannelContent,
  ChannelFeedTab,
} from './channel-visibility';
import {
  CHANNEL_VIDEO_MAX_BYTES,
  CHANNEL_VIDEO_MAX_DURATION_SEC,
  CreateChannelVideoDto,
} from './dto/create-channel-video.dto';
import { CreateChannelCommentDto } from './dto/create-channel-comment.dto';

const OBIC_SLUG = 'obic';

@Injectable()
export class ChannelsService {
  constructor(
    @InjectRepository(Channel)
    private readonly channels: Repository<Channel>,
    @InjectRepository(ChannelFollow)
    private readonly follows: Repository<ChannelFollow>,
    @InjectRepository(ChannelVideo)
    private readonly videos: Repository<ChannelVideo>,
    @InjectRepository(ChannelVideoLike)
    private readonly likes: Repository<ChannelVideoLike>,
    @InjectRepository(ChannelVideoComment)
    private readonly comments: Repository<ChannelVideoComment>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    private readonly friends: FriendsService,
    private readonly moderation: ModerationService,
  ) {}

  limits() {
    return {
      maxBytes: CHANNEL_VIDEO_MAX_BYTES,
      maxDurationSec: CHANNEL_VIDEO_MAX_DURATION_SEC,
      maxMb: Math.round(CHANNEL_VIDEO_MAX_BYTES / (1024 * 1024)),
    };
  }

  // ── Official OBIC (back-compat) ──────────────────────────────────────

  async getObic(viewerId?: string | null) {
    return this.toChannelDto(await this.ensureObic(), viewerId);
  }

  async followObic(actor: AuthUser) {
    return this.followChannel(actor, await this.ensureObic());
  }

  async unfollowObic(actor: AuthUser) {
    return this.unfollowChannel(actor, await this.ensureObic());
  }

  async listObicVideos(limit = 40, viewerId?: string | null) {
    const channel = await this.ensureObic();
    return this.listVideosForChannel(channel, limit, viewerId);
  }

  async createObicVideo(actor: AuthUser, dto: CreateChannelVideoDto) {
    return this.createVideoOnChannel(actor, await this.ensureObic(), dto);
  }

  // ── Per-user channels ────────────────────────────────────────────────

  async getMine(actor: AuthUser) {
    const channel = await this.ensurePersonal(actor.userId);
    return this.toChannelDto(channel, actor.userId);
  }

  async getByUserId(userId: string, viewerId?: string | null) {
    const channel = await this.ensurePersonal(userId);
    const friendIds = await this.friendIdSet(viewerId);
    const canSee = canViewerSeeChannelContent({
      channel,
      viewerId,
      friendOwnerIds: friendIds,
    });
    const dto = await this.toChannelDto(channel, viewerId);
    return {
      ...dto,
      contentVisible: canSee,
      relationship: canSee
        ? viewerId === userId
          ? 'self'
          : 'friend'
        : viewerId
          ? 'stranger'
          : 'guest',
    };
  }

  async getByIdOrSlug(idOrSlug: string, viewerId?: string | null) {
    const channel = await this.findChannel(idOrSlug);
    if (!channel) throw new NotFoundException('Channel not found');
    const friendIds = await this.friendIdSet(viewerId);
    const canSee = canViewerSeeChannelContent({
      channel,
      viewerId,
      friendOwnerIds: friendIds,
    });
    const dto = await this.toChannelDto(channel, viewerId);
    return {
      ...dto,
      contentVisible: canSee,
    };
  }

  async followByIdOrSlug(actor: AuthUser, idOrSlug: string) {
    const channel = await this.findChannel(idOrSlug);
    if (!channel) throw new NotFoundException('Channel not found');
    return this.followChannel(actor, channel);
  }

  async unfollowByIdOrSlug(actor: AuthUser, idOrSlug: string) {
    const channel = await this.findChannel(idOrSlug);
    if (!channel) throw new NotFoundException('Channel not found');
    return this.unfollowChannel(actor, channel);
  }

  async listVideosByIdOrSlug(
    idOrSlug: string,
    limit = 40,
    viewerId?: string | null,
  ) {
    const channel = await this.findChannel(idOrSlug);
    if (!channel) throw new NotFoundException('Channel not found');
    return this.listVideosForChannel(channel, limit, viewerId);
  }

  async createVideoByIdOrSlug(
    actor: AuthUser,
    idOrSlug: string,
    dto: CreateChannelVideoDto,
  ) {
    const channel = await this.findChannel(idOrSlug);
    if (!channel) throw new NotFoundException('Channel not found');
    return this.createVideoOnChannel(actor, channel, dto);
  }

  // ── Feed tabs (Follow / Nearby / Friends / Hot) ──────────────────────

  async feed(
    tab: ChannelFeedTab,
    limit = 40,
    viewerId?: string | null,
  ): Promise<object[]> {
    const take = Math.min(Math.max(limit, 1), 80);
    const friendIds = await this.friendIdSet(viewerId);

    if (tab === 'follow') {
      if (!viewerId) return [];
      const follows = await this.follows.find({
        where: { userId: viewerId },
      });
      const channelIds = follows.map((f) => f.channelId);
      if (channelIds.length === 0) return [];
      const rows = await this.videos.find({
        where: { channelId: In(channelIds), deletedAt: IsNull() },
        relations: { author: true, channel: true },
        order: { createdAt: 'DESC' },
        take: take * 3,
      });
      return this.filterAndMapVideos(rows, viewerId, friendIds, take);
    }

    if (tab === 'friends') {
      return this.friendsFeed(viewerId, friendIds, take);
    }

    if (tab === 'nearby') {
      if (!viewerId) return [];
      const me = await this.users.findOne({ where: { id: viewerId } });
      const city = me?.city?.trim();
      if (!city) {
        return this.friendsFeed(viewerId, friendIds, take);
      }
      const nearbyUsers = await this.users
        .createQueryBuilder('u')
        .where('LOWER(TRIM(u.city)) = LOWER(:city)', { city })
        .andWhere('u.id != :me', { me: viewerId })
        .take(80)
        .getMany();
      const nearbyIds = nearbyUsers.map((u) => u.id);
      if (nearbyIds.length === 0) return [];
      const nearbyChannels = await this.channels.find({
        where: [
          { ownerUserId: In(nearbyIds) },
          { official: true },
        ],
      });
      const channelIds = nearbyChannels.map((c) => c.id);
      const rows = await this.videos.find({
        where: { channelId: In(channelIds), deletedAt: IsNull() },
        relations: { author: true, channel: true },
        order: { createdAt: 'DESC' },
        take: take * 2,
      });
      return this.filterAndMapVideos(rows, viewerId, friendIds, take);
    }

    // hot — official + visible personal, ranked by engagement
    const rows = await this.videos.find({
      where: { deletedAt: IsNull() },
      relations: { author: true, channel: true },
      order: { createdAt: 'DESC' },
      take: Math.min(take * 4, 200),
    });
    const visible = rows.filter((v) =>
      v.channel
        ? canViewerSeeChannelContent({
            channel: v.channel,
            viewerId,
            friendOwnerIds: friendIds,
          })
        : false,
    );
    visible.sort((a, b) => {
      const score = (x: ChannelVideo) =>
        (x.likeCount ?? 0) * 3 +
        (x.commentCount ?? 0) * 2 +
        (x.shareCount ?? 0) +
        Math.max(
          0,
          10 - (Date.now() - new Date(x.createdAt).getTime()) / 86_400_000,
        );
      return score(b) - score(a);
    });
    return this.mapVideos(visible.slice(0, take), viewerId);
  }

  private async friendsFeed(
    viewerId: string | null | undefined,
    friendIds: Set<string>,
    take: number,
  ): Promise<object[]> {
    if (!viewerId || friendIds.size === 0) return [];
    const friendChannels = await this.channels.find({
      where: { ownerUserId: In([...friendIds]) },
    });
    const channelIds = friendChannels.map((c) => c.id);
    if (channelIds.length === 0) return [];
    const rows = await this.videos.find({
      where: { channelId: In(channelIds), deletedAt: IsNull() },
      relations: { author: true, channel: true },
      order: { createdAt: 'DESC' },
      take,
    });
    return this.filterAndMapVideos(rows, viewerId, friendIds, take);
  }

  /** Discover hub previews — Moments tip + Channels thumbnails. */
  async discoverPreview(viewerId?: string | null) {
    const friendIds = await this.friendIdSet(viewerId);
    const obic = await this.ensureObic();
    const obicVideos = await this.videos.find({
      where: { channelId: obic.id, deletedAt: IsNull() },
      relations: { author: true },
      order: { createdAt: 'DESC' },
      take: 1,
    });

    let friendsPreview: ChannelVideo | null = null;
    if (viewerId && friendIds.size > 0) {
      const friendChannels = await this.channels.find({
        where: { ownerUserId: In([...friendIds]) },
      });
      if (friendChannels.length > 0) {
        const rows = await this.videos.find({
          where: {
            channelId: In(friendChannels.map((c) => c.id)),
            deletedAt: IsNull(),
          },
          relations: { author: true, channel: true },
          order: { createdAt: 'DESC' },
          take: 1,
        });
        friendsPreview = rows[0] ?? null;
      }
    }

    const myChannel = viewerId
      ? await this.ensurePersonal(viewerId)
      : null;

    return {
      moments: {
        key: 'moments',
        hasPreview: true,
      },
      channels: {
        key: 'channels',
        official: await this.toChannelDto(obic, viewerId),
        officialPreview: obicVideos[0]
          ? this.toVideoDto(obicVideos[0], viewerId)
          : null,
        friendsPreview: friendsPreview
          ? this.toVideoDto(friendsPreview, viewerId)
          : null,
        myChannel: myChannel
          ? await this.toChannelDto(myChannel, viewerId)
          : null,
        unreadDot: !!(obicVideos[0] || friendsPreview),
      },
      canPostOfficial: viewerId
        ? canPostOnOfficial(
            (await this.users.findOne({ where: { id: viewerId } }))?.role,
          )
        : false,
    };
  }

  // ── Engagement ───────────────────────────────────────────────────────

  async toggleLike(actor: AuthUser, videoId: string) {
    const video = await this.requireVisibleVideo(videoId, actor.userId);
    const existing = await this.likes.findOne({
      where: { videoId, userId: actor.userId },
    });
    if (existing) {
      await this.likes.remove(existing);
      video.likeCount = Math.max(0, (video.likeCount ?? 0) - 1);
      await this.videos.save(video);
      return {
        liked: false,
        likeCount: video.likeCount,
        videoId,
      };
    }
    await this.likes.save(
      this.likes.create({ videoId, userId: actor.userId }),
    );
    video.likeCount = (video.likeCount ?? 0) + 1;
    await this.videos.save(video);
    return { liked: true, likeCount: video.likeCount, videoId };
  }

  async listComments(videoId: string, viewerId?: string | null, limit = 40) {
    await this.requireVisibleVideo(videoId, viewerId);
    const take = Math.min(Math.max(limit, 1), 80);
    const rows = await this.comments.find({
      where: { videoId, deletedAt: IsNull() },
      relations: { author: true },
      order: { createdAt: 'ASC' },
      take,
    });
    return rows.map((c) => ({
      id: c.id,
      videoId: c.videoId,
      authorId: c.authorId,
      authorName: c.author?.name ?? null,
      authorAvatarUrl: c.author?.avatarUrl ?? null,
      body: c.body,
      createdAt: c.createdAt,
      mine: viewerId ? c.authorId === viewerId : false,
    }));
  }

  async addComment(
    actor: AuthUser,
    videoId: string,
    dto: CreateChannelCommentDto,
  ) {
    await this.requireVisibleVideo(videoId, actor.userId);
    const body = (dto.body ?? '').trim().slice(0, 500);
    if (!body) throw new BadRequestException('body required');
    await this.moderation.assertClean(actor, body, {
      targetType: ReportTargetType.Moment,
    });
    const author = await this.users.findOne({ where: { id: actor.userId } });
    const saved = await this.comments.save(
      this.comments.create({
        videoId,
        authorId: actor.userId,
        body,
      }),
    );
    await this.videos.increment({ id: videoId }, 'commentCount', 1);
    saved.author = author ?? undefined!;
    return {
      id: saved.id,
      videoId: saved.videoId,
      authorId: saved.authorId,
      authorName: author?.name ?? null,
      authorAvatarUrl: author?.avatarUrl ?? null,
      body: saved.body,
      createdAt: saved.createdAt,
      mine: true,
    };
  }

  async share(actor: AuthUser, videoId: string) {
    const video = await this.requireVisibleVideo(videoId, actor.userId);
    video.shareCount = (video.shareCount ?? 0) + 1;
    await this.videos.save(video);
    return { ok: true as const, shareCount: video.shareCount, videoId };
  }

  async softDeleteVideo(actor: AuthUser, videoId: string) {
    const video = await this.videos.findOne({
      where: { id: videoId, deletedAt: IsNull() },
      relations: { channel: true },
    });
    if (!video) throw new NotFoundException('Video not found');
    const user = await this.users.findOne({ where: { id: actor.userId } });
    const isStaff =
      user?.role === UserRole.SuperAdmin || user?.role === UserRole.Employee;
    const isOwner = video.authorId === actor.userId;
    const isChannelOwner =
      video.channel?.ownerUserId != null &&
      video.channel.ownerUserId === actor.userId;
    if (!isOwner && !isStaff && !isChannelOwner) {
      throw new NotFoundException('Video not found');
    }
    video.deletedAt = new Date();
    await this.videos.save(video);
    return { ok: true as const, id: videoId };
  }

  // ── Internals ────────────────────────────────────────────────────────

  private async followChannel(actor: AuthUser, channel: Channel) {
    const existing = await this.follows.findOne({
      where: { channelId: channel.id, userId: actor.userId },
    });
    if (!existing) {
      await this.follows.save(
        this.follows.create({
          channelId: channel.id,
          userId: actor.userId,
        }),
      );
    }
    return this.toChannelDto(channel, actor.userId);
  }

  private async unfollowChannel(actor: AuthUser, channel: Channel) {
    await this.follows.delete({
      channelId: channel.id,
      userId: actor.userId,
    });
    return this.toChannelDto(channel, actor.userId);
  }

  private async listVideosForChannel(
    channel: Channel,
    limit: number,
    viewerId?: string | null,
  ) {
    const friendIds = await this.friendIdSet(viewerId);
    const canSee = canViewerSeeChannelContent({
      channel,
      viewerId,
      friendOwnerIds: friendIds,
    });
    if (!canSee) return [];
    const take = Math.min(Math.max(limit, 1), 80);
    const rows = await this.videos.find({
      where: { channelId: channel.id, deletedAt: IsNull() },
      relations: { author: true, channel: true },
      order: { createdAt: 'DESC' },
      take,
    });
    return this.mapVideos(rows, viewerId);
  }

  private async createVideoOnChannel(
    actor: AuthUser,
    channel: Channel,
    dto: CreateChannelVideoDto,
  ) {
    const user = await this.users.findOne({ where: { id: actor.userId } });
    if (!user) throw new NotFoundException('User not found');

    if (channel.official) {
      if (!canPostOnOfficial(user.role)) {
        throw new ForbiddenException(
          'Only OBIC staff can post to the Official Channel',
        );
      }
    } else if (channel.ownerUserId !== actor.userId) {
      throw new ForbiddenException('You can only post to your own Channel');
    }

    const videoUrl = (dto.videoUrl ?? '').trim();
    if (!videoUrl) throw new BadRequestException('videoUrl required');
    const okUrl =
      /^https?:\/\//i.test(videoUrl) || videoUrl.startsWith('/uploads/');
    if (!okUrl) {
      throw new BadRequestException('videoUrl must be http(s) or /uploads/…');
    }
    if (
      dto.durationSec != null &&
      dto.durationSec > CHANNEL_VIDEO_MAX_DURATION_SEC
    ) {
      throw new BadRequestException(
        `Video must be ≤ ${CHANNEL_VIDEO_MAX_DURATION_SEC} seconds`,
      );
    }
    if (dto.byteSize != null && dto.byteSize > CHANNEL_VIDEO_MAX_BYTES) {
      throw new BadRequestException(
        `Video must be ≤ ${Math.round(CHANNEL_VIDEO_MAX_BYTES / (1024 * 1024))} MB`,
      );
    }

    const caption = (dto.caption ?? '').trim().slice(0, 500);
    if (caption) {
      await this.moderation.assertClean(actor, caption, {
        targetType: ReportTargetType.Moment,
      });
    }

    const saved = await this.videos.save(
      this.videos.create({
        channelId: channel.id,
        authorId: actor.userId,
        videoUrl: videoUrl.slice(0, 1024),
        thumbUrl: dto.thumbUrl?.trim()?.slice(0, 1024) || null,
        caption,
        durationSec: dto.durationSec ?? null,
        byteSize: dto.byteSize ?? null,
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
      }),
    );
    saved.author = user;
    saved.channel = channel;
    return this.toVideoDto(saved, actor.userId);
  }

  private async requireVisibleVideo(
    videoId: string,
    viewerId?: string | null,
  ): Promise<ChannelVideo> {
    const video = await this.videos.findOne({
      where: { id: videoId, deletedAt: IsNull() },
      relations: { channel: true, author: true },
    });
    if (!video?.channel) throw new NotFoundException('Video not found');
    const friendIds = await this.friendIdSet(viewerId);
    if (
      !canViewerSeeChannelContent({
        channel: video.channel,
        viewerId,
        friendOwnerIds: friendIds,
      })
    ) {
      throw new NotFoundException('Video not found');
    }
    return video;
  }

  private async findChannel(idOrSlug: string): Promise<Channel | null> {
    const uuid =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        idOrSlug,
      );
    if (uuid) {
      return this.channels.findOne({ where: { id: idOrSlug } });
    }
    if (idOrSlug === OBIC_SLUG) return this.ensureObic();
    return this.channels.findOne({ where: { slug: idOrSlug } });
  }

  private async ensureObic(): Promise<Channel> {
    let channel = await this.channels.findOne({ where: { slug: OBIC_SLUG } });
    if (!channel) {
      channel = await this.channels.save(
        this.channels.create({
          slug: OBIC_SLUG,
          name: 'OBIC Official Channel',
          description: 'Short videos from OBIC staff',
          official: true,
          ownerUserId: null,
        }),
      );
    }
    return channel;
  }

  private async ensurePersonal(userId: string): Promise<Channel> {
    let channel = await this.channels.findOne({
      where: { ownerUserId: userId },
      relations: { owner: true },
    });
    if (channel) return channel;

    const user = await this.users.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const slug = `u-${userId.replace(/-/g, '').slice(0, 16)}`;
    const name = user.name?.trim()
      ? `${user.name.trim()}`
      : 'Channel';
    try {
      channel = await this.channels.save(
        this.channels.create({
          slug,
          name,
          description: null,
          avatarUrl: user.avatarUrl,
          official: false,
          ownerUserId: userId,
        }),
      );
    } catch {
      // Race: another request created it.
      channel = await this.channels.findOne({
        where: { ownerUserId: userId },
      });
      if (!channel) throw new BadRequestException('Could not create channel');
    }
    channel.owner = user;
    return channel;
  }

  private async friendIdSet(viewerId?: string | null): Promise<Set<string>> {
    if (!viewerId) return new Set();
    const ids = await this.friends.friendIdsOf(viewerId);
    return new Set(ids);
  }

  private async filterAndMapVideos(
    rows: ChannelVideo[],
    viewerId: string | null | undefined,
    friendIds: Set<string>,
    take: number,
  ) {
    const visible = rows.filter((v) =>
      v.channel
        ? canViewerSeeChannelContent({
            channel: v.channel,
            viewerId,
            friendOwnerIds: friendIds,
          })
        : false,
    );
    return this.mapVideos(visible.slice(0, take), viewerId);
  }

  private async mapVideos(
    rows: ChannelVideo[],
    viewerId?: string | null,
  ) {
    if (!viewerId || rows.length === 0) {
      return rows.map((v) => this.toVideoDto(v, viewerId));
    }
    const liked = await this.likes.find({
      where: {
        userId: viewerId,
        videoId: In(rows.map((r) => r.id)),
      },
    });
    const likedSet = new Set(liked.map((l) => l.videoId));
    return rows.map((v) =>
      this.toVideoDto(v, viewerId, likedSet.has(v.id)),
    );
  }

  private async toChannelDto(channel: Channel, viewerId?: string | null) {
    const [followerCount, videoCount, followedByMe] = await Promise.all([
      this.follows.count({ where: { channelId: channel.id } }),
      this.videos.count({
        where: { channelId: channel.id, deletedAt: IsNull() },
      }),
      viewerId
        ? this.follows
            .exist({
              where: { channelId: channel.id, userId: viewerId },
            })
            .then(Boolean)
        : Promise.resolve(false),
    ]);
    let ownerName: string | null = null;
    let ownerAvatarUrl: string | null = null;
    if (channel.ownerUserId) {
      const owner =
        channel.owner ??
        (await this.users.findOne({ where: { id: channel.ownerUserId } }));
      ownerName = owner?.name ?? null;
      ownerAvatarUrl = owner?.avatarUrl ?? channel.avatarUrl;
    }
    return {
      id: channel.id,
      slug: channel.slug,
      name: channel.name,
      description: channel.description,
      avatarUrl: channel.avatarUrl ?? ownerAvatarUrl,
      coverUrl: channel.coverUrl,
      official: channel.official,
      ownerUserId: channel.ownerUserId,
      ownerName,
      ownerAvatarUrl,
      followerCount,
      videoCount,
      followedByMe,
      canPost: await this.canActorPost(channel, viewerId),
      limits: this.limits(),
    };
  }

  private async canActorPost(
    channel: Channel,
    viewerId?: string | null,
  ): Promise<boolean> {
    if (!viewerId) return false;
    if (channel.official) {
      const user = await this.users.findOne({ where: { id: viewerId } });
      return canPostOnOfficial(user?.role);
    }
    return channel.ownerUserId === viewerId;
  }

  private toVideoDto(
    v: ChannelVideo,
    viewerId?: string | null,
    likedByMe = false,
  ) {
    const a = v.author;
    return {
      id: v.id,
      channelId: v.channelId,
      channelSlug: v.channel?.slug ?? null,
      channelOfficial: v.channel?.official ?? false,
      channelName: v.channel?.name ?? null,
      authorId: v.authorId,
      authorName: a?.name ?? null,
      authorAvatarUrl: a?.avatarUrl ?? null,
      authorVerified:
        a?.role === UserRole.Employee || a?.role === UserRole.SuperAdmin,
      videoUrl: v.videoUrl,
      thumbUrl: v.thumbUrl,
      caption: v.caption,
      durationSec: v.durationSec,
      byteSize: v.byteSize,
      likeCount: v.likeCount ?? 0,
      commentCount: v.commentCount ?? 0,
      shareCount: v.shareCount ?? 0,
      likedByMe,
      createdAt: v.createdAt,
      mine: viewerId ? v.authorId === viewerId : false,
    };
  }
}
