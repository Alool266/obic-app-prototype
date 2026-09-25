// Made by Dr Ali
// Moments feed — WeChat 朋友圈 ACL (server-enforced).
// Official/staff → public to everyone; customers → mutual friends only.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { FriendsService } from '../friends/friends.service';
import { NotificationKind } from '../notifications/notification.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { ModerationService } from '../moderation/moderation.service';
import { ReportTargetType } from '../moderation/content-report.entity';
import { User } from '../users/user.entity';
import { CreateMomentCommentDto } from './dto/create-moment-comment.dto';
import { CreateMomentDto, MomentMediaDto } from './dto/create-moment.dto';
import {
  canViewerSeeMoment,
  momentVisibilityForRole,
} from './moment-visibility';
import { momentNotifyCandidateMode } from './moment-fanout';
import { MomentComment } from './moment-comment.entity';
import { MomentLike } from './moment-like.entity';
import { MomentNotifyPrefsService } from './moment-notify-prefs.service';
import { Moment } from './moment.entity';

@Injectable()
export class MomentsService {
  constructor(
    @InjectRepository(Moment)
    private readonly moments: Repository<Moment>,
    @InjectRepository(MomentLike)
    private readonly likes: Repository<MomentLike>,
    @InjectRepository(MomentComment)
    private readonly comments: Repository<MomentComment>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    private readonly notifications: NotificationsService,
    private readonly moderation: ModerationService,
    private readonly friends: FriendsService,
    private readonly notifyPrefs: MomentNotifyPrefsService,
  ) {}

  async listFeed(limit = 50, viewerId?: string | null) {
    const take = Math.min(Math.max(limit * 3, 50), 200);
    const rows = await this.moments.find({
      where: { deletedAt: IsNull() },
      relations: { author: true },
      order: { createdAt: 'DESC' },
      take,
    });
    if (!rows.length) return [];

    const friendIds = viewerId
      ? new Set(await this.friends.friendIdsOf(viewerId))
      : new Set<string>();

    const visible = rows
      .filter((m) => canViewerSeeMoment(m, viewerId, friendIds))
      .slice(0, Math.min(limit, 100));
    if (!visible.length) return [];

    const ids = visible.map((m) => m.id);
    const [likeRows, commentRows] = await Promise.all([
      this.likes.find({
        where: { momentId: In(ids) },
        relations: { user: true },
        order: { createdAt: 'ASC' },
      }),
      this.comments.find({
        where: { momentId: In(ids) },
        relations: { author: true },
        order: { createdAt: 'ASC' },
      }),
    ]);

    const likesByMoment = new Map<string, MomentLike[]>();
    for (const l of likeRows) {
      const list = likesByMoment.get(l.momentId) ?? [];
      list.push(l);
      likesByMoment.set(l.momentId, list);
    }
    const commentsByMoment = new Map<string, MomentComment[]>();
    for (const c of commentRows) {
      const list = commentsByMoment.get(c.momentId) ?? [];
      list.push(c);
      commentsByMoment.set(c.momentId, list);
    }

    return visible.map((m) =>
      this.toDto(
        m,
        m.author,
        likesByMoment.get(m.id) ?? [],
        commentsByMoment.get(m.id) ?? [],
        viewerId,
      ),
    );
  }

  async create(actor: AuthUser, dto: CreateMomentDto) {
    const author = await this.users.findOne({ where: { id: actor.userId } });
    const role = (author?.role ?? actor.role) as UserRole;
    const isStaff =
      role === UserRole.SuperAdmin || role === UserRole.Employee;
    const visibility = momentVisibilityForRole(isStaff);

    const media = this.normalizeMedia(dto);
    const body = (dto.body ?? '').trim();
    if (!body && media.length === 0) {
      throw new BadRequestException('Moment needs text or media');
    }
    if (body) {
      await this.moderation.assertClean(actor, body, {
        targetType: ReportTargetType.Moment,
      });
    }

    const saved = await this.moments.save(
      this.moments.create({
        authorId: actor.userId,
        body,
        imageUrl: media.find((m) => m.kind === 'image')?.url ?? null,
        media,
        notifyAll: isStaff,
        visibility,
      }),
    );
    saved.author = author ?? undefined!;

    // WeChat Moments: fan-out to friends (customers) or all users (staff/official).
    // Honor mute prefs; never notify the author.
    const preview =
      body.slice(0, 180) ||
      (media[0]?.name ? `Shared ${media[0].name}` : 'New Moments update');
    let candidateIds: string[];
    if (momentNotifyCandidateMode(isStaff) === 'all') {
      const allIds: Array<{ id: string }> = await this.users
        .createQueryBuilder('u')
        .select('u.id', 'id')
        .where('u.id <> :authorId', { authorId: actor.userId })
        .andWhere('u.deleted_at IS NULL')
        .getRawMany();
      candidateIds = allIds.map((r) => r.id);
    } else {
      candidateIds = (await this.friends.friendIdsOf(actor.userId)).filter(
        (id) => id !== actor.userId,
      );
    }
    const recipients = await this.notifyPrefs.filterNotifyRecipients(
      candidateIds,
      actor.userId,
    );
    if (recipients.length) {
      await this.notifications.createForUsers({
        userIds: recipients,
        kind: NotificationKind.Moment,
        title: isStaff ? 'OBIC update' : `${author?.name ?? 'Friend'} posted`,
        body: preview,
        data: {
          type: 'moment',
          momentId: saved.id,
          authorId: actor.userId,
        },
      });
    }

    return this.toDto(saved, author, [], [], actor.userId);
  }

