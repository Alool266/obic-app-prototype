// Made by Dr Ali
// Auto-reply for support/order customer messages — staff can override per thread.

import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { Repository } from 'typeorm';
import {
  Conversation,
  ConversationKind,
} from '../chat/conversation.entity';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { AttachmentKind, Message } from '../chat/message.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { NotificationKind } from '../notifications/notification.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { Order } from '../orders/order.entity';
import { RealtimeService } from '../realtime/realtime.service';
import { User } from '../users/user.entity';
import { shouldAutoRequestStaff } from './ai-handoff-intent';
import { AiConfig } from './ai.config';
import { AiService } from './ai.service';
import { AiSettingsService } from './ai-settings.service';
import {
  AiLocale,
  OBIC_AI_DISPLAY_NAME,
  OBIC_AI_EMAIL,
  OBIC_AI_USER_ID,
  resolveReplyLocale,
} from './obic-ai.constants';

export type AutoReplyResult = {
  /** Caller should open support handoff form (client) or soft-request order assignee. */
  autoHandoff: boolean;
};

@Injectable()
export class AiAutoReplyService {
  private readonly logger = new Logger(AiAutoReplyService.name);
  /** One auto-reply in flight per customer message id (dedupe double-submit). */
  private readonly replyInflight = new Set<string>();

  constructor(
    private readonly cfg: AiConfig,
    private readonly ai: AiService,
    private readonly aiSettings: AiSettingsService,
    @InjectRepository(Conversation)
    private readonly conversations: Repository<Conversation>,
    @InjectRepository(ConversationParticipant)
    private readonly participants: Repository<ConversationParticipant>,
    @InjectRepository(Message)
    private readonly messages: Repository<Message>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    private readonly notifications: NotificationsService,
    private readonly realtime: RealtimeService,
  ) {}

  /**
   * After a human message is saved. Fire-and-forget from ChatService.
   * Never mutates order status (Form2 ACL stays on customer/assignee only).
   */
  async afterHumanMessage(opts: {
    actor: AuthUser;
    conversationId: string;
    customerMessageBody: string;
    customerMessageId: string;
    /** Optional app locale from chat client (ar | en | zh) — fallback only. */
    clientLocale?: string | null;
  }): Promise<AutoReplyResult> {
    if (!this.cfg.autoReplyEnabled) {
      return { autoHandoff: false };
    }
    if (!(await this.aiSettings.isGlobalAutoReplyEnabled())) {
      return { autoHandoff: false };
    }

    const lockKey = opts.customerMessageId;
    if (this.replyInflight.has(lockKey)) {
      return { autoHandoff: false };
    }
    this.replyInflight.add(lockKey);

    try {
      return await this.runAutoReply(opts);
    } finally {
      this.replyInflight.delete(lockKey);
    }
  }

  private async runAutoReply(opts: {
    actor: AuthUser;
    conversationId: string;
    customerMessageBody: string;
    customerMessageId: string;
    clientLocale?: string | null;
  }): Promise<AutoReplyResult> {
    const noHandoff = { autoHandoff: false as const };
    const conv = await this.conversations.findOne({
      where: { id: opts.conversationId },
    });
    if (!conv) return noHandoff;
    if (
      conv.kind !== ConversationKind.Support &&
      conv.kind !== ConversationKind.Order
    ) {
      return noHandoff;
    }

    const actorUser = await this.users.findOne({
      where: { id: opts.actor.userId },
      select: ['id', 'role'],
    });
    if (!actorUser) return noHandoff;

    // Staff takeover: pause auto-reply on this thread until re-enabled.
    if (
      actorUser.role === UserRole.Employee ||
      actorUser.role === UserRole.SuperAdmin
    ) {
      if (opts.actor.userId === OBIC_AI_USER_ID) return noHandoff;
      if (conv.aiAutoReplyEnabled) {
        conv.aiAutoReplyEnabled = false;
        await this.conversations.save(conv);
        this.logger.log(
          `ai_auto_reply_paused conversation=${opts.conversationId}`,
        );
      }
      return noHandoff;
    }

    if (actorUser.role !== UserRole.Customer) return noHandoff;
    if (!conv.aiAutoReplyEnabled) return noHandoff;

    const body = (opts.customerMessageBody ?? '').trim();
    if (!body) return noHandoff;

    const autoHandoff = shouldAutoRequestStaff(body);

    const customerMsg = await this.messages.findOne({
      where: { id: opts.customerMessageId },
      select: ['id', 'createdAt'],
    });
    if (!customerMsg) return { autoHandoff };

    // Already replied after this customer message (retried hook / double fire).
    const priorAi = await this.messages
      .createQueryBuilder('m')
      .where('m.conversation_id = :cid', { cid: opts.conversationId })
      .andWhere('m.is_ai = true')
      .andWhere('m.created_at > :after', { after: customerMsg.createdAt })
      .getCount();
    if (priorAi > 0) return { autoHandoff };

    try {
      // Script in message wins; else client app locale; never force English over AR/ZH.
      const locale = resolveReplyLocale(body, opts.clientLocale);
      const extra = await this.orderContext(conv);
      const reply = await this.ai.complete({
        userId: opts.actor.userId,
        locale,
        userMessage: body,
        purpose: 'auto_reply',
        extraContext: extra,
      });
      await this.postAiMessage(conv, reply);
    } catch (err) {
      // Soft-fail: customer message already delivered; never leak provider errors.
      this.logger.warn(
        `ai_auto_reply_skip conversation=${opts.conversationId} reason=provider_or_limit`,
      );
      void err;
    }

    if (autoHandoff) {
      this.logger.log(
        `ai_auto_handoff_intent conversation=${opts.conversationId}`,
      );
    }
    return { autoHandoff };
  }

