// Made by Dr Ali — reject stub:// attachment URLs on sendMessage.
import { BadRequestException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { AiAutoReplyService } from '../ai/ai-auto-reply.service';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ModerationService } from '../moderation/moderation.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OrderChatService } from '../orders/order-chat.service';
import { Order } from '../orders/order.entity';
import { User } from '../users/user.entity';
import { AuditLog } from './audit-log.entity';
import { ChatService } from './chat.service';
import { ConversationParticipant } from './conversation-participant.entity';
import { Conversation } from './conversation.entity';
import { Message } from './message.entity';
import { RealtimeService } from '../realtime/realtime.service';

describe('ChatService sendMessage attachment URL', () => {
  let service: ChatService;

  const conversations = {
    findOne: jest.fn(),
    find: jest.fn(),
    update: jest.fn(),
    save: jest.fn(),
    create: jest.fn((r: unknown) => r),
    query: jest.fn(),
  };
  const participants = {
    findOne: jest.fn(),
    find: jest.fn(),
    save: jest.fn(async (r: unknown) => r),
    create: jest.fn((r: unknown) => r),
    update: jest.fn(),
  };
  const messages = {
    findOne: jest.fn(),
    find: jest.fn(),
    save: jest.fn(async (r: unknown) => ({ id: 'm1', ...(r as object) })),
    create: jest.fn((r: unknown) => r),
    createQueryBuilder: jest.fn(),
  };
  const users = { findOne: jest.fn(), find: jest.fn() };
  const auditLogs = {
    save: jest.fn(),
    create: jest.fn((r: unknown) => r),
  };
  const orders = { findOne: jest.fn(), save: jest.fn(async (r: unknown) => r) };
  const moderation = { assertClean: jest.fn() };
  const notifications = { createForUsers: jest.fn() };
  const aiAutoReply = {
    pauseForCustomerHandoff: jest.fn(),
    postConnectingNotice: jest.fn(),
    afterHumanMessage: jest.fn(() => Promise.resolve(null)),
    setAutoReplyEnabled: jest.fn(),
  };
  const orderChat = { syncParticipants: jest.fn() };
  const realtime = {
    publishChatMessage: jest.fn(),
    publishNotification: jest.fn(),
    publishBadgeHint: jest.fn(),
  };

  const actor = new AuthUser('u1', 'sid', UserRole.Customer);

  beforeEach(async () => {
    jest.clearAllMocks();
    participants.findOne.mockResolvedValue({ userId: 'u1', conversationId: 'c1' });
    messages.findOne.mockResolvedValue({
      id: 'm1',
      body: '',
      attachmentKind: 'image',
      attachmentUrl: 'https://example.com/uploads/a.jpg',
      sender: { id: 'u1', name: 'C' },
    });
    participants.find.mockResolvedValue([{ userId: 'u1' }]);

    const module = await Test.createTestingModule({
      providers: [
        ChatService,
        { provide: getRepositoryToken(Conversation), useValue: conversations },
        {
          provide: getRepositoryToken(ConversationParticipant),
          useValue: participants,
        },
        { provide: getRepositoryToken(Message), useValue: messages },
        { provide: getRepositoryToken(User), useValue: users },
        { provide: getRepositoryToken(AuditLog), useValue: auditLogs },
        { provide: getRepositoryToken(Order), useValue: orders },
        { provide: ModerationService, useValue: moderation },
        { provide: NotificationsService, useValue: notifications },
        { provide: AiAutoReplyService, useValue: aiAutoReply },
        { provide: OrderChatService, useValue: orderChat },
        { provide: RealtimeService, useValue: realtime },
      ],
    }).compile();
    service = module.get(ChatService);
  });

  it('rejects stub:// attachmentUrl', async () => {
    await expect(
      service.sendMessage(actor, 'c1', {
        attachmentKind: 'image',
        attachmentName: 'x.jpg',
        attachmentUrl: 'stub://local/x.jpg',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(messages.save).not.toHaveBeenCalled();
  });

  it('requires attachmentUrl for image kind', async () => {
    await expect(
      service.sendMessage(actor, 'c1', {
        attachmentKind: 'image',
        attachmentName: 'x.jpg',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('accepts https upload URL', async () => {
    await service.sendMessage(actor, 'c1', {
      attachmentKind: 'image',
      attachmentName: 'a.jpg',
      attachmentUrl: 'https://example.com/uploads/a.jpg',
    });
    expect(messages.save).toHaveBeenCalled();
  });
});
