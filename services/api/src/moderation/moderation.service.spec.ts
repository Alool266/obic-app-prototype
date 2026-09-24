// Made by Dr Ali
import { ForbiddenException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { Message } from '../chat/message.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { MomentComment } from '../moments/moment-comment.entity';
import { Moment } from '../moments/moment.entity';
import { BannedWord } from './banned-word.entity';
import { ContentReport, ReportTargetType } from './content-report.entity';
import { CONTENT_BLOCKED, ModerationService } from './moderation.service';

describe('ModerationService', () => {
  let service: ModerationService;
  const wordsRepo = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn((row: unknown) => row),
    save: jest.fn(async (row: unknown) => row),
  };
  const reportsRepo = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn((row: unknown) => row),
    save: jest.fn(async (row: Record<string, unknown>) => ({
      ...row,
      id: 'report-1',
      createdAt: new Date(),
    })),
  };
  const messagesRepo = { findOne: jest.fn() };
  const participantsRepo = { findOne: jest.fn() };
  const momentsRepo = { findOne: jest.fn() };
  const commentsRepo = { findOne: jest.fn() };

  const customer = new AuthUser('cust-1', 'sess', UserRole.Customer);
  const admin = new AuthUser('admin-1', 'sess', UserRole.SuperAdmin);

  beforeEach(async () => {
    jest.clearAllMocks();
    wordsRepo.find.mockResolvedValue([{ phrase: 'sell cocaine', isActive: true }]);
    const module = await Test.createTestingModule({
      providers: [
        ModerationService,
        { provide: getRepositoryToken(BannedWord), useValue: wordsRepo },
        { provide: getRepositoryToken(ContentReport), useValue: reportsRepo },
        { provide: getRepositoryToken(Message), useValue: messagesRepo },
        {
          provide: getRepositoryToken(ConversationParticipant),
          useValue: participantsRepo,
        },
        { provide: getRepositoryToken(Moment), useValue: momentsRepo },
        { provide: getRepositoryToken(MomentComment), useValue: commentsRepo },
      ],
    }).compile();
    service = module.get(ModerationService);
  });

  it('blocks a banned phrase and records an auto flag', async () => {
    await expect(
      service.assertClean(customer, 'I can sell cocaine', {
        targetType: ReportTargetType.Message,
      }),
    ).rejects.toMatchObject({ message: CONTENT_BLOCKED });
    expect(reportsRepo.save).toHaveBeenCalled();
  });

  it('allows a clean hotel request', async () => {
    await expect(
      service.assertClean(customer, 'Need a hotel in Shenzhen', {
        targetType: ReportTargetType.Moment,
      }),
    ).resolves.toBeUndefined();
  });

  it('forbids a customer from listing the SuperAdmin queue', async () => {
    await expect(service.listReports(customer)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('lets SuperAdmin list reports', async () => {
    reportsRepo.find.mockResolvedValue([]);
    await expect(service.listReports(admin)).resolves.toEqual([]);
  });
});
