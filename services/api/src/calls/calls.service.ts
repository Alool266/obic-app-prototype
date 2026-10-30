// Made by Dr Ali
// Phase 5 M5.1–M5.2 — create/ring + mint scoped Agora RTC tokens.
// ACL = conversation participants (direct, support, group, order — same rule).

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomUUID } from 'crypto';
import { Repository } from 'typeorm';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { Conversation } from '../chat/conversation.entity';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { RealtimeService } from '../realtime/realtime.service';
import { NotificationsService } from '../notifications/notifications.service';
import { User } from '../users/user.entity';
import {
  agoraUidFromUserId,
  mintRtcToken,
} from './agora-token.util';
import { AGORA_CONSOLE_URL, CallsConfig } from './calls.config';
import { CreateCallDto } from './dto/calls.dto';

export type CallMode = 'voice' | 'video';

export type CallSession = {
  id: string;
  conversationId: string;
  channelName: string;
  mode: CallMode;
  createdBy: string;
  createdAt: Date;
  /** Soft expiry for in-memory cleanup (~token TTL). */
  expiresAt: Date;
  ended: boolean;
  conversationKind: string;
  conversationTitle: string | null;
  /** People currently in the channel. The call ends when this is empty. */
  joinedUserIds: string[];
};

export type CallJoinPayload = {
  callId: string;
  conversationId: string;
  channelName: string;
  mode: CallMode;
  appId: string;
  token: string;
  uid: number;
  expiresAt: string;
  /** True when Agora is live; false only in unit tests with mocks. */
  live: boolean;
  /** Conversation kind (direct | support | group | order). */
  conversationKind: string;
  conversationTitle: string | null;
  /** True when kind === group — clients leave without ending for peers. */
  isGroup: boolean;
};

@Injectable()
export class CallsService {
  private readonly logger = new Logger(CallsService.name);
  /** Ephemeral sessions — single-instance trial; ACL re-checked on every token. */
  private readonly sessions = new Map<string, CallSession>();

  constructor(
    private readonly config: CallsConfig,
    private readonly realtime: RealtimeService,
    private readonly notifications: NotificationsService,
    @InjectRepository(Conversation)
    private readonly conversations: Repository<Conversation>,
    @InjectRepository(ConversationParticipant)
    private readonly participants: Repository<ConversationParticipant>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
  ) {}

  status() {
    return {
      configured: this.config.configured,
      consoleUrl: AGORA_CONSOLE_URL,
      /** App ID is public; certificate never returned. */
      hasAppId: this.config.appId.length > 0,
      hasCertificate: this.config.appCertificate.length > 0,
    };
  }

  async createCall(
    actor: AuthUser,
    dto: CreateCallDto,
  ): Promise<CallJoinPayload> {
    this.assertConfigured();
    const conv = await this.requireParticipant(actor.userId, dto.conversationId);

    const callId = randomUUID();
    const channelName = `obic_${callId.replace(/-/g, '').slice(0, 24)}`;
    const ttl = this.config.tokenTtlSeconds;
    const expiresAt = new Date(Date.now() + ttl * 1000);
    const session: CallSession = {
      id: callId,
      conversationId: dto.conversationId,
      channelName,
      mode: dto.mode,
      createdBy: actor.userId,
      createdAt: new Date(),
      expiresAt,
      ended: false,
      conversationKind: conv.kind,
      conversationTitle: conv.title ?? null,
      joinedUserIds: [actor.userId],
    };
    this.sessions.set(callId, session);
    this.pruneExpired();

    const join = this.mintForUser(session, actor.userId);

    // Ring every other participant (group = all members; 1:1 = the peer).
    const peers = await this.participants.find({
      where: { conversationId: dto.conversationId },
    });
    let calleeIds = peers
      .map((p) => p.userId)
      .filter((id) => id !== actor.userId);
    if (dto.inviteUserIds?.length) {
      const allowed = new Set(calleeIds);
      const picked = [...new Set(dto.inviteUserIds)].filter((id) => allowed.has(id));
      const cap = dto.mode === 'video' ? 8 : 15;
      if (!picked.length) {
        throw new BadRequestException('Pick at least one person in this chat');
      }
      if (picked.length > cap) {
        throw new BadRequestException(
          dto.mode === 'video'
            ? 'Video calls can include up to 9 people'
            : 'Voice calls can include up to 16 people',
        );
      }
      calleeIds = picked;
    }

    const caller = await this.users.findOne({ where: { id: actor.userId } });
    const isGroup = conv.kind === 'group';
    this.realtime.publishCallIncoming({
      userIds: calleeIds,
      payload: {
        callId,
        conversationId: dto.conversationId,
        channelName,
        mode: dto.mode,
        fromUserId: actor.userId,
        fromName: caller?.name ?? 'OBIC',
        fromAvatarUrl: caller?.avatarUrl ?? null,
        conversationKind: conv.kind,
        conversationTitle: conv.title ?? null,
        isGroup,
      },
    });
    if (calleeIds.length) {
      void this.notifications.pushAlert({
        userIds: calleeIds,
        title: caller?.name ?? 'OBIC',
        body: dto.mode === 'video' ? 'مكالمة فيديو' : 'مكالمة صوتية',
        data: {
          kind: 'call',
          callId,
          conversationId: dto.conversationId,
          channelName,
          mode: dto.mode,
          fromUserId: actor.userId,
          fromName: caller?.name ?? 'OBIC',
          conversationKind: conv.kind,
          conversationTitle: conv.title ?? '',
          isGroup: isGroup ? '1' : '0',
        },
      });
    }

    this.logger.log(
      `call created id=${callId} mode=${dto.mode} kind=${conv.kind} conv=${dto.conversationId} ring=${calleeIds.length}`,
    );
    return join;
  }

