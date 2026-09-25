// Made by Dr Ali
// Chat — participants only; SuperAdmin oversight + audit stub.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, MoreThan, Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { User } from '../users/user.entity';
import { AuditLog } from './audit-log.entity';
import { ConversationParticipant } from './conversation-participant.entity';
import { Conversation, ConversationKind } from './conversation.entity';
import { CreateThreadDto, SendMessageDto } from './dto/chat.dto';
import { AttachmentKind, Message } from './message.entity';
import {
  OBIC_AI_USER_ID,
  resolveReplyLocale,
} from '../ai/obic-ai.constants';
import { AiAutoReplyService } from '../ai/ai-auto-reply.service';
import { ModerationService } from '../moderation/moderation.service';
import { ReportTargetType } from '../moderation/content-report.entity';
import { NotificationKind } from '../notifications/notification.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { Order, OrderStatus } from '../orders/order.entity';
import { OrderChatService } from '../orders/order-chat.service';
import {
  branchEmailDesk,
  deskKeyForServiceSlug,
} from '../orders/order-routing';
import { statusNoteBody } from '../orders/order-status-note';
import {
  DEFAULT_SUPPORT_BRANCH,
  resolveSupportBranch,
  resolveSupportDeskKey,
  supportDeskEmail,
} from './support-desk-routing';
import { RealtimeService } from '../realtime/realtime.service';

