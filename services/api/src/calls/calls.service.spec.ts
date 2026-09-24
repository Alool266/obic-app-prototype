// Made by Dr Ali
import { ForbiddenException, ServiceUnavailableException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { Conversation } from '../chat/conversation.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { RealtimeService } from '../realtime/realtime.service';
import { User } from '../users/user.entity';
import { CallsConfig } from './calls.config';
import { CallsService } from './calls.service';

describe('CallsService ACL', () => {
  const convId = '11111111-1111-1111-1111-111111111111';
  const memberId = '22222222-2222-2222-2222-222222222222';
  const strangerId = '33333333-3333-3333-3333-333333333333';
  const memberB = '55555555-5555-5555-5555-555555555555';
  const memberC = '66666666-6666-6666-6666-666666666666';
  const superAdminId = '77777777-7777-7777-7777-777777777777';

  const conversations = {
    findOne: jest.fn(),
  };
  const participants = {
    findOne: jest.fn(),
    find: jest.fn(),
  };
  const users = {
    findOne: jest.fn(),
  };
  const realtime = {
    publishCallIncoming: jest.fn(),
    publishCallEnded: jest.fn(),
  };
  const config = {
    configured: true,
    // Hex-shaped placeholders (not real secrets) — agora-token rejects junk.
    appId: '970CA35de60c44645bbae8a215061b33',
    appCertificate: '5Cfd2fd1755d40ecb72977518be15d3b',
    tokenTtlSeconds: 3600,
  };

  let service: CallsService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        CallsService,
        { provide: CallsConfig, useValue: config },
        { provide: RealtimeService, useValue: realtime },
        { provide: getRepositoryToken(Conversation), useValue: conversations },
        {
          provide: getRepositoryToken(ConversationParticipant),
          useValue: participants,
        },
        { provide: getRepositoryToken(User), useValue: users },
      ],
    }).compile();
    service = module.get(CallsService);
  });

  it('createCall: non-member gets 403', async () => {
    conversations.findOne.mockResolvedValue({
      id: convId,
      kind: 'direct',
      title: null,
    });
    participants.findOne.mockResolvedValue(null);

    await expect(
      service.createCall(
        { userId: strangerId, role: UserRole.Customer },
        { conversationId: convId, mode: 'voice' },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(realtime.publishCallIncoming).not.toHaveBeenCalled();
  });

  it('mintToken: non-member gets 403', async () => {
    const callId = '44444444-4444-4444-4444-444444444444';
    service.putSessionForTests({
      id: callId,
      conversationId: convId,
      channelName: 'obic_testchannel',
      mode: 'voice',
      createdBy: memberId,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 60_000),
      ended: false,
      conversationKind: 'direct',
      conversationTitle: null,
    });
    conversations.findOne.mockResolvedValue({
      id: convId,
      kind: 'direct',
      title: null,
    });
    participants.findOne.mockResolvedValue(null);

    await expect(
      service.mintToken(
        { userId: strangerId, role: UserRole.Customer },
        callId,
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('createCall: member gets join payload + rings peers', async () => {
    conversations.findOne.mockResolvedValue({
      id: convId,
      kind: 'direct',
      title: null,
    });
    participants.findOne.mockResolvedValue({
      conversationId: convId,
      userId: memberId,
    });
    participants.find.mockResolvedValue([
      { userId: memberId },
      { userId: strangerId },
    ]);
    users.findOne.mockResolvedValue({
      id: memberId,
      name: 'Ali',
      avatarUrl: null,
    });

    const join = await service.createCall(
      { userId: memberId, role: UserRole.Customer },
      { conversationId: convId, mode: 'video' },
    );

    expect(join.live).toBe(true);
    expect(join.appId).toBe(config.appId);
    expect(join.mode).toBe('video');
    expect(join.isGroup).toBe(false);
    expect(join.conversationKind).toBe('direct');
    expect(join.token.length).toBeGreaterThan(20);
    expect(join.channelName.startsWith('obic_')).toBe(true);
    expect(realtime.publishCallIncoming).toHaveBeenCalledWith(
      expect.objectContaining({
        userIds: [strangerId],
        payload: expect.objectContaining({
          mode: 'video',
          fromUserId: memberId,
          conversationId: convId,
          isGroup: false,
          conversationKind: 'direct',
        }),
      }),
    );
  });

  it('createCall group: member rings all other members', async () => {
    conversations.findOne.mockResolvedValue({
      id: convId,
      kind: 'group',
      title: 'Trip crew',
    });
    participants.findOne.mockResolvedValue({
      conversationId: convId,
      userId: memberId,
    });
    participants.find.mockResolvedValue([
      { userId: memberId },
      { userId: memberB },
      { userId: memberC },
    ]);
    users.findOne.mockResolvedValue({
      id: memberId,
      name: 'Ali',
      avatarUrl: null,
    });

    const join = await service.createCall(
      { userId: memberId, role: UserRole.Customer },
      { conversationId: convId, mode: 'voice' },
    );

    expect(join.isGroup).toBe(true);
    expect(join.conversationKind).toBe('group');
    expect(join.conversationTitle).toBe('Trip crew');
    expect(realtime.publishCallIncoming).toHaveBeenCalledWith(
      expect.objectContaining({
        userIds: expect.arrayContaining([memberB, memberC]),
        payload: expect.objectContaining({
          isGroup: true,
          conversationKind: 'group',
          conversationTitle: 'Trip crew',
          fromUserId: memberId,
          mode: 'voice',
        }),
      }),
    );
    const ringIds = realtime.publishCallIncoming.mock.calls[0][0]
      .userIds as string[];
    expect(ringIds).toHaveLength(2);
    expect(ringIds).not.toContain(memberId);
  });

  it('createCall group: non-member gets 403 (ACL)', async () => {
    conversations.findOne.mockResolvedValue({
      id: convId,
      kind: 'group',
      title: 'Private group',
    });
    participants.findOne.mockResolvedValue(null);

    await expect(
      service.createCall(
        { userId: strangerId, role: UserRole.Customer },
        { conversationId: convId, mode: 'video' },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(realtime.publishCallIncoming).not.toHaveBeenCalled();
  });

  it('createCall group: SuperAdmin who joined can create + ring', async () => {
    conversations.findOne.mockResolvedValue({
      id: convId,
      kind: 'group',
      title: 'Ops',
    });
    participants.findOne.mockResolvedValue({
      conversationId: convId,
      userId: superAdminId,
    });
    participants.find.mockResolvedValue([
      { userId: superAdminId },
      { userId: memberId },
      { userId: memberB },
    ]);
    users.findOne.mockResolvedValue({
      id: superAdminId,
      name: 'Boss',
      avatarUrl: null,
    });

    const join = await service.createCall(
      { userId: superAdminId, role: UserRole.SuperAdmin },
      { conversationId: convId, mode: 'video' },
    );

    expect(join.isGroup).toBe(true);
    expect(realtime.publishCallIncoming).toHaveBeenCalledWith(
      expect.objectContaining({
        userIds: expect.arrayContaining([memberId, memberB]),
      }),
    );
  });

  it('createCall: fails clearly when Agora unset', async () => {
    (config as { configured: boolean }).configured = false;
    conversations.findOne.mockResolvedValue({
      id: convId,
      kind: 'direct',
      title: null,
    });
    participants.findOne.mockResolvedValue({
      conversationId: convId,
      userId: memberId,
    });

    await expect(
      service.createCall(
        { userId: memberId, role: UserRole.Customer },
        { conversationId: convId, mode: 'voice' },
      ),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);

    (config as { configured: boolean }).configured = true;
  });
});
