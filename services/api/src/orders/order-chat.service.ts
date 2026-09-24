// Made by Dr Ali
// Order-linked CRM chat — one thread per order; customer + assignee.

import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import {
  Conversation,
  ConversationKind,
} from '../chat/conversation.entity';
import { Message } from '../chat/message.entity';
import { statusNoteBody } from './order-status-note';
import { Order, OrderStatus } from './order.entity';
import { RealtimeService } from '../realtime/realtime.service';

@Injectable()
export class OrderChatService {
  constructor(
    @InjectRepository(Conversation)
    private readonly conversations: Repository<Conversation>,
    @InjectRepository(ConversationParticipant)
    private readonly participants: Repository<ConversationParticipant>,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(Message)
    private readonly messages: Repository<Message>,
    private readonly realtime: RealtimeService,
  ) {}

  /** Create or return the CRM thread for an order (after order save). */
  async ensureForOrder(order: Order): Promise<string> {
    const existing = await this.conversations.findOne({
      where: { orderId: order.id },
    });
    if (existing) {
      await this.syncParticipants(existing.id, order);
      return existing.id;
    }

    const shortId = order.id.slice(0, 8).toUpperCase();
    const conv = await this.conversations.save(
      this.conversations.create({
        kind: ConversationKind.Order,
        orderId: order.id,
        title: `Order ${shortId}`,
      }),
    );
    await this.syncParticipants(conv.id, order);
    return conv.id;
  }

  async syncParticipants(conversationId: string, order: Order): Promise<void> {
    const memberIds = new Set<string>([order.userId]);
    if (order.assignedEmployeeId) {
      memberIds.add(order.assignedEmployeeId);
    }

    const existing = await this.participants.find({
      where: { conversationId },
      relations: { user: true },
    });
    for (const row of existing) {
      if (memberIds.has(row.userId)) continue;
      if (row.user?.role === UserRole.SuperAdmin) continue;
      await this.participants.delete(row.id);
    }

    for (const userId of memberIds) {
      const exists = existing.some((row) => row.userId === userId);
      if (!exists) {
        await this.participants.save(
          this.participants.create({ conversationId, userId }),
        );
      }
    }
  }

  /** Visible status line in the order thread. Sender is the staff (or customer) who caused it. */
  async postStatusNote(
    conversationId: string,
    actorUserId: string,
    status: OrderStatus,
  ): Promise<void> {
    const saved = await this.messages.save(
      this.messages.create({
        conversationId,
        senderId: actorUserId,
        body: statusNoteBody(status),
      }),
    );
    await this.conversations.update(conversationId, { updatedAt: new Date() });
    const withSender = await this.messages.findOne({
      where: { id: saved.id },
      relations: { sender: true },
    });
    const peers = await this.participants.find({
      where: { conversationId },
      select: ['userId'],
    });
    this.realtime.publishChatMessage({
      userIds: peers.map((p) => p.userId),
      conversationId,
      message: {
        id: saved.id,
        conversationId,
        senderId: actorUserId,
        senderName: withSender?.sender?.name ?? null,
        senderAvatarUrl: withSender?.sender?.avatarUrl ?? null,
        body: saved.body,
        attachmentKind: saved.attachmentKind,
        attachmentName: saved.attachmentName,
        attachmentUrl: saved.attachmentUrl,
        isAi: false,
        createdAt: saved.createdAt,
      },
    });
  }

  async conversationIdForOrder(orderId: string): Promise<string | null> {
    const conv = await this.conversations.findOne({ where: { orderId } });
    return conv?.id ?? null;
  }

  async conversationIdsForOrders(
    orderIds: string[],
  ): Promise<Map<string, string>> {
    if (!orderIds.length) return new Map();
    const rows = await this.conversations.find({
      where: { orderId: In(orderIds) },
    });
    const map = new Map<string, string>();
    for (const row of rows) {
      if (row.orderId) map.set(row.orderId, row.id);
    }
    return map;
  }

  async openForActor(actor: AuthUser, orderId: string) {
    const order = await this.orders.findOne({
      where: { id: orderId },
      relations: { service: true },
    });
    if (!order) throw new NotFoundException('Order not found');

    const isCustomer = order.userId === actor.userId;
    const isAssignee = order.assignedEmployeeId === actor.userId;
    const isStaff =
      actor.role === UserRole.Employee || actor.role === UserRole.SuperAdmin;

    if (!isCustomer && !(isStaff && (isAssignee || actor.role === UserRole.SuperAdmin))) {
      throw new ForbiddenException('Not allowed on this order');
    }

    const conversationId = await this.ensureForOrder(order);
    if (actor.role === UserRole.SuperAdmin) {
      const already = await this.participants.findOne({
        where: { conversationId, userId: actor.userId },
      });
      if (!already) {
        await this.participants.save(
          this.participants.create({
            conversationId,
            userId: actor.userId,
          }),
        );
      }
    }
    const conv = await this.conversations.findOne({
      where: { id: conversationId },
    });

    return {
      conversationId,
      orderId: order.id,
      orderStatus: order.status,
      title: conv?.title ?? null,
      serviceSlug: order.service?.slug ?? null,
    };
  }
}
