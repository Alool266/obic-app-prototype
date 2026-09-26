// Made by Dr Ali — requestStaff: pause AI + route order vs support.
import { ForbiddenException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { AiAutoReplyService } from '../ai/ai-auto-reply.service';
import { OBIC_AI_USER_ID } from '../ai/obic-ai.constants';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ModerationService } from '../moderation/moderation.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OrderChatService } from '../orders/order-chat.service';
import { Order, OrderStatus } from '../orders/order.entity';
import { User } from '../users/user.entity';
import { AuditLog } from './audit-log.entity';
import { ChatService } from './chat.service';
import { ConversationParticipant } from './conversation-participant.entity';
import { Conversation, ConversationKind } from './conversation.entity';
import { Message } from './message.entity';
import { RealtimeService } from '../realtime/realtime.service';

describe('ChatService.requestStaff', () => {
  let service: ChatService;

  const conversations = {
    findOne: jest.fn(),
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
    find: jest.fn().mockResolvedValue([]),
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
  const orderChat = {
    syncParticipants: jest.fn(),
  };
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

    // Default getThreadSummary deps
    messages.findOne.mockResolvedValue(null);
    participants.find.mockResolvedValue([]);
  });

  it('rejects non-customers', async () => {
    users.findOne.mockResolvedValue({
      id: 'emp-1',
      role: UserRole.Employee,
      name: 'Staff',
    });
    const actor = new AuthUser('emp-1', 'sid', UserRole.Employee);
    await expect(service.requestStaff(actor, 'c1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('support: pauses AI, adds secretary desk, notifies, posts connecting', async () => {
    const convId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    const customerId = 'cust-1';
    const deskId = 'desk-sec';

    users.findOne
      .mockResolvedValueOnce({
        id: customerId,
        role: UserRole.Customer,
        name: 'Ali',
      }) // me
      .mockResolvedValueOnce({
        id: deskId,
        role: UserRole.Employee,
        email: 'temp.yiwu.secretary@obic.local',
      }); // support desk email lookup

    participants.findOne
      .mockResolvedValueOnce({ conversationId: convId, userId: customerId }) // requireParticipant
      .mockResolvedValueOnce(null); // ensureParticipant — not yet member

    conversations.findOne
      .mockResolvedValueOnce({
        id: convId,
        kind: ConversationKind.Support,
        orderId: null,
        aiAutoReplyEnabled: true,
        title: null,
        updatedAt: new Date(),
      })
      .mockResolvedValueOnce({
        id: convId,
        kind: ConversationKind.Support,
        orderId: null,
        aiAutoReplyEnabled: false,
        title: null,
        updatedAt: new Date(),
      }); // getThreadSummary

    aiAutoReply.pauseForCustomerHandoff.mockResolvedValue({
      ok: true,
      conversationId: convId,
      aiAutoReplyEnabled: false,
      newlyPaused: true,
    });
    aiAutoReply.postConnectingNotice.mockResolvedValue({ id: 'msg-1' });

    const actor = new AuthUser(customerId, 'sid', UserRole.Customer);
    const result = await service.requestStaff(actor, convId, {
      branch: 'Yiwu',
      serviceKey: 'visa',
    });

    expect(aiAutoReply.pauseForCustomerHandoff).toHaveBeenCalledWith(convId);
    expect(participants.save).toHaveBeenCalled();
    expect(notifications.createForUsers).toHaveBeenCalledWith(
      expect.objectContaining({
        userIds: [deskId],
        data: expect.objectContaining({
          type: 'staff_handoff',
          kind: 'support',
          branch: 'Yiwu',
          desk: 'secretary',
          serviceKey: 'visa',
        }),
      }),
    );
    expect(aiAutoReply.postConnectingNotice).toHaveBeenCalled();
    expect(result.aiAutoReplyEnabled).toBe(false);
    expect(result.staffMemberIds).toEqual([deskId]);
    expect(result.addedMemberIds).toEqual([deskId]);
    expect(result.branch).toBe('Yiwu');
    expect(result.desk).toBe('secretary');
    expect(auditLogs.save).toHaveBeenCalled();
  });

  it('support: routes Guangzhou + business → branchmgr desk', async () => {
    const convId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
    const customerId = 'cust-2';
    const deskId = 'desk-bm';

    users.findOne
      .mockResolvedValueOnce({
        id: customerId,
        role: UserRole.Customer,
        name: 'Ali',
      })
      .mockResolvedValueOnce({
        id: deskId,
        role: UserRole.Employee,
        email: 'temp.guangzhou.branchmgr@obic.local',
      });

    participants.findOne
      .mockResolvedValueOnce({ conversationId: convId, userId: customerId })
      .mockResolvedValueOnce(null);

    conversations.findOne
      .mockResolvedValueOnce({
        id: convId,
        kind: ConversationKind.Support,
        orderId: null,
        aiAutoReplyEnabled: true,
        title: null,
        updatedAt: new Date(),
      })
      .mockResolvedValueOnce({
        id: convId,
        kind: ConversationKind.Support,
        orderId: null,
        aiAutoReplyEnabled: false,
        title: null,
        updatedAt: new Date(),
      });

    aiAutoReply.pauseForCustomerHandoff.mockResolvedValue({
      ok: true,
      conversationId: convId,
      aiAutoReplyEnabled: false,
      newlyPaused: true,
    });
    aiAutoReply.postConnectingNotice.mockResolvedValue({ id: 'msg-1' });

    const actor = new AuthUser(customerId, 'sid', UserRole.Customer);
    const result = await service.requestStaff(actor, convId, {
      branch: 'Guangzhou',
      serviceKey: 'business',
      orderRef: '1790244575128',
      note: 'visa follow-up',
    });

    expect(users.findOne).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          email: 'temp.guangzhou.branchmgr@obic.local',
        }),
      }),
    );
    expect(notifications.createForUsers).toHaveBeenCalledWith(
      expect.objectContaining({
        body: expect.stringContaining('1790244575128'),
        data: expect.objectContaining({
          branch: 'Guangzhou',
          desk: 'branchmgr',
          orderRef: '1790244575128',
          note: 'visa follow-up',
        }),
      }),
    );
    expect(result.desk).toBe('branchmgr');
    expect(result.staffMemberIds).toEqual([deskId]);
  });

  it('support: rejects missing branch/serviceKey', async () => {
    const convId = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
    const customerId = 'cust-3';
    users.findOne.mockResolvedValue({
      id: customerId,
      role: UserRole.Customer,
      name: 'Ali',
    });
    participants.findOne.mockResolvedValue({
      conversationId: convId,
      userId: customerId,
    });
    conversations.findOne.mockResolvedValue({
      id: convId,
      kind: ConversationKind.Support,
      orderId: null,
      aiAutoReplyEnabled: true,
    });
    const actor = new AuthUser(customerId, 'sid', UserRole.Customer);
    await expect(service.requestStaff(actor, convId, {})).rejects.toThrow(
      /branch is required/,
    );
    await expect(
      service.requestStaff(actor, convId, { branch: 'Yiwu' }),
    ).rejects.toThrow(/serviceKey/);
  });

  it('order: ensures assignee member + notifies (no re-resolve when assigned)', async () => {
    const convId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    const customerId = 'cust-1';
    const assigneeId = 'emp-assignee';
    const orderId = 'order-1';

    users.findOne.mockResolvedValue({
      id: customerId,
      role: UserRole.Customer,
      name: 'Ali',
    });

    participants.findOne
      .mockResolvedValueOnce({ conversationId: convId, userId: customerId })
      .mockResolvedValueOnce({ conversationId: convId, userId: assigneeId }); // already member

    const order = {
      id: orderId,
      userId: customerId,
      assignedEmployeeId: assigneeId,
      preferredBranch: 'Yiwu',
      status: OrderStatus.Assigned,
      service: { slug: 'visa' },
    };
    orders.findOne.mockResolvedValue(order);

    conversations.findOne
      .mockResolvedValueOnce({
        id: convId,
        kind: ConversationKind.Order,
        orderId,
        aiAutoReplyEnabled: true,
        title: 'Order X',
        updatedAt: new Date(),
      })
      .mockResolvedValueOnce({
        id: convId,
        kind: ConversationKind.Order,
        orderId,
        aiAutoReplyEnabled: false,
        title: 'Order X',
        updatedAt: new Date(),
      });

    aiAutoReply.pauseForCustomerHandoff.mockResolvedValue({
      ok: true,
      conversationId: convId,
      aiAutoReplyEnabled: false,
      newlyPaused: true,
    });
    aiAutoReply.postConnectingNotice.mockResolvedValue({ id: 'msg-1' });

    const actor = new AuthUser(customerId, 'sid', UserRole.Customer);
    const result = await service.requestStaff(actor, convId);

    expect(orderChat.syncParticipants).toHaveBeenCalledWith(convId, order);
    expect(result.staffMemberIds).toEqual([assigneeId]);
    expect(result.addedMemberIds).toEqual([]);
    expect(notifications.createForUsers).toHaveBeenCalledWith(
      expect.objectContaining({
        userIds: [assigneeId],
        data: expect.objectContaining({
          type: 'staff_handoff',
          kind: 'order',
          orderId,
        }),
      }),
    );
    expect(OBIC_AI_USER_ID).toBeTruthy();
  });
});
