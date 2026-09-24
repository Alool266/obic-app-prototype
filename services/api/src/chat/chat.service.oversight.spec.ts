// Made by Dr Ali — SuperAdmin oversight list/join permissions.
import { ForbiddenException } from '@nestjs/common';
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
import { Conversation, ConversationKind } from './conversation.entity';
import { Message } from './message.entity';
import { RealtimeService } from '../realtime/realtime.service';

describe('ChatService oversight join', () => {
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
    save: jest.fn(),
    create: jest.fn((r: unknown) => r),
    createQueryBuilder: jest.fn(),
  };
  const users = {
    findOne: jest.fn(),
    find: jest.fn(),
  };
  const auditLogs = {
    save: jest.fn(),
    create: jest.fn((r: unknown) => r),
  };
  const orders = {
    findOne: jest.fn(),
    save: jest.fn(async (r: unknown) => r),
  };
  const moderation = { assertClean: jest.fn() };
  const notifications = { createForUsers: jest.fn() };
  const aiAutoReply = {
    pauseForCustomerHandoff: jest.fn(),
    postConnectingNotice: jest.fn(),
    afterHumanMessage: jest.fn(),
    setAutoReplyEnabled: jest.fn(),
  };
  const orderChat = { syncParticipants: jest.fn() };
  const realtime = {
    publishChatMessage: jest.fn(),
    publishNotification: jest.fn(),
    publishBadgeHint: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
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

    messages.findOne.mockResolvedValue(null);
    participants.find.mockResolvedValue([]);
  });

  const sa = new AuthUser('sa-1', 'sid', UserRole.SuperAdmin);
  const emp = new AuthUser('emp-1', 'sid', UserRole.Employee);

  it('rejects non-SuperAdmin join', async () => {
    users.findOne.mockResolvedValue({
      id: 'emp-1',
      role: UserRole.Employee,
    });
    await expect(service.adminJoinThread(emp, 'c1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('refuses join on friend DM (direct, no staff)', async () => {
    users.findOne.mockResolvedValue({
      id: 'sa-1',
      role: UserRole.SuperAdmin,
      name: 'Admin',
    });
    conversations.findOne.mockResolvedValue({
      id: 'c-friend',
      kind: ConversationKind.Direct,
      title: null,
      orderId: null,
      aiAutoReplyEnabled: true,
      updatedAt: new Date(),
    });
    await expect(
      service.adminJoinThread(sa, 'c-friend'),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(participants.save).not.toHaveBeenCalled();
  });

  it('joins support thread and audits', async () => {
    users.findOne
      .mockResolvedValueOnce({
        id: 'sa-1',
        role: UserRole.SuperAdmin,
        name: 'Admin',
      })
      .mockResolvedValueOnce({
        id: 'sa-1',
        role: UserRole.SuperAdmin,
        name: 'Admin',
      });
    const convId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    conversations.findOne.mockResolvedValue({
      id: convId,
      kind: ConversationKind.Support,
      title: null,
      orderId: null,
      aiAutoReplyEnabled: true,
      updatedAt: new Date(),
    });
    participants.findOne.mockResolvedValue(null); // not yet member
    participants.find.mockResolvedValue([
      {
        userId: 'cust-1',
        conversationId: convId,
        user: { id: 'cust-1', name: 'Cust', role: UserRole.Customer },
      },
      {
        userId: 'sa-1',
        conversationId: convId,
        user: { id: 'sa-1', name: 'Admin', role: UserRole.SuperAdmin },
      },
    ]);
    messages.findOne.mockResolvedValue(null);

    const res = await service.adminJoinThread(sa, convId);
    expect(res.joined).toBe(true);
    expect(res.alreadyMember).toBe(false);
    expect(participants.save).toHaveBeenCalled();
    expect(auditLogs.save).toHaveBeenCalled();
    expect(notifications.createForUsers).toHaveBeenCalled();
  });

  it('friend DM transcript is readable (audited) without join', async () => {
    users.findOne.mockResolvedValue({
      id: 'sa-1',
      role: UserRole.SuperAdmin,
    });
    conversations.findOne.mockResolvedValue({
      id: 'c-friend',
      kind: ConversationKind.Direct,
      title: null,
      orderId: null,
      aiAutoReplyEnabled: true,
    });
    participants.find.mockResolvedValue([
      {
        userId: 'c1',
        user: { id: 'c1', name: 'A', role: UserRole.Customer },
      },
      {
        userId: 'c2',
        user: { id: 'c2', name: 'B', role: UserRole.Customer },
      },
    ]);
    messages.find.mockResolvedValue([]);

    const res = await service.adminReadTranscript(sa, 'c-friend');
    expect(res.friendDm).toBe(true);
    expect(res.joinable).toBe(false);
    expect(res.audit).toBe('logged');
  });
});
