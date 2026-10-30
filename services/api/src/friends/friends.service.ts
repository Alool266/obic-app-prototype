// Made by Dr Ali
// Friends — Employees cannot add Customers (403). Ownership via JWT subject.

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { ILike, Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { NotificationKind } from '../notifications/notification.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { toPublicUser } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { SendFriendRequestDto } from './dto/friends.dto';
import {
  FriendRequest,
  FriendRequestStatus,
} from './friend-request.entity';
import { Friendship } from './friendship.entity';

@Injectable()
export class FriendsService {
  constructor(
    @InjectRepository(Friendship)
    private readonly friendships: Repository<Friendship>,
    @InjectRepository(FriendRequest)
    private readonly requests: Repository<FriendRequest>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    private readonly notifications: NotificationsService,
  ) {}

  async listFriends(actor: AuthUser) {
    const rows = await this.friendships.find({
      where: [{ userLowId: actor.userId }, { userHighId: actor.userId }],
      relations: { userLow: true, userHigh: true },
      order: { createdAt: 'DESC' },
    });
    return rows.map((f) => {
      const other =
        f.userLowId === actor.userId ? f.userHigh : f.userLow;
      return {
        friendshipId: f.id,
        since: f.createdAt,
        user: toPublicUser(other),
      };
    });
  }

  /**
   * Profile card for the signed-in user or an accepted friend.
   * Omits email, phone, role, staff, and admin flags.
   */
  async friendProfile(actor: AuthUser, userId: string) {
    const user = await this.users.findOne({ where: { id: userId } });
    if (!user || user.deletedAt) {
      throw new NotFoundException('User not found');
    }
    const self = user.id === actor.userId;
    if (!self && !(await this.areFriends(actor.userId, user.id))) {
      throw new ForbiddenException('Friends only');
    }
    return {
      id: user.id,
      name: user.name,
      avatarUrl: user.avatarUrl ?? null,
      city: user.city ?? null,
      country: user.country ?? null,
      gender: user.gender ?? null,
      whatsUp: user.whatsUp ?? null,
      obicId: user.obicId ?? null,
    };
  }

  /** Mutual friend user ids (accepted friendships only). */
  async friendIdsOf(userId: string): Promise<string[]> {
    const rows = await this.friendships.find({
      where: [{ userLowId: userId }, { userHighId: userId }],
    });
    return rows.map((f) =>
      f.userLowId === userId ? f.userHighId : f.userLowId,
    );
  }

  async areFriends(a: string, b: string): Promise<boolean> {
    if (a === b) return true;
    const [low, high] = a < b ? [a, b] : [b, a];
    const row = await this.friendships.findOne({
      where: { userLowId: low, userHighId: high },
    });
    return !!row;
  }

  async search(actor: AuthUser, q: string) {
    const query = q.trim();
    if (query.length < 2) {
      throw new BadRequestException('Query too short');
    }
    const isUuid =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        query,
      );
    const obicIdExact = query.toLowerCase();
    const rows = await this.users.find({
      where: isUuid
        ? { id: query }
        : [
            { obicId: obicIdExact },
            { phone: query },
            { phone: ILike(`%${query}%`) },
            { name: ILike(`%${query}%`) },
            { email: ILike(`%${query}%`) },
            { obicId: ILike(`%${obicIdExact}%`) },
          ],
      take: 20,
    });
    return rows
      .filter((u) => u.id !== actor.userId)
      .map((u) => ({
        id: u.id,
        name: u.name,
        phone: u.phone,
        email: u.email,
        role: u.role,
        staffTitle: u.staffTitle ?? null,
        branchLabel: u.branchLabel ?? null,
        avatarUrl: u.avatarUrl ?? null,
        obicId: u.obicId ?? null,
      }));
  }

  async sendRequest(actor: AuthUser, dto: SendFriendRequestDto) {
    const me = await this.users.findOne({ where: { id: actor.userId } });
    if (!me) throw new NotFoundException('User not found');

    let target: User | null = null;
    if (dto.userId) {
      target = await this.users.findOne({ where: { id: dto.userId } });
    } else if (dto.phone) {
      target = await this.users.findOne({ where: { phone: dto.phone.trim() } });
    }
    if (!target) throw new NotFoundException('User not found');
    if (target.id === actor.userId) {
      throw new BadRequestException('Cannot add yourself');
    }

    // Policy: Employees cannot add Customers.
    if (
      me.role === UserRole.Employee &&
      target.role === UserRole.Customer
    ) {
      throw new ForbiddenException('Employees cannot add customers');
    }

    if (await this.areFriends(me.id, target.id)) {
      throw new ConflictException('Already friends');
    }

    // WeChat: if they already requested you, accepting is the right action.
    const reciprocal = await this.requests.findOne({
      where: {
        fromUserId: target.id,
        toUserId: me.id,
        status: FriendRequestStatus.Pending,
      },
    });
    if (reciprocal) {
      return this.accept(actor, reciprocal.id);
    }

    const existingRows = await this.requests.find({
      where: {
        fromUserId: me.id,
        toUserId: target.id,
        status: FriendRequestStatus.Pending,
      },
      order: { createdAt: 'DESC' },
      take: 1,
    });
    const existing = existingRows[0];
    if (existing) {
      // WeChat: one pending row — latest note wins; never spam duplicates.
      const note = dto.message?.trim().slice(0, 120) || null;
      if (note != null && note !== existing.message) {
        existing.message = note;
        await this.requests.save(existing);
        await this.notifyFriendRequest(target.id, existing.id, me);
      }
      return this.requestDto(existing, me, target);
    }

    const note = dto.message?.trim().slice(0, 120) || null;

    const saved = await this.requests.save(
      this.requests.create({
        fromUserId: me.id,
        toUserId: target.id,
        status: FriendRequestStatus.Pending,
        message: note,
      }),
    );

    await this.notifyFriendRequest(target.id, saved.id, me);

    return this.requestDto(saved, me, target);
  }

  async listRequests(actor: AuthUser) {
    const incoming = await this.requests.find({
      where: {
        toUserId: actor.userId,
        status: FriendRequestStatus.Pending,
      },
      relations: { fromUser: true, toUser: true },
      order: { createdAt: 'DESC' },
    });
    const outgoing = await this.requests.find({
      where: {
        fromUserId: actor.userId,
        status: FriendRequestStatus.Pending,
      },
      relations: { fromUser: true, toUser: true },
      order: { createdAt: 'DESC' },
    });
    // WeChat New Friends: one row per peer (latest note / newest wins).
    return {
      incoming: this.dedupeByPeer(incoming, (r) => r.fromUserId).map((r) =>
        this.requestDto(r, r.fromUser, r.toUser),
      ),
      outgoing: this.dedupeByPeer(outgoing, (r) => r.toUserId).map((r) =>
        this.requestDto(r, r.fromUser, r.toUser),
      ),
    };
  }

  /** Keep newest pending per peer id (list already DESC by createdAt). */
  private dedupeByPeer(
    rows: FriendRequest[],
    peerId: (r: FriendRequest) => string,
  ): FriendRequest[] {
    const seen = new Set<string>();
    const out: FriendRequest[] = [];
    for (const r of rows) {
      const id = peerId(r);
      if (seen.has(id)) continue;
      seen.add(id);
      out.push(r);
    }
    return out;
  }

  async accept(actor: AuthUser, requestId: string) {
    const req = await this.requests.findOne({
      where: { id: requestId },
      relations: { fromUser: true, toUser: true },
    });
    if (!req || req.toUserId !== actor.userId) {
      throw new NotFoundException('Request not found');
    }
    if (req.status !== FriendRequestStatus.Pending) {
      throw new ConflictException('Request is not pending');
    }
    req.status = FriendRequestStatus.Accepted;
    await this.requests.save(req);

    // Collapse any duplicate pending rows from the same peer (legacy spam).
    await this.requests
      .createQueryBuilder()
      .update(FriendRequest)
      .set({ status: FriendRequestStatus.Accepted })
      .where('from_user_id = :from', { from: req.fromUserId })
      .andWhere('to_user_id = :to', { to: req.toUserId })
      .andWhere('status = :pending', { pending: FriendRequestStatus.Pending })
      .andWhere('id != :id', { id: req.id })
      .execute();

    const [low, high] =
      req.fromUserId < req.toUserId
        ? [req.fromUserId, req.toUserId]
        : [req.toUserId, req.fromUserId];
    const existing = await this.friendships.findOne({
      where: { userLowId: low, userHighId: high },
    });
    if (!existing) {
      await this.friendships.save(
        this.friendships.create({ userLowId: low, userHighId: high }),
      );
    }

    await this.notifyFriendAccepted(req);

    return this.requestDto(req, req.fromUser, req.toUser);
  }

  async reject(actor: AuthUser, requestId: string) {
    const req = await this.requests.findOne({
      where: { id: requestId },
      relations: { fromUser: true, toUser: true },
    });
    if (!req || req.toUserId !== actor.userId) {
      throw new NotFoundException('Request not found');
    }
    if (req.status !== FriendRequestStatus.Pending) {
      throw new ConflictException('Request is not pending');
    }
    req.status = FriendRequestStatus.Rejected;
    await this.requests.save(req);

    // Reject every pending from this peer so New Friends stays a single row.
    await this.requests
      .createQueryBuilder()
      .update(FriendRequest)
      .set({ status: FriendRequestStatus.Rejected })
      .where('from_user_id = :from', { from: req.fromUserId })
      .andWhere('to_user_id = :to', { to: req.toUserId })
      .andWhere('status = :pending', { pending: FriendRequestStatus.Pending })
      .andWhere('id != :id', { id: req.id })
      .execute();

    return this.requestDto(req, req.fromUser, req.toUser);
  }

  private async notifyFriendRequest(toUserId: string, requestId: string, from: User) {
    try {
      await this.notifications.createForUsers({
        userIds: [toUserId],
        kind: NotificationKind.System,
        title: 'New friend request',
        body: `${from.name ?? 'Someone'} wants to add you as a friend`,
        data: { type: 'friend_request', requestId, fromUserId: from.id },
      });
    } catch {
      // The request row is already saved.
    }
  }

  private async notifyFriendAccepted(req: FriendRequest) {
    try {
      await this.notifications.createForUsers({
        userIds: [req.fromUserId],
        kind: NotificationKind.System,
        title: 'Friend request accepted',
        body: `${req.toUser?.name ?? 'Your friend'} accepted your friend request`,
        data: { type: 'friend_accepted', requestId: req.id, userId: req.toUserId },
      });
    } catch {
      // The friendship is already saved.
    }
  }

  private requestDto(r: FriendRequest, from?: User, to?: User) {
    return {
      id: r.id,
      status: r.status,
      fromUserId: r.fromUserId,
      toUserId: r.toUserId,
      message: r.message ?? null,
      from: from ? toPublicUser(from) : null,
      to: to ? toPublicUser(to) : null,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    };
  }
}