  async setAutoReplyEnabled(
    actor: AuthUser,
    conversationId: string,
    enabled: boolean,
  ) {
    const actorUser = await this.users.findOne({
      where: { id: actor.userId },
      select: ['id', 'role'],
    });
    if (
      !actorUser ||
      (actorUser.role !== UserRole.Employee &&
        actorUser.role !== UserRole.SuperAdmin)
    ) {
      return { ok: false as const, error: 'staff_only' };
    }

    const conv = await this.conversations.findOne({
      where: { id: conversationId },
    });
    if (!conv) return { ok: false as const, error: 'not_found' };

    if (actorUser.role !== UserRole.SuperAdmin) {
      const part = await this.participants.findOne({
        where: { conversationId, userId: actor.userId },
      });
      if (!part) return { ok: false as const, error: 'not_found' };
    }

    conv.aiAutoReplyEnabled = enabled;
    await this.conversations.save(conv);
    this.logger.log(
      `ai_auto_reply_set conversation=${conversationId} enabled=${enabled}`,
    );
    return {
      ok: true as const,
      conversationId,
      aiAutoReplyEnabled: conv.aiAutoReplyEnabled,
    };
  }

  /**
   * Customer “Talk to staff” — pause auto-reply without staff JWT.
   * Caller must already authorize the customer on this thread.
   */
  async pauseForCustomerHandoff(conversationId: string) {
    const conv = await this.conversations.findOne({
      where: { id: conversationId },
    });
    if (!conv) return { ok: false as const, error: 'not_found' };

    const wasEnabled = conv.aiAutoReplyEnabled ?? true;
    if (wasEnabled) {
      conv.aiAutoReplyEnabled = false;
      await this.conversations.save(conv);
      this.logger.log(
        `ai_auto_reply_paused_handoff conversation=${conversationId}`,
      );
    }
    return {
      ok: true as const,
      conversationId,
      aiAutoReplyEnabled: false,
      newlyPaused: wasEnabled,
    };
  }

  /** Short in-thread notice after customer requests staff. */
  async postConnectingNotice(
    conversationId: string,
    locale: AiLocale = 'en',
  ) {
    const body =
      locale === 'ar'
        ? 'جارٍ توصيلك بفريق الدعم…'
        : locale === 'zh'
          ? '正在为您接通人工客服…'
          : 'Connecting you with staff…';
    const conv = await this.conversations.findOne({
      where: { id: conversationId },
    });
    if (!conv) return null;
    return this.postAiMessage(conv, body);
  }