  async softDelete(actor: AuthUser, momentId: string) {
    const moment = await this.moments.findOne({
      where: { id: momentId, deletedAt: IsNull() },
    });
    if (!moment) throw new NotFoundException('Moment not found');

    const author = await this.users.findOne({ where: { id: actor.userId } });
    const role = (author?.role ?? actor.role) as UserRole;
    const isStaff =
      role === UserRole.SuperAdmin || role === UserRole.Employee;
    if (moment.authorId !== actor.userId && !isStaff) {
      throw new ForbiddenException('Not allowed to delete this Moment');
    }

    moment.deletedAt = new Date();
    await this.moments.save(moment);
    return { deleted: true, momentId };
  }

  async toggleLike(actor: AuthUser, momentId: string) {
    const moment = await this.requireVisibleMoment(momentId, actor.userId);

    const existing = await this.likes.findOne({
      where: { momentId, userId: actor.userId },
    });
    if (existing) {
      await this.likes.remove(existing);
      return { liked: false, momentId };
    }
    await this.likes.save(
      this.likes.create({ momentId, userId: actor.userId }),
    );
    return { liked: true, momentId };
  }

  async addComment(
    actor: AuthUser,
    momentId: string,
    dto: CreateMomentCommentDto,
  ) {
    await this.requireVisibleMoment(momentId, actor.userId);

    const body = dto.body.trim();
    if (!body) throw new BadRequestException('Comment required');
    await this.moderation.assertClean(actor, body, {
      targetType: ReportTargetType.Comment,
    });

    let replyTo: MomentComment | null = null;
    if (dto.replyToCommentId) {
      replyTo = await this.comments.findOne({
        where: { id: dto.replyToCommentId, momentId },
        relations: { author: true },
      });
      if (!replyTo) {
        throw new BadRequestException('Reply target comment not found');
      }
    }

    const author = await this.users.findOne({ where: { id: actor.userId } });
    const saved = await this.comments.save(
      this.comments.create({
        momentId,
        authorId: actor.userId,
        body,
        replyToCommentId: replyTo?.id ?? null,
      }),
    );
    saved.author = author ?? undefined!;

    return {
      id: saved.id,
      momentId,
      authorId: saved.authorId,
      authorName: author?.name ?? null,
      authorAvatarUrl: author?.avatarUrl ?? null,
      body: saved.body,
      replyToCommentId: replyTo?.id ?? null,
      replyToAuthorId: replyTo?.authorId ?? null,
      replyToAuthorName: replyTo?.author?.name ?? null,
      createdAt: saved.createdAt,
    };
  }

  /** 404 (not 403) when hidden — do not leak friends-only Moments. */
  private async requireVisibleMoment(momentId: string, viewerId: string) {
    const moment = await this.moments.findOne({
      where: { id: momentId, deletedAt: IsNull() },
    });
    if (!moment) throw new NotFoundException('Moment not found');
    const friendIds = new Set(await this.friends.friendIdsOf(viewerId));
    if (!canViewerSeeMoment(moment, viewerId, friendIds)) {
      throw new NotFoundException('Moment not found');
    }
    return moment;
  }

  private normalizeMedia(dto: CreateMomentDto): MomentMediaDto[] {
    const fromList = (dto.media ?? []).filter((m) => m?.url?.trim());
    if (fromList.length) return fromList.slice(0, 9);
    if (dto.imageUrl?.trim()) {
      return [
        {
          kind: 'image',
          url: dto.imageUrl.trim(),
          name: 'photo.jpg',
        },
      ];
    }
    return [];
  }

  private toDto(
    m: Moment,
    author?: User | null,
    likeRows: MomentLike[] = [],
    commentRows: MomentComment[] = [],
    viewerId?: string | null,
  ) {
    const a = author ?? m.author;
    let media = Array.isArray(m.media) ? m.media : [];
    if ((!media || media.length === 0) && m.imageUrl) {
      media = [{ kind: 'image', url: m.imageUrl, name: 'photo.jpg' }];
    }
    return {
      id: m.id,
      authorId: m.authorId,
      authorName: a?.name ?? null,
      authorRole: a?.role ?? null,
      authorAvatarUrl: a?.avatarUrl ?? null,
      body: m.body,
      imageUrl: m.imageUrl,
      media,
      notifyAll: m.notifyAll,
      visibility: m.visibility,
      createdAt: m.createdAt,
      likeCount: likeRows.length,
      likedByMe: viewerId
        ? likeRows.some((l) => l.userId === viewerId)
        : false,
      likes: likeRows.map((l) => ({
        userId: l.userId,
        name: l.user?.name ?? null,
      })),
      comments: commentRows.map((c) => {
        const parent = c.replyToCommentId
          ? commentRows.find((p) => p.id === c.replyToCommentId)
          : undefined;
        return {
          id: c.id,
          authorId: c.authorId,
          authorName: c.author?.name ?? null,
          authorAvatarUrl: c.author?.avatarUrl ?? null,
          body: c.body,
          replyToCommentId: c.replyToCommentId ?? null,
          replyToAuthorId: parent?.authorId ?? null,
          replyToAuthorName: parent?.author?.name ?? null,
          createdAt: c.createdAt,
        };
      }),
    };
  }
}