  async mintToken(actor: AuthUser, callId: string): Promise<CallJoinPayload> {
    this.assertConfigured();
    const session = this.sessions.get(callId);
    if (!session || session.ended || session.expiresAt.getTime() < Date.now()) {
      throw new NotFoundException('Call not found or expired');
    }
    await this.requireParticipant(actor.userId, session.conversationId);
    if (!session.joinedUserIds.includes(actor.userId)) {
      session.joinedUserIds.push(actor.userId);
    }
    const join = this.mintForUser(session, actor.userId);
    this.logger.log(
      `call token minted id=${callId} uid=${join.uid} user=${actor.userId}`,
    );
    return join;
  }

  /**
   * Rings still open for this user as callee (not creator). Used by mobile
   * poll so a missed Socket.IO `call:incoming` still shows the accept UI.
   */
  async listIncoming(actor: AuthUser): Promise<
    Array<{
      callId: string;
      conversationId: string;
      channelName: string;
      mode: CallMode;
      fromUserId: string;
      fromName: string;
      fromAvatarUrl: string | null;
      conversationKind: string;
      conversationTitle: string | null;
      isGroup: boolean;
      createdAt: string;
      expiresAt: string;
    }>
  > {
    this.pruneExpired();
    const out: Array<{
      callId: string;
      conversationId: string;
      channelName: string;
      mode: CallMode;
      fromUserId: string;
      fromName: string;
      fromAvatarUrl: string | null;
      conversationKind: string;
      conversationTitle: string | null;
      isGroup: boolean;
      createdAt: string;
      expiresAt: string;
    }> = [];

    for (const session of this.sessions.values()) {
      if (session.ended) continue;
      if (session.createdBy === actor.userId) continue;
      if (session.expiresAt.getTime() < Date.now()) continue;
      const p = await this.participants.findOne({
        where: {
          conversationId: session.conversationId,
          userId: actor.userId,
        },
      });
      if (!p) continue;
      const caller = await this.users.findOne({
        where: { id: session.createdBy },
      });
      out.push({
        callId: session.id,
        conversationId: session.conversationId,
        channelName: session.channelName,
        mode: session.mode,
        fromUserId: session.createdBy,
        fromName: caller?.name ?? 'OBIC',
        fromAvatarUrl: caller?.avatarUrl ?? null,
        conversationKind: session.conversationKind,
        conversationTitle: session.conversationTitle,
        isGroup: session.conversationKind === 'group',
        createdAt: session.createdAt.toISOString(),
        expiresAt: session.expiresAt.toISOString(),
      });
    }
    return out;
  }

  async active(actor: AuthUser, conversationId: string) {
    await this.requireParticipant(actor.userId, conversationId);
    this.pruneExpired();
    for (const session of this.sessions.values()) {
      if (session.ended) continue;
      if (session.conversationId !== conversationId) continue;
      if (session.expiresAt.getTime() < Date.now()) continue;
      const ids = session.joinedUserIds ?? [];
      if (!ids.length) continue;
      return {
        call: {
          callId: session.id,
          mode: session.mode,
          count: ids.length,
          title: session.conversationTitle,
          conversationId: session.conversationId,
        },
      };
    }
    return { call: null };
  }