  private async postAiMessage(conv: Conversation, body: string) {
    const bot = await this.ensureBotUser();
    await this.ensureParticipant(conv.id, bot.id);

    const saved = await this.messages.save(
      this.messages.create({
        conversationId: conv.id,
        senderId: bot.id,
        body,
        attachmentKind: AttachmentKind.None,
        isAi: true,
      }),
    );
    await this.conversations.update(conv.id, { updatedAt: new Date() });

    const withSender = await this.messages.findOne({
      where: { id: saved.id },
      relations: { sender: true },
    });
    const peers = await this.participants.find({
      where: { conversationId: conv.id },
      select: ['userId'],
    });
    this.realtime.publishChatMessage({
      userIds: peers.map((p) => p.userId),
      conversationId: conv.id,
      message: {
        id: (withSender ?? saved).id,
        conversationId: conv.id,
        senderId: bot.id,
        senderName: withSender?.sender?.name ?? OBIC_AI_DISPLAY_NAME,
        senderAvatarUrl: withSender?.sender?.avatarUrl ?? null,
        body: saved.body,
        attachmentKind: AttachmentKind.None,
        attachmentName: null,
        attachmentUrl: null,
        isAi: true,
        createdAt: saved.createdAt,
      },
    });

    // Notify customer on support/order threads (tap → open that chat).
    if (
      conv.kind === ConversationKind.Order ||
      conv.kind === ConversationKind.Support
    ) {
      let customerUserId: string | null = null;
      if (conv.kind === ConversationKind.Order && conv.orderId) {
        const order = await this.orders.findOne({
          where: { id: conv.orderId },
        });
        customerUserId = order?.userId ?? null;
      } else {
        const parts = await this.participants.find({
          where: { conversationId: conv.id },
        });
        for (const p of parts) {
          if (p.userId === bot.id) continue;
          const u = await this.users.findOne({
            where: { id: p.userId },
            select: ['id', 'role'],
          });
          if (u?.role === UserRole.Customer) {
            customerUserId = u.id;
            break;
          }
        }
      }
      if (customerUserId) {
        await this.notifications.createForUsers({
          userIds: [customerUserId],
          kind: NotificationKind.Message,
          title: 'OBIC AI reply',
          body: 'You have a new message',
          data: {
            type:
              conv.kind === ConversationKind.Order
                ? 'order_chat'
                : 'support_chat',
            orderId: conv.orderId ?? null,
            conversationId: conv.id,
            isAi: true,
          },
        });
      }
    }

    return saved;
  }

  private async ensureBotUser(): Promise<User> {
    const existing = await this.users.findOne({
      where: { id: OBIC_AI_USER_ID },
    });
    if (existing) return existing;

    const byEmail = await this.users.findOne({
      where: { email: OBIC_AI_EMAIL },
    });
    if (byEmail) return byEmail;

    const passwordHash = await bcrypt.hash(
      `obic-ai-no-login-${Date.now()}`,
      10,
    );
    // Explicit id — bot identity must be stable across environments.
    await this.users.query(
      `
      INSERT INTO users (
        id, email, phone, password_hash, role, name,
        staff_title, branch_label, ops_access, offers_access, addresses
      ) VALUES (
        $1, $2, NULL, $3, 'Employee', $4,
        'AI Assistant', NULL, false, false, '[]'::jsonb
      )
      ON CONFLICT (id) DO NOTHING
      `,
      [OBIC_AI_USER_ID, OBIC_AI_EMAIL, passwordHash, OBIC_AI_DISPLAY_NAME],
    );
    const bot = await this.users.findOne({ where: { id: OBIC_AI_USER_ID } });
    if (!bot) {
      throw new Error('Failed to ensure OBIC AI bot user');
    }
    return bot;
  }

  private async ensureParticipant(conversationId: string, userId: string) {
    const existing = await this.participants.findOne({
      where: { conversationId, userId },
    });
    if (existing) return;
    await this.participants.save(
      this.participants.create({ conversationId, userId }),
    );
  }

  private async orderContext(conv: Conversation): Promise<string | undefined> {
    if (conv.kind !== ConversationKind.Order || !conv.orderId) return undefined;
    const order = await this.orders.findOne({
      where: { id: conv.orderId },
      relations: { service: true },
    });
    if (!order) return undefined;
    // Status + service slug only — no customer name/phone/email.
    return [
      `Order status: ${order.status}`,
      order.service?.slug ? `Service: ${order.service.slug}` : null,
      'Do not claim the order was paid or completed unless status says so.',
    ]
      .filter(Boolean)
      .join('\n');
  }
}
