// Made by Dr Ali
// Live location stays in memory and only for people in that chat.
// It is dropped when someone stops or the chosen time ends.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { RealtimeService } from '../realtime/realtime.service';
import { User } from '../users/user.entity';
import { Conversation, ConversationKind } from './conversation.entity';
import { ConversationParticipant } from './conversation-participant.entity';

export type LiveShare = {
  userId: string;
  name: string;
  avatarUrl: string | null;
  lat: number;
  lng: number;
  accuracy: number | null;
  expiresAt: string;
};

@Injectable()
export class LiveLocationService implements OnModuleInit, OnModuleDestroy {
  private readonly shares = new Map<string, LiveShare & { conversationId: string; expiresMs: number }>();
  private timer: NodeJS.Timeout | null = null;

  constructor(
    @InjectRepository(Conversation)
    private readonly conversations: Repository<Conversation>,
    @InjectRepository(ConversationParticipant)
    private readonly participants: Repository<ConversationParticipant>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    private readonly realtime: RealtimeService,
  ) {}

  onModuleInit() {
    this.timer = setInterval(() => {
      void this.prune();
    }, 15_000);
  }

  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
  }

  async list(actor: AuthUser, conversationId: string): Promise<{ shares: LiveShare[] }> {
    await this.assertMember(actor.userId, conversationId);
    this.dropExpired(conversationId);
    return { shares: this.rows(conversationId) };
  }

  async upsert(
    actor: AuthUser,
    input: {
      conversationId: string;
      lat: number;
      lng: number;
      accuracy?: number;
      minutes?: number;
    },
  ): Promise<{ shares: LiveShare[] }> {
    await this.assertMember(actor.userId, input.conversationId);
    if (!Number.isFinite(input.lat) || !Number.isFinite(input.lng)) {
      throw new BadRequestException('Location is not valid');
    }
    const key = this.key(input.conversationId, actor.userId);
    const existing = this.shares.get(key);
    const minutes = input.minutes;
    if (!existing && (minutes !== 15 && minutes !== 60 && minutes !== 480)) {
      throw new BadRequestException('Choose 15 minutes, 1 hour, or 8 hours');
    }
    const user = await this.users.findOne({ where: { id: actor.userId } });
    const expiresMs = existing && minutes == null
      ? existing.expiresMs
      : Date.now() + (minutes ?? 15) * 60_000;
    this.shares.set(key, {
      conversationId: input.conversationId,
      userId: actor.userId,
      name: user?.name?.trim() || 'OBIC',
      avatarUrl: user?.avatarUrl ?? null,
      lat: input.lat,
      lng: input.lng,
      accuracy: Number.isFinite(input.accuracy) ? input.accuracy! : null,
      expiresMs,
      expiresAt: new Date(expiresMs).toISOString(),
    });
    const shares = this.rows(input.conversationId);
    await this.broadcast(input.conversationId, shares);
    return { shares };
  }

  async stop(actor: AuthUser, conversationId: string): Promise<{ shares: LiveShare[] }> {
    await this.assertMember(actor.userId, conversationId);
    this.shares.delete(this.key(conversationId, actor.userId));
    const shares = this.rows(conversationId);
    await this.broadcast(conversationId, shares);
    return { shares };
  }

  private async prune() {
    const touched = new Set<string>();
    const now = Date.now();
    for (const [key, row] of this.shares) {
      if (row.expiresMs > now) continue;
      touched.add(row.conversationId);
      this.shares.delete(key);
    }
    for (const conversationId of touched) {
      await this.broadcast(conversationId, this.rows(conversationId));
    }
  }

  private dropExpired(conversationId: string) {
    const now = Date.now();
    for (const [key, row] of this.shares) {
      if (row.conversationId === conversationId && row.expiresMs <= now) {
        this.shares.delete(key);
      }
    }
  }

  private rows(conversationId: string): LiveShare[] {
    const out: LiveShare[] = [];
    for (const row of this.shares.values()) {
      if (row.conversationId !== conversationId) continue;
      out.push({
        userId: row.userId,
        name: row.name,
        avatarUrl: row.avatarUrl,
        lat: row.lat,
        lng: row.lng,
        accuracy: row.accuracy,
        expiresAt: row.expiresAt,
      });
    }
    return out;
  }

  private async broadcast(conversationId: string, shares: LiveShare[]) {
    const members = await this.participants.find({
      where: { conversationId },
      select: ['userId'],
    });
    this.realtime.publishLiveLocation(
      members.map((row) => row.userId),
      { conversationId, shares },
    );
  }

  private async assertMember(userId: string, conversationId: string) {
    const conv = await this.conversations.findOne({ where: { id: conversationId } });
    if (!conv) throw new NotFoundException('Conversation not found');
    if (
      conv.kind !== ConversationKind.Direct &&
      conv.kind !== ConversationKind.Group
    ) {
      throw new BadRequestException('Live location is for chats');
    }
    const mine = await this.participants.findOne({
      where: { conversationId, userId },
    });
    if (!mine) throw new ForbiddenException('Only people in this chat can see this');
  }

  private key(conversationId: string, userId: string) {
    return `${conversationId}:${userId}`;
  }
}
