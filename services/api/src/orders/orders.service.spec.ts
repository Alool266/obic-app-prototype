// Made by Dr Ali
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { Conversation } from '../chat/conversation.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { NotificationsService } from '../notifications/notifications.service';
import { OffersService } from '../offers/offers.service';
import { ServicesService } from '../services/services.service';
import { User } from '../users/user.entity';
import { OrderChatService } from './order-chat.service';
import { Order, OrderStatus } from './order.entity';
import { OrdersService } from './orders.service';

describe('OrdersService.create with offerId', () => {
  let service: OrdersService;
  const ordersRepo = {
    create: jest.fn((row: unknown) => row),
    save: jest.fn(async (row: Record<string, unknown>) => ({
      ...row,
      id: 'order-1',
      createdAt: new Date(),
      updatedAt: new Date(),
      status: OrderStatus.Submitted,
    })),
    find: jest.fn(async () => []),
  };
  const usersRepo = {
    find: jest.fn(async () => []),
    findOne: jest.fn(async () => null),
  };
  const conversationsRepo = { find: jest.fn(async () => []) };
  const participantsRepo = {
    find: jest.fn(async () => []),
  };
  const auditLogsRepo = {
    findOne: jest.fn(async () => null),
  };
  const servicesService = {
    requireActiveId: jest.fn(),
  };
  const offersService = {
    requireAvailableForOrder: jest.fn(),
  };
  const notifications = { createForUsers: jest.fn() };
  const orderChat = {
    ensureForOrder: jest.fn(async () => 'conv-1'),
    postStatusNote: jest.fn(),
    syncParticipants: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        OrdersService,
        { provide: getRepositoryToken(Order), useValue: ordersRepo },
        { provide: getRepositoryToken(User), useValue: usersRepo },
        {
          provide: getRepositoryToken(Conversation),
          useValue: conversationsRepo,
        },
        {
          provide: getRepositoryToken(ConversationParticipant),
          useValue: participantsRepo,
        },
        { provide: getRepositoryToken(AuditLog), useValue: auditLogsRepo },
        { provide: ServicesService, useValue: servicesService },
        { provide: OffersService, useValue: offersService },
        { provide: NotificationsService, useValue: notifications },
        { provide: OrderChatService, useValue: orderChat },
      ],
    }).compile();
    service = module.get(OrdersService);
  });

  it('stores offerId on the order when requesting an available offer', async () => {
    const offerId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    const serviceId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    servicesService.requireActiveId.mockResolvedValue({
      id: serviceId,
      slug: 'hotels',
    });
    offersService.requireAvailableForOrder.mockResolvedValue({
      id: offerId,
      kind: 'hotels',
      titleEn: 'Canton Hotel',
      titleAr: 'فندق',
    });

    const actor = new AuthUser('cust-1', 'sid', UserRole.Customer);
    const dto = await service.create(actor, {
      serviceId,
      offerId,
      notes: 'please book',
    });

    expect(offersService.requireAvailableForOrder).toHaveBeenCalledWith(offerId);
    expect(ordersRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'cust-1',
        serviceId,
        offerId,
      }),
    );
    expect(dto.offerId).toBe(offerId);
  });

  it('notifies SuperAdmin and offers-access employees, not the customer', async () => {
    const offerId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    const serviceId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    servicesService.requireActiveId.mockResolvedValue({
      id: serviceId,
      slug: 'hotels',
    });
    offersService.requireAvailableForOrder.mockResolvedValue({
      id: offerId,
      kind: 'hotels',
      titleEn: 'Canton Hotel',
      titleAr: 'فندق',
    });
    usersRepo.find.mockResolvedValue([
      { id: 'sa-1', role: UserRole.SuperAdmin, offersAccess: false },
      { id: 'emp-offers', role: UserRole.Employee, offersAccess: true },
      { id: 'emp-plain', role: UserRole.Employee, offersAccess: false },
      { id: 'cust-1', role: UserRole.Customer, offersAccess: false },
    ]);

    const actor = new AuthUser('cust-1', 'sid', UserRole.Customer);
    await service.create(actor, { serviceId, offerId });

    expect(notifications.createForUsers).toHaveBeenCalled();
    const offerCall = notifications.createForUsers.mock.calls.find((c) => {
      const data = (c[0] as { data?: { type?: string } }).data;
      return data?.type === 'offer_request';
    })?.[0] as { userIds: string[]; kind: string; data: { orderId: string } };
    expect(offerCall).toBeTruthy();
    expect(offerCall.userIds.sort()).toEqual(['emp-offers', 'sa-1']);
    expect(offerCall.kind).toBe('order_created');
    expect(offerCall.data.orderId).toBe('order-1');
  });

  it('listMine merges support threads with service orders', async () => {
    const updated = new Date('2026-09-26T12:00:00Z');
    ordersRepo.find.mockResolvedValue([
      {
        id: 'order-1',
        serviceId: 'svc-1',
        status: OrderStatus.Submitted,
        preferredBranch: 'Yiwu',
        subServiceId: null,
        subServiceNameEn: null,
        subServiceNameAr: null,
        formData: null,
        offerId: null,
        notes: null,
        assignedEmployeeId: null,
        createdAt: new Date('2026-09-25T10:00:00Z'),
        updatedAt: new Date('2026-09-25T10:00:00Z'),
        service: { slug: 'visa', nameEn: 'Visa' },
      },
    ]);
    participantsRepo.find
      .mockResolvedValueOnce([
        {
          userId: 'cust-1',
          conversation: {
            id: 'sup-1',
            kind: 'support',
            title: null,
            aiAutoReplyEnabled: false,
            createdAt: new Date('2026-09-26T11:00:00Z'),
            updatedAt: updated,
          },
        },
      ])
      .mockResolvedValueOnce([
        {
          userId: 'cust-1',
          user: { role: UserRole.Customer },
        },
        {
          userId: 'emp-1',
          user: { role: UserRole.Employee },
        },
      ]);
    auditLogsRepo.findOne.mockResolvedValue({
      meta: { branch: 'Yiwu', serviceKey: 'visa', desk: 'secretary' },
    });

    const actor = new AuthUser('cust-1', 'sid', UserRole.Customer);
    const list = await service.listMine(actor);

    expect(list).toHaveLength(2);
    expect(list[0]).toEqual(
      expect.objectContaining({
        type: 'support',
        id: 'sup-1',
        conversationId: 'sup-1',
        status: 'WithAgent',
        preferredBranch: 'Yiwu',
        serviceSlug: 'support',
      }),
    );
    expect(list[1]).toEqual(
      expect.objectContaining({
        type: 'order',
        id: 'order-1',
        serviceSlug: 'visa',
      }),
    );
  });
});