  async invite(actor: AuthUser, callId: string, userIds: string[]) {
    const session = this.sessions.get(callId);
    if (!session || session.ended || session.expiresAt.getTime() < Date.now()) {
      throw new NotFoundException('Call not found or expired');
    }
    await this.requireParticipant(actor.userId, session.conversationId);
    const peers = await this.participants.find({
      where: { conversationId: session.conversationId },
    });
    const allowed = new Set(peers.map((p) => p.userId));
    const cap = session.mode === 'video' ? 9 : 16;
    const already = new Set(session.joinedUserIds);
    const picked = [...new Set(userIds)].filter(
      (id) => allowed.has(id) && id !== actor.userId && !already.has(id),
    );
    if (already.size + picked.length > cap) {
      throw new BadRequestException(
        session.mode === 'video'
          ? 'Video calls can include up to 9 people'
          : 'Voice calls can include up to 16 people',
      );
    }
    if (!picked.length) return { ok: true, callId, invited: 0 };
    const caller = await this.users.findOne({ where: { id: actor.userId } });
    this.realtime.publishCallIncoming({
      userIds: picked,
      payload: {
        callId,
        conversationId: session.conversationId,
        channelName: session.channelName,
        mode: session.mode,
        fromUserId: actor.userId,
        fromName: caller?.name ?? 'OBIC',
        fromAvatarUrl: caller?.avatarUrl ?? null,
        conversationKind: session.conversationKind,
        conversationTitle: session.conversationTitle,
        isGroup: session.conversationKind === 'group',
      },
    });
    void this.notifications.pushAlert({
      userIds: picked,
      title: caller?.name ?? 'OBIC',
      body: session.mode === 'video' ? 'مكالمة فيديو' : 'مكالمة صوتية',
      data: {
        kind: 'call',
        callId,
        conversationId: session.conversationId,
        channelName: session.channelName,
        mode: session.mode,
        fromUserId: actor.userId,
        fromName: caller?.name ?? 'OBIC',
        conversationKind: session.conversationKind,
        conversationTitle: session.conversationTitle ?? '',
        isGroup: session.conversationKind === 'group' ? '1' : '0',
      },
    });
    return { ok: true, callId, invited: picked.length };
  }

  /** Group: drop this person. End the call only when nobody is left. */
  async leave(actor: AuthUser, callId: string) {
    const session = this.sessions.get(callId);
    if (!session) throw new NotFoundException('Call not found');
    await this.requireParticipant(actor.userId, session.conversationId);
    if (session.conversationKind !== 'group') {
      return this.endCall(actor, callId);
    }
    session.joinedUserIds = (session.joinedUserIds ?? []).filter(
      (id) => id !== actor.userId,
    );
    if (!session.joinedUserIds.length) {
      return this.endCall(actor, callId);
    }
    return { ok: true, callId, count: session.joinedUserIds.length };
  }

  async endCall(actor: AuthUser, callId: string) {
    const session = this.sessions.get(callId);
    if (!session) {
      throw new NotFoundException('Call not found');
    }
    await this.requireParticipant(actor.userId, session.conversationId);
    session.ended = true;
    const peers = await this.participants.find({
      where: { conversationId: session.conversationId },
    });
    const peerIds = peers.map((p) => p.userId);
    this.realtime.publishCallEnded({
      userIds: peerIds,
      payload: {
        callId,
        conversationId: session.conversationId,
        endedBy: actor.userId,
      },
    });
    const notify = peerIds.filter((id) => id !== actor.userId);
    if (notify.length) {
      void this.notifications.pushAlert({
        userIds: notify,
        title: 'OBIC',
        body: '',
        data: {
          kind: 'call_ended',
          callId,
          conversationId: session.conversationId,
          endedBy: actor.userId,
        },
      });
    }
    return { ok: true, callId };
  }

  /** Test helper — inject a session without Agora mint. */
  putSessionForTests(session: CallSession) {
    this.sessions.set(session.id, session);
  }

  private mintForUser(session: CallSession, userId: string): CallJoinPayload {
    const uid = agoraUidFromUserId(userId);
    const { token, expiresAt } = mintRtcToken({
      appId: this.config.appId,
      appCertificate: this.config.appCertificate,
      channelName: session.channelName,
      uid,
      ttlSeconds: this.config.tokenTtlSeconds,
    });
    return {
      callId: session.id,
      conversationId: session.conversationId,
      channelName: session.channelName,
      mode: session.mode,
      appId: this.config.appId,
      token,
      uid,
      expiresAt,
      live: true,
      conversationKind: session.conversationKind,
      conversationTitle: session.conversationTitle,
      isGroup: session.conversationKind === 'group',
    };
  }

  private assertConfigured() {
    if (!this.config.configured) {
      throw new ServiceUnavailableException(
        `Agora is not configured. Set AGORA_APP_ID and AGORA_APP_CERTIFICATE (free project at ${AGORA_CONSOLE_URL}).`,
      );
    }
  }

  /**
   * Non-member → 403 (explicit ACL for calls; chat uses 404 to avoid probing).
   * Group ACL = every ConversationParticipant row (incl. SuperAdmin if joined).
   */
  private async requireParticipant(
    userId: string,
    conversationId: string,
  ): Promise<Conversation> {
    const conv = await this.conversations.findOne({
      where: { id: conversationId },
    });
    if (!conv) {
      throw new NotFoundException('Conversation not found');
    }
    const p = await this.participants.findOne({
      where: { conversationId, userId },
    });
    if (!p) {
      throw new ForbiddenException('Not a participant of this conversation');
    }
    return conv;
  }

  private pruneExpired() {
    const now = Date.now();
    for (const [id, s] of this.sessions) {
      if (s.ended || s.expiresAt.getTime() < now) {
        this.sessions.delete(id);
      }
    }
  }
}