export type RequestStaffOptions = {
  locale?: string | null;
  /** Form2 branch — required for support handoff form. */
  branch?: string | null;
  /** Service slug or desk key — required for support handoff form. */
  serviceKey?: string | null;
  orderRef?: string | null;
  note?: string | null;
};

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(Conversation)
    private readonly conversations: Repository<Conversation>,
    @InjectRepository(ConversationParticipant)
    private readonly participants: Repository<ConversationParticipant>,
    @InjectRepository(Message)
    private readonly messages: Repository<Message>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    private readonly moderation: ModerationService,
    private readonly notifications: NotificationsService,
    private readonly aiAutoReply: AiAutoReplyService,
    private readonly orderChat: OrderChatService,
    private readonly realtime: RealtimeService,
  ) {}

  async listThreads(actor: AuthUser) {
    const mine = await this.participants.find({
      where: { userId: actor.userId },
      relations: { conversation: true },
      order: { joinedAt: 'DESC' },
    });
    const out = [];
    for (const p of mine) {
      // WeChat hide — omit from main list until unhidden.
      if (p.hidden) continue;
      const peers = await this.participants.find({
        where: { conversationId: p.conversationId },
        relations: { user: true },
      });
      const last = await this.messages.findOne({
        where: { conversationId: p.conversationId },
        order: { createdAt: 'DESC' },
      });
      const unreadCount = p.muted
        ? 0
        : await this.countUnread(
            p.conversationId,
            actor.userId,
            p.lastReadAt,
          );
      out.push({
        id: p.conversationId,
        kind: p.conversation.kind,
        title: p.conversation.title ?? null,
        orderId: p.conversation.orderId ?? null,
        aiAutoReplyEnabled: p.conversation.aiAutoReplyEnabled ?? true,
        updatedAt: p.conversation.updatedAt,
        unreadCount,
        muted: Boolean(p.muted),
        hidden: Boolean(p.hidden),
        participants: peers.map((x) => ({
          userId: x.userId,
          name: x.user?.name ?? null,
          role: x.user?.role ?? null,
          avatarUrl: x.user?.avatarUrl ?? null,
        })),
        lastMessage: last
          ? {
              id: last.id,
              body: last.body,
              attachmentKind: last.attachmentKind,
              senderId: last.senderId,
              isAi: last.isAi ?? false,
              createdAt: last.createdAt,
            }
          : null,
        ...(await this.orderMeta(p.conversation.orderId)),
      });
    }
    out.sort((a, b) => {
      const ta = a.lastMessage?.createdAt?.getTime() ?? a.updatedAt.getTime();
      const tb = b.lastMessage?.createdAt?.getTime() ?? b.updatedAt.getTime();
      return tb - ta;
    });
    return out;
  }

  async openOrCreateThread(actor: AuthUser, dto: CreateThreadDto) {
    if (dto.kind === 'group') {
      return this.createGroup(actor, dto);
    }

    const kind =
      dto.kind === 'support' || !dto.peerUserId
        ? ConversationKind.Support
        : ConversationKind.Direct;

    if (kind === ConversationKind.Direct) {
      if (!dto.peerUserId) {
        throw new BadRequestException('peerUserId required for direct chat');
      }
      if (dto.peerUserId === actor.userId) {
        throw new BadRequestException('Cannot chat with yourself');
      }
      const peer = await this.users.findOne({ where: { id: dto.peerUserId } });
      if (!peer) throw new NotFoundException('User not found');

      // Reuse existing 1:1 direct thread if present.
      const existing = await this.findDirectBetween(actor.userId, dto.peerUserId);
      if (existing) {
        return this.getThreadSummary(existing.id);
      }

      const conv = await this.conversations.save(
        this.conversations.create({ kind: ConversationKind.Direct }),
      );
      await this.participants.save([
        this.participants.create({
          conversationId: conv.id,
          userId: actor.userId,
        }),
        this.participants.create({
          conversationId: conv.id,
          userId: dto.peerUserId,
        }),
      ]);
      return this.getThreadSummary(conv.id);
    }

    // Support: open or reuse a support thread owned by this customer.
    const existingSupport = await this.findSupportForUser(actor.userId);
    if (existingSupport) {
      return this.getThreadSummary(existingSupport.id);
    }
    const conv = await this.conversations.save(
      this.conversations.create({ kind: ConversationKind.Support }),
    );
    await this.participants.save(
      this.participants.create({
        conversationId: conv.id,
        userId: actor.userId,
      }),
    );
    return this.getThreadSummary(conv.id);
  }

  /** Marketing Manager (or any Employee/SA): create a client service group. */
  async createGroup(actor: AuthUser, dto: CreateThreadDto) {
    const me = await this.users.findOne({ where: { id: actor.userId } });
    if (!me) throw new NotFoundException('User not found');
    if (me.role === UserRole.Customer) {
      throw new ForbiddenException('Staff only can create service groups');
    }

    const title = (dto.title ?? '').trim();
    if (!title) throw new BadRequestException('Group title required');
    await this.moderation.assertClean(actor, title, {
      targetType: ReportTargetType.Thread,
    });

    const memberIds = new Set<string>([actor.userId]);
    for (const id of dto.memberUserIds ?? []) {
      if (id) memberIds.add(id);
    }
    if (dto.peerUserId) memberIds.add(dto.peerUserId);

    if (memberIds.size < 2) {
      throw new BadRequestException('Group needs at least one other member');
    }

    for (const id of memberIds) {
      if (id === actor.userId) continue;
      const u = await this.users.findOne({ where: { id } });
      if (!u) throw new NotFoundException(`Member not found: ${id}`);
    }

    const conv = await this.conversations.save(
      this.conversations.create({
        kind: ConversationKind.Group,
        title,
      }),
    );
    await this.participants.save(
      [...memberIds].map((userId) =>
        this.participants.create({ conversationId: conv.id, userId }),
      ),
    );

    await this.writeAudit(actor.userId, 'chat_create_group', 'conversation', conv.id, {
      title,
      members: [...memberIds].length,
    });

    return this.getThreadSummary(conv.id);
  }

  async listMessages(actor: AuthUser, conversationId: string) {
    const part = await this.requireParticipant(actor.userId, conversationId);
    // Same find()+relations path as oversight — QueryBuilder join+take was
    // 500ing on trial (Postgres) while admin transcript still loaded.
    const rows = await this.messages.find({
      where: part.clearedBefore
        ? { conversationId, createdAt: MoreThan(part.clearedBefore) }
        : { conversationId },
      relations: { sender: true },
      order: { createdAt: 'ASC' },
      take: 200,
    });
    try {
      await this.markThreadRead(actor.userId, conversationId);
      // Opening chat unhides (WeChat: viewing brings it back to the list).
      if (part.hidden) {
        part.hidden = false;
        await this.participants.save(part);
      }
    } catch {
      // Soft-fail: never block reading the transcript on read-state updates.
    }
    return rows.map((m) => this.messageDto(m));
  }

  /**
   * WeChat chat prefs: mute (no notifs/badges), hide (omit from list),
   * clearHistory (clearedBefore = now), delete (= hide + clear).
   */
  async updateThreadPrefs(
    actor: AuthUser,
    conversationId: string,
    dto: {
      muted?: boolean;
      hidden?: boolean;
      clearHistory?: boolean;
      deleteChat?: boolean;
    },
  ) {
    const part = await this.requireParticipant(actor.userId, conversationId);
    if (dto.muted !== undefined) part.muted = dto.muted;
    if (dto.hidden !== undefined) part.hidden = dto.hidden;
    if (dto.clearHistory === true || dto.deleteChat === true) {
      part.clearedBefore = new Date();
    }
    if (dto.deleteChat === true) {
      part.hidden = true;
      part.muted = true;
    }
    await this.participants.save(part);
    return {
      conversationId,
      muted: part.muted,
      hidden: part.hidden,
      clearedBefore: part.clearedBefore,
    };
  }

  async sendMessage(actor: AuthUser, conversationId: string, dto: SendMessageDto) {
    await this.requireParticipant(actor.userId, conversationId);
    const kind = (dto.attachmentKind as AttachmentKind) ?? AttachmentKind.None;
    const body = (dto.body ?? '').trim();
    if (!body && kind === AttachmentKind.None) {
      throw new BadRequestException('Message body or attachment required');
    }
    const attachmentUrl = dto.attachmentUrl?.trim() || null;
    if (attachmentUrl) {
      const lower = attachmentUrl.toLowerCase();
      if (
        lower.startsWith('stub://') ||
        lower.startsWith('file:') ||
        lower.startsWith('content:')
      ) {
        throw new BadRequestException('Invalid attachment URL');
      }
      const ok =
        /^https?:\/\//i.test(attachmentUrl) || attachmentUrl.startsWith('/uploads/');
      if (!ok) {
        throw new BadRequestException('Invalid attachment URL');
      }
    }
    if (
      (kind === AttachmentKind.Image ||
        kind === AttachmentKind.File ||
        kind === AttachmentKind.Audio ||
        kind === AttachmentKind.Video) &&
      !attachmentUrl
    ) {
      throw new BadRequestException('attachmentUrl required for attachments');
    }
    if (body) {
      await this.moderation.assertClean(actor, body, {
        targetType: ReportTargetType.Message,
      });
    }
    const saved = await this.messages.save(
      this.messages.create({
        conversationId,
        senderId: actor.userId,
        body,
        attachmentKind: kind,
        attachmentName: dto.attachmentName?.trim() || null,
        attachmentUrl,
      }),
    );
    await this.conversations.update(conversationId, { updatedAt: new Date() });
    await this.afterOrderMessage(actor, conversationId);
    // Phase 5 AI auto-reply (async) — does not change Form2 order status ACL.
    // Auto handoff intent: order threads may soft-request existing assignee;
    // support threads do NOT silent-default Yiwu — client opens handoff form.
    void this.aiAutoReply
      .afterHumanMessage({
        actor,
        conversationId,
        customerMessageBody: body,
        customerMessageId: saved.id,
        clientLocale: dto.locale,
      })
      .then(async (result) => {
        if (!result?.autoHandoff) return;
        const conv = await this.conversations.findOne({
          where: { id: conversationId },
          select: ['id', 'kind'],
        });
        if (!conv || conv.kind !== ConversationKind.Order) return;
        try {
          await this.requestStaff(actor, conversationId, {
            locale: dto.locale,
          });
        } catch {
          // Soft-fail: message + AI reply already delivered.
        }
      })
      .catch(() => undefined);
    const withSender = await this.messages.findOne({
      where: { id: saved.id },
      relations: { sender: true },
    });
    const message = this.messageDto(withSender ?? saved);
    await this.publishChatMessage(conversationId, message);
    return message;
  }

  /** Push new message to all thread participants (Socket.IO). */
  async publishChatMessage(
    conversationId: string,
    message: Record<string, unknown>,
  ) {
    const peers = await this.participants.find({
      where: { conversationId },
      select: ['userId', 'muted'],
    });
    const allIds = peers.map((p) => p.userId);
    const badgeIds = peers.filter((p) => !p.muted).map((p) => p.userId);
    this.realtime.publishChatMessage({
      userIds: allIds,
      conversationId,
      message,
      badgeUserIds: badgeIds,
    });
  }

  /**
   * Customer “Talk to staff”: pause AI, ensure desk assignee(s) on the thread,
   * notify them. Order → existing assignee (form optional). Support → branch +
   * desk from handoff form (required). Soft claim: first staff who replies
   * already pauses AI (existing behaviour).
   */
  async requestStaff(
    actor: AuthUser,
    conversationId: string,
    opts?: RequestStaffOptions | string | null,
  ) {
    const options: RequestStaffOptions =
      typeof opts === 'string' || opts == null
        ? { locale: opts as string | null | undefined }
        : opts;
    const clientLocale = options.locale;
    const branchIn = options.branch?.trim() || null;
    const serviceKeyIn = options.serviceKey?.trim() || null;
    const orderRef = options.orderRef?.trim() || null;
    const note = options.note?.trim() || null;

    const me = await this.users.findOne({
      where: { id: actor.userId },
      select: ['id', 'role', 'name'],
    });
    if (!me || me.role !== UserRole.Customer) {
      throw new ForbiddenException('Customers only');
    }
    await this.requireParticipant(actor.userId, conversationId);

    const conv = await this.conversations.findOne({
      where: { id: conversationId },
    });
    if (!conv) throw new NotFoundException('Conversation not found');
    if (
      conv.kind !== ConversationKind.Support &&
      conv.kind !== ConversationKind.Order
    ) {
      throw new BadRequestException(
        'Talk to staff is only for support or order chats',
      );
    }

    if (conv.kind === ConversationKind.Support) {
      if (!branchIn) {
        throw new BadRequestException(
          'branch is required for support handoff',
        );
      }
      if (!serviceKeyIn) {
        throw new BadRequestException(
          'serviceKey (or desk) is required for support handoff',
        );
      }
    }

    const pause = await this.aiAutoReply.pauseForCustomerHandoff(conversationId);
    if (!pause.ok) throw new NotFoundException('Conversation not found');

    const deskKey =
      conv.kind === ConversationKind.Support
        ? resolveSupportDeskKey(serviceKeyIn)
        : null;

    const staffIds =
      conv.kind === ConversationKind.Order
        ? await this.resolveOrderStaffIds(conv)
        : await this.resolveSupportStaffIds(actor.userId, {
            branch: branchIn,
            deskKey: deskKey ?? undefined,
            requireExplicitBranch: true,
          });

    const addedIds: string[] = [];
    for (const staffId of staffIds) {
      if (staffId === actor.userId) continue;
      if (staffId === OBIC_AI_USER_ID) continue;
      const added = await this.ensureParticipant(conversationId, staffId);
      if (added) addedIds.push(staffId);
    }

    // Always notify resolved desk staff (even if already members).
    const notifyIds = [...new Set(staffIds)].filter(
      (id) => id !== actor.userId && id !== OBIC_AI_USER_ID,
    );
    if (notifyIds.length) {
      const refBit = orderRef ? ` · ref ${orderRef}` : '';
      const noteBit = note ? ` — ${note}` : '';
      await this.notifications.createForUsers({
        userIds: notifyIds,
        kind: NotificationKind.Message,
        title: 'Customer requested staff',
        body: `${me.name ?? 'Customer'} asked to talk to staff${refBit}${noteBit}`,
        data: {
          type: 'staff_handoff',
          conversationId,
          kind: conv.kind,
          orderId: conv.orderId ?? null,
          branch: branchIn,
          desk: deskKey,
          serviceKey: serviceKeyIn,
          orderRef,
          note,
        },
      });
    }

    let connectingPosted = false;
    if (pause.newlyPaused) {
      const lastCustomer = await this.messages.findOne({
        where: { conversationId, senderId: actor.userId },
        order: { createdAt: 'DESC' },
        select: ['id', 'body'],
      });
      const noticeLocale = resolveReplyLocale(
        lastCustomer?.body,
        clientLocale,
      );
      const notice = await this.aiAutoReply.postConnectingNotice(
        conversationId,
        noticeLocale,
      );
      connectingPosted = Boolean(notice);
    }

    await this.writeAudit(actor.userId, 'chat_request_staff', 'conversation', conversationId, {
      kind: conv.kind,
      staffIds,
      addedIds,
      notifyCount: notifyIds.length,
      branch: branchIn,
      desk: deskKey,
      serviceKey: serviceKeyIn,
      orderRef,
    });

    const summary = await this.getThreadSummary(conversationId);
    return {
      ...summary,
      aiAutoReplyEnabled: false,
      staffMemberIds: staffIds,
      addedMemberIds: addedIds,
      connectingPosted,
      alreadyHandedOff: !pause.newlyPaused && addedIds.length === 0,
      branch: branchIn,
      desk: deskKey,
    };
  }

  /** Staff: pause / resume AI auto-reply on a support or order thread. */
  async setAiAutoReply(
    actor: AuthUser,
    conversationId: string,
    enabled: boolean,
  ) {
    const user = await this.users.findOne({
      where: { id: actor.userId },
      select: ['id', 'role'],
    });
    if (
      !user ||
      (user.role !== UserRole.Employee && user.role !== UserRole.SuperAdmin)
    ) {
      throw new ForbiddenException('Staff only');
    }
    if (user.role !== UserRole.SuperAdmin) {
      await this.requireParticipant(actor.userId, conversationId);
    } else {
      const conv = await this.conversations.findOne({
        where: { id: conversationId },
      });
      if (!conv) throw new NotFoundException('Conversation not found');
    }
    const result = await this.aiAutoReply.setAutoReplyEnabled(
      actor,
      conversationId,
      enabled,
    );
    if (!result.ok) {
      if (result.error === 'staff_only') {
        throw new ForbiddenException('Staff only');
      }
      throw new NotFoundException('Conversation not found');
    }
    await this.writeAudit(actor.userId, 'ai_auto_reply_thread', 'conversation', conversationId, {
      enabled,
    });
    return result;
  }

  /**
   * SuperAdmin oversight list — Support / order / staff groups primary.
   * Filters: kind, q (participant name/email), from/to (last message), includeFriends.
   * Friend DMs (customer↔customer) only when includeFriends=true; joinable=false.
   */
  async listEmployeeChats(
    actor: AuthUser,
    filters?: {
      kind?: string;
      q?: string;
      from?: string;
      to?: string;
      includeFriends?: boolean;
    },
  ) {
    await this.requireSuperAdmin(actor);

    const kindFilter = (filters?.kind || '').trim().toLowerCase();
    const q = (filters?.q || '').trim().toLowerCase();
    const includeFriends = filters?.includeFriends === true;
    const from = filters?.from ? new Date(filters.from) : null;
    const to = filters?.to ? new Date(filters.to) : null;
    const fromOk = from && !Number.isNaN(from.getTime()) ? from : null;
    const toOk = to && !Number.isNaN(to.getTime()) ? to : null;

    const kinds: ConversationKind[] = [];
    if (kindFilter === 'support') kinds.push(ConversationKind.Support);
    else if (kindFilter === 'order') kinds.push(ConversationKind.Order);
    else if (kindFilter === 'group') kinds.push(ConversationKind.Group);
    else if (kindFilter === 'direct') kinds.push(ConversationKind.Direct);
    else {
      kinds.push(
        ConversationKind.Support,
        ConversationKind.Order,
        ConversationKind.Group,
        ConversationKind.Direct,
      );
    }

    const convs = await this.conversations.find({
      where: { kind: In(kinds) },
      order: { updatedAt: 'DESC' },
      take: 800,
    });

    const out = [];
    for (const conv of convs) {
      const peers = await this.participants.find({
        where: { conversationId: conv.id },
        relations: { user: true },
      });
      const hasStaff = peers.some(
        (p) =>
          p.user?.role === UserRole.Employee ||
          p.user?.role === UserRole.SuperAdmin,
      );
      const isFriendDm =
        conv.kind === ConversationKind.Direct && !hasStaff;

      // Primary: support / order / group (even before staff joins).
      // Direct with staff: staff↔customer.
      // Friend DM: only when includeFriends.
      if (conv.kind === ConversationKind.Direct) {
        if (isFriendDm && !includeFriends) continue;
        if (!isFriendDm && !hasStaff) continue;
      }

      const last = await this.messages.findOne({
        where: { conversationId: conv.id },
        order: { createdAt: 'DESC' },
      });
      const lastAt = last?.createdAt ?? conv.updatedAt;
      if (fromOk && lastAt < fromOk) continue;
      if (toOk && lastAt > toOk) continue;

      if (q) {
        const hay = peers
          .map((p) =>
            [p.user?.name, p.user?.email, p.user?.phone, conv.title]
              .filter(Boolean)
              .join(' ')
              .toLowerCase(),
          )
          .join(' ');
        if (!hay.includes(q) && !(last?.body || '').toLowerCase().includes(q)) {
          continue;
        }
      }

      const iAmMember = peers.some((p) => p.userId === actor.userId);
      const joinable =
        conv.kind === ConversationKind.Support ||
        conv.kind === ConversationKind.Order ||
        conv.kind === ConversationKind.Group;

      out.push({
        id: conv.id,
        kind: conv.kind,
        title: conv.title ?? null,
        orderId: conv.orderId ?? null,
        aiAutoReplyEnabled: conv.aiAutoReplyEnabled ?? true,
        updatedAt: conv.updatedAt,
        createdAt: conv.createdAt,
        iAmMember,
        joinable,
        friendDm: isFriendDm,
        participants: peers.map((x) => ({
          userId: x.userId,
          name: x.user?.name ?? null,
          role: x.user?.role ?? null,
          avatarUrl: x.user?.avatarUrl ?? null,
        })),
        lastMessage: last
          ? {
              id: last.id,
              body: last.body,
              attachmentKind: last.attachmentKind,
              senderId: last.senderId,
              isAi: last.isAi ?? false,
              createdAt: last.createdAt,
            }
          : null,
        ...(await this.orderMeta(conv.orderId)),
      });
    }

    out.sort((a, b) => {
      const ta =
        a.lastMessage?.createdAt?.getTime?.() ??
        new Date(a.updatedAt).getTime();
      const tb =
        b.lastMessage?.createdAt?.getTime?.() ??
        new Date(b.updatedAt).getTime();
      return tb - ta;
    });

    await this.writeAudit(actor.userId, 'list_employee_chats', 'conversation', null, {
      count: out.length,
      kind: kindFilter || null,
      includeFriends,
    });
    return out;
  }

  /**
   * SuperAdmin oversight transcript — IDOR-safe (admin only).
   * Friend DMs: read-only with audit (joinable=false).
   * Support / order / group: full history + join flag.
   */
  async adminReadTranscript(actor: AuthUser, conversationId: string) {
    await this.requireSuperAdmin(actor);
    const conv = await this.conversations.findOne({
      where: { id: conversationId },
    });
    if (!conv) throw new NotFoundException('Conversation not found');

    const peers = await this.participants.find({
      where: { conversationId },
      relations: { user: true },
    });
    const hasStaff = peers.some(
      (p) =>
        p.user?.role === UserRole.Employee ||
        p.user?.role === UserRole.SuperAdmin,
    );
    const isFriendDm =
      conv.kind === ConversationKind.Direct && !hasStaff;

    const rows = await this.messages.find({
      where: { conversationId },
      relations: { sender: true },
      order: { createdAt: 'ASC' },
      take: 500,
    });

    const joinable =
      conv.kind === ConversationKind.Support ||
      conv.kind === ConversationKind.Order ||
      conv.kind === ConversationKind.Group;
    const iAmMember = peers.some((p) => p.userId === actor.userId);

    await this.writeAudit(
      actor.userId,
      isFriendDm ? 'read_friend_dm' : 'read_transcript',
      'conversation',
      conversationId,
      { messageCount: rows.length, friendDm: isFriendDm },
    );

    return {
      conversationId,
      kind: conv.kind,
      title: conv.title ?? null,
      orderId: conv.orderId ?? null,
      aiAutoReplyEnabled: conv.aiAutoReplyEnabled ?? true,
      joinable,
      friendDm: isFriendDm,
      iAmMember,
      participants: peers.map((x) => ({
        userId: x.userId,
        name: x.user?.name ?? null,
        role: x.user?.role ?? null,
        avatarUrl: x.user?.avatarUrl ?? null,
      })),
      messages: rows.map((m) => this.messageDto(m)),
      audit: 'logged',
    };
  }

  /**
   * SuperAdmin joins Support / order / group as a participant (audited).
   * Friend DMs are read-only — refuse join.
   */
  async adminJoinThread(actor: AuthUser, conversationId: string) {
    await this.requireSuperAdmin(actor);
    const conv = await this.conversations.findOne({
      where: { id: conversationId },
    });
    if (!conv) throw new NotFoundException('Conversation not found');

    if (
      conv.kind !== ConversationKind.Support &&
      conv.kind !== ConversationKind.Order &&
      conv.kind !== ConversationKind.Group
    ) {
      throw new ForbiddenException(
        'Join is only for Support, order, and group chats — friend DMs are read-only oversight',
      );
    }

    const added = await this.ensureParticipant(conversationId, actor.userId);
    await this.writeAudit(
      actor.userId,
      'join_conversation',
      'conversation',
      conversationId,
      { kind: conv.kind, alreadyMember: !added },
    );

    if (added) {
      const peers = await this.participants.find({
        where: { conversationId },
        select: ['userId'],
      });
      const others = peers
        .map((p) => p.userId)
        .filter((id) => id !== actor.userId && id !== OBIC_AI_USER_ID);
      if (others.length) {
        const me = await this.users.findOne({
          where: { id: actor.userId },
          select: ['id', 'name'],
        });
        await this.notifications.createForUsers({
          userIds: others,
          kind: NotificationKind.System,
          title: 'Staff joined chat',
          body: `${me?.name ?? 'Admin'} joined this conversation`,
          data: { conversationId, kind: conv.kind },
        });
      }
    }

    const summary = await this.getThreadSummary(conversationId);
    return {
      ...summary,
      joined: true,
      alreadyMember: !added,
      iAmMember: true,
      joinable: true,
    };
  }

  /** True when at least one participant is Employee or SuperAdmin. */
  private async conversationHasEmployee(conversationId: string) {
    const parts = await this.participants.find({
      where: { conversationId },
      relations: { user: true },
    });
    return parts.some(
      (p) =>
        p.user?.role === UserRole.Employee ||
        p.user?.role === UserRole.SuperAdmin,
    );
  }

  private async requireSuperAdmin(actor: AuthUser) {
    // Defense in depth: re-check DB even after RolesGuard.
    const user = await this.users.findOne({
      where: { id: actor.userId },
      select: ['id', 'role'],
    });
    if (!user || user.role !== UserRole.SuperAdmin) {
      throw new ForbiddenException('SuperAdmin only');
    }
  }

  private async countUnread(
    conversationId: string,
    userId: string,
    lastReadAt: Date | null,
  ) {
    const qb = this.messages
      .createQueryBuilder('m')
      .where('m.conversation_id = :conversationId', { conversationId })
      .andWhere('m.sender_id != :userId', { userId });
    if (lastReadAt) {
      qb.andWhere('m.created_at > :lastReadAt', { lastReadAt });
    }
    return qb.getCount();
  }

  private async markThreadRead(userId: string, conversationId: string) {
    await this.participants.update(
      { conversationId, userId },
      { lastReadAt: new Date() },
    );
  }

  private async requireParticipant(userId: string, conversationId: string) {
    const p = await this.participants.findOne({
      where: { conversationId, userId },
    });
    if (!p) {
      // Prefer 404 so callers cannot probe other users' threads.
      throw new NotFoundException('Conversation not found');
    }
    return p;
  }

  private async findDirectBetween(a: string, b: string) {
    const rows: Array<{ conversation_id: string }> = await this.conversations.query(
      `
      SELECT c.id AS conversation_id
      FROM conversations c
      JOIN conversation_participants p1
        ON p1.conversation_id = c.id AND p1.user_id = $1
      JOIN conversation_participants p2
        ON p2.conversation_id = c.id AND p2.user_id = $2
      WHERE c.kind = 'direct'
      LIMIT 1
      `,
      [a, b],
    );
    if (!rows.length) return null;
    return this.conversations.findOne({ where: { id: rows[0].conversation_id } });
  }

  private async orderMeta(orderId: string | null) {
    if (!orderId) {
      return { orderStatus: null as string | null, serviceSlug: null as string | null };
    }
    const order = await this.orders.findOne({
      where: { id: orderId },
      relations: { service: true },
    });
    return {
      orderStatus: order?.status ?? null,
      serviceSlug: order?.service?.slug ?? null,
    };
  }

  /** Customer reply while waiting resumes work. Staff reply while assigned starts work. */
  private async afterOrderMessage(actor: AuthUser, conversationId: string) {
    const conv = await this.conversations.findOne({
      where: { id: conversationId },
    });
    if (!conv?.orderId || conv.kind !== ConversationKind.Order) return;

    const order = await this.orders.findOne({ where: { id: conv.orderId } });
    if (!order) return;

    const isCustomer = order.userId === actor.userId;
    const isAssignee = order.assignedEmployeeId === actor.userId;
    let next: OrderStatus | null = null;
    if (isCustomer && order.status === OrderStatus.WaitingCustomer) {
      next = OrderStatus.InProgress;
    } else if (isAssignee && order.status === OrderStatus.Assigned) {
      next = OrderStatus.InProgress;
    }

    if (next) {
      order.status = next;
      await this.orders.save(order);
      const note = await this.messages.save(
        this.messages.create({
          conversationId,
          senderId: actor.userId,
          body: statusNoteBody(next),
        }),
      );
      const withSender = await this.messages.findOne({
        where: { id: note.id },
        relations: { sender: true },
      });
      await this.publishChatMessage(
        conversationId,
        this.messageDto(withSender ?? note),
      );
    }

    const notifyIds: string[] = [];
    if (isCustomer && order.assignedEmployeeId) {
      notifyIds.push(order.assignedEmployeeId);
    } else if (!isCustomer && order.userId !== actor.userId) {
      notifyIds.push(order.userId);
    }
    if (!notifyIds.length) return;

    // Skip muted recipients (WeChat mute chat).
    const parts = await this.participants.find({
      where: notifyIds.map((userId) => ({ conversationId, userId })),
    });
    const muted = new Set(parts.filter((p) => p.muted).map((p) => p.userId));
    const liveIds = notifyIds.filter((id) => !muted.has(id));
    if (!liveIds.length) return;

    await this.notifications.createForUsers({
      userIds: liveIds,
      kind: next ? NotificationKind.OrderStatus : NotificationKind.Message,
      title: next ? 'Order status updated' : 'New order message',
      body: next
        ? `This order is now ${next}`
        : 'You have a new message on an order',
      data: {
        type: 'order_chat',
        orderId: order.id,
        conversationId,
        status: order.status,
      },
    });
  }

  private async findSupportForUser(userId: string) {
    const rows: Array<{ conversation_id: string }> = await this.conversations.query(
      `
      SELECT c.id AS conversation_id
      FROM conversations c
      JOIN conversation_participants p
        ON p.conversation_id = c.id AND p.user_id = $1
      WHERE c.kind = 'support'
      ORDER BY c.updated_at DESC
      LIMIT 1
      `,
      [userId],
    );
    if (!rows.length) return null;
    return this.conversations.findOne({ where: { id: rows[0].conversation_id } });
  }

  private async getThreadSummary(conversationId: string) {
    const conv = await this.conversations.findOne({
      where: { id: conversationId },
    });
    if (!conv) throw new NotFoundException('Conversation not found');
    const peers = await this.participants.find({
      where: { conversationId },
      relations: { user: true },
    });
    const last = await this.messages.findOne({
      where: { conversationId },
      order: { createdAt: 'DESC' },
    });
    return {
      id: conv.id,
      kind: conv.kind,
      title: conv.title ?? null,
      orderId: conv.orderId ?? null,
      aiAutoReplyEnabled: conv.aiAutoReplyEnabled ?? true,
      updatedAt: conv.updatedAt,
      participants: peers.map((x) => ({
        userId: x.userId,
        name: x.user?.name ?? null,
        role: x.user?.role ?? null,
        avatarUrl: x.user?.avatarUrl ?? null,
      })),
      lastMessage: last
        ? {
            id: last.id,
            body: last.body,
            attachmentKind: last.attachmentKind,
            senderId: last.senderId,
            isAi: last.isAi ?? false,
            createdAt: last.createdAt,
          }
        : null,
      ...(await this.orderMeta(conv.orderId)),
    };
  }

  private messageDto(m: Message) {
    return {
      id: m.id,
      conversationId: m.conversationId,
      senderId: m.senderId,
      senderName: m.sender?.name ?? null,
      senderAvatarUrl: m.sender?.avatarUrl ?? null,
      body: m.body,
      attachmentKind: m.attachmentKind,
      attachmentName: m.attachmentName,
      attachmentUrl: m.attachmentUrl,
      isAi: m.isAi ?? false,
      createdAt: m.createdAt,
    };
  }

  private async writeAudit(
    actorId: string | null,
    action: string,
    resourceType: string,
    resourceId: string | null,
    meta?: Record<string, unknown>,
  ) {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action,
        resourceType,
        resourceId,
        meta: meta ?? null,
      }),
    );
  }

  /** @returns true when a new participant row was inserted. */
  private async ensureParticipant(
    conversationId: string,
    userId: string,
  ): Promise<boolean> {
    const existing = await this.participants.findOne({
      where: { conversationId, userId },
    });
    if (existing) return false;
    await this.participants.save(
      this.participants.create({ conversationId, userId }),
    );
    return true;
  }

  /**
   * Order chat: keep assignee = branch + service desk (same as OrdersService).
   * Re-resolve if missing; sync via OrderChatService.
   */
  private async resolveOrderStaffIds(conv: Conversation): Promise<string[]> {
    if (!conv.orderId) return [];
    const order = await this.orders.findOne({
      where: { id: conv.orderId },
      relations: { service: true },
    });
    if (!order) return [];

    let assigneeId = order.assignedEmployeeId;
    if (!assigneeId) {
      const branch = order.preferredBranch ?? DEFAULT_SUPPORT_BRANCH;
      const slug = order.service?.slug ?? 'consultations';
      assigneeId = await this.resolveOrderAssignee(slug, branch);
      if (assigneeId) {
        order.assignedEmployeeId = assigneeId;
        if (order.status === OrderStatus.Submitted) {
          order.status = OrderStatus.Assigned;
        }
        await this.orders.save(order);
      }
    }

    await this.orderChat.syncParticipants(conv.id, order);

    const ids = new Set<string>();
    if (order.assignedEmployeeId) ids.add(order.assignedEmployeeId);

    // If still nobody, fall back to support queue so customer is not alone.
    if (!ids.size) {
      for (const id of await this.resolveSupportStaffIds(order.userId, {
        branch: order.preferredBranch,
      })) {
        ids.add(id);
      }
    }
    return [...ids];
  }

  /** Mirror OrdersService.resolveAssignee — branch desk email then fallbacks. */
  private async resolveOrderAssignee(
    serviceSlug: string,
    branch: string,
  ): Promise<string | null> {
    const deskKey = deskKeyForServiceSlug(serviceSlug);
    const primaryEmail = branchEmailDesk(branch, deskKey);

    let emp = await this.users.findOne({
      where: { email: primaryEmail, role: UserRole.Employee },
    });

    if (
      !emp &&
      (serviceSlug === 'hotels' ||
        serviceSlug === 'flights' ||
        serviceSlug === 'vip')
    ) {
      emp = await this.users.findOne({
        where: {
          branchLabel: branch,
          role: UserRole.Employee,
          offersAccess: true,
        },
      });
    }

    if (!emp) {
      emp = await this.users.findOne({
        where: { branchLabel: branch, role: UserRole.Employee },
      });
    }

    if (emp?.id === OBIC_AI_USER_ID) return null;
    return emp?.id ?? null;
  }

  /**
   * Support queue: desk @ branch → secretary @ branch → opsAccess @ branch →
   * any staff @ branch → any opsAccess → SuperAdmin.
   * Seed: temp.{branch}.{desk}@obic.local
   */
  private async resolveSupportStaffIds(
    customerUserId: string,
    opts?: {
      branch?: string | null;
      deskKey?: string | null;
      /** When true, do not fall back to latest-order branch (form already chose). */
      requireExplicitBranch?: boolean;
    },
  ): Promise<string[]> {
    const preferred = opts?.branch?.trim() || null;
    let branch = resolveSupportBranch(preferred);
    if (!preferred && !opts?.requireExplicitBranch) {
      const recent = await this.orders.findOne({
        where: { userId: customerUserId },
        order: { createdAt: 'DESC' },
      });
      branch = resolveSupportBranch(recent?.preferredBranch);
    }

    const deskKey = resolveSupportDeskKey(opts?.deskKey);
    const ids: string[] = [];
    const push = (u: User | null | undefined) => {
      if (!u?.id || u.id === OBIC_AI_USER_ID || u.id === customerUserId) return;
      if (!ids.includes(u.id)) ids.push(u.id);
    };

    push(
      await this.users.findOne({
        where: {
          email: supportDeskEmail(branch, deskKey),
          role: UserRole.Employee,
        },
      }),
    );

    // If non-secretary desk missing, try secretary at same branch.
    if (!ids.length && deskKey !== 'secretary') {
      push(
        await this.users.findOne({
          where: {
            email: supportDeskEmail(branch, 'secretary'),
            role: UserRole.Employee,
          },
        }),
      );
    }

    if (!ids.length) {
      const ops = await this.users.find({
        where: {
          role: UserRole.Employee,
          opsAccess: true,
          branchLabel: branch,
        },
        take: 5,
      });
      for (const u of ops) push(u);
    }

    if (!ids.length) {
      const branchStaff = await this.users.find({
        where: { role: UserRole.Employee, branchLabel: branch },
        take: 5,
      });
      for (const u of branchStaff) push(u);
    }

    if (!ids.length) {
      const anyOps = await this.users.find({
        where: { role: UserRole.Employee, opsAccess: true },
        take: 5,
      });
      for (const u of anyOps) push(u);
    }

    if (!ids.length) {
      const admin = await this.users.findOne({
        where: { role: UserRole.SuperAdmin },
      });
      push(admin);
    }

    return ids;
  }
}
