// Made by Dr Ali
// Thin content filter + report queue. Server is the only authority.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { Message } from '../chat/message.entity';
import { MomentComment } from '../moments/moment-comment.entity';
import { Moment } from '../moments/moment.entity';
import { BannedWord } from './banned-word.entity';
import {
  ContentReport,
  ReportSource,
  ReportStatus,
  ReportTargetType,
} from './content-report.entity';
import { firstBannedHit, normalizeForFilter } from './word-matcher';

export const CONTENT_BLOCKED = 'This content is not allowed';

@Injectable()
export class ModerationService {
  constructor(
    @InjectRepository(BannedWord)
    private readonly words: Repository<BannedWord>,
    @InjectRepository(ContentReport)
    private readonly reports: Repository<ContentReport>,
    @InjectRepository(Message)
    private readonly messages: Repository<Message>,
    @InjectRepository(ConversationParticipant)
    private readonly participants: Repository<ConversationParticipant>,
    @InjectRepository(Moment)
    private readonly moments: Repository<Moment>,
    @InjectRepository(MomentComment)
    private readonly comments: Repository<MomentComment>,
  ) {}

  /** Reject send if an active phrase matches. Also opens an auto flag for SuperAdmin. */
  async assertClean(actor: AuthUser, text: string, context: {
    targetType: ReportTargetType;
    targetId?: string;
  }): Promise<void> {
    const hit = await this.findHit(text);
    if (!hit) return;

    await this.reports.save(
      this.reports.create({
        reporterId: actor.userId,
        targetType: context.targetType,
        targetId: context.targetId ?? actor.userId,
        source: ReportSource.Auto,
        reason: 'auto_filter',
        snippet: this.clip(text),
        status: ReportStatus.Open,
      }),
    );
    throw new BadRequestException(CONTENT_BLOCKED);
  }

  async createUserReport(actor: AuthUser, input: {
    targetType: ReportTargetType;
    targetId: string;
    reason?: string;
  }) {
    await this.assertCanReport(actor, input.targetType, input.targetId);
    const snippet = await this.snippetFor(input.targetType, input.targetId);
    const saved = await this.reports.save(
      this.reports.create({
        reporterId: actor.userId,
        targetType: input.targetType,
        targetId: input.targetId,
        source: ReportSource.User,
        reason: (input.reason ?? '').trim().slice(0, 500),
        snippet,
        status: ReportStatus.Open,
      }),
    );
    return this.reportDto(saved);
  }

  async listReports(actor: AuthUser) {
    this.requireSuperAdmin(actor);
    const rows = await this.reports.find({
      order: { createdAt: 'DESC' },
      take: 200,
    });
    return rows.map((r) => this.reportDto(r));
  }

  async reviewReport(
    actor: AuthUser,
    id: string,
    status: ReportStatus,
  ) {
    this.requireSuperAdmin(actor);
    if (status === ReportStatus.Open) {
      throw new BadRequestException('Choose reviewed or dismissed');
    }
    const row = await this.reports.findOne({ where: { id } });
    if (!row) throw new NotFoundException('Report not found');
    row.status = status;
    row.reviewedBy = actor.userId;
    row.reviewedAt = new Date();
    const saved = await this.reports.save(row);
    return this.reportDto(saved);
  }

  async listWords(actor: AuthUser) {
    this.requireSuperAdmin(actor);
    return this.words.find({ order: { phrase: 'ASC' } });
  }

  async addWord(actor: AuthUser, phrase: string, category?: string) {
    this.requireSuperAdmin(actor);
    const normalized = normalizeForFilter(phrase);
    if (normalized.length < 3) {
      throw new BadRequestException('Phrase too short');
    }
    const existing = await this.words.findOne({ where: { phrase: normalized } });
    if (existing) {
      existing.isActive = true;
      existing.category = (category ?? existing.category).slice(0, 40);
      return this.words.save(existing);
    }
    return this.words.save(
      this.words.create({
        phrase: normalized,
        category: (category ?? 'general').slice(0, 40),
        isActive: true,
      }),
    );
  }

  private async findHit(text: string): Promise<string | null> {
    const active = await this.words.find({ where: { isActive: true } });
    return firstBannedHit(
      text,
      active.map((w) => w.phrase),
    );
  }

  private requireSuperAdmin(actor: AuthUser) {
    if (actor.role !== UserRole.SuperAdmin) {
      throw new ForbiddenException('Insufficient role');
    }
  }

  private async assertCanReport(
    actor: AuthUser,
    type: ReportTargetType,
    id: string,
  ) {
    if (type === ReportTargetType.Message) {
      const msg = await this.messages.findOne({ where: { id } });
      if (!msg) throw new NotFoundException('Message not found');
      const part = await this.participants.findOne({
        where: { conversationId: msg.conversationId, userId: actor.userId },
      });
      if (!part) throw new ForbiddenException('Not in this conversation');
      return;
    }
    if (type === ReportTargetType.Thread) {
      const part = await this.participants.findOne({
        where: { conversationId: id, userId: actor.userId },
      });
      if (!part) throw new ForbiddenException('Not in this conversation');
      return;
    }
    if (type === ReportTargetType.Moment) {
      const moment = await this.moments.findOne({ where: { id } });
      if (!moment) throw new NotFoundException('Moment not found');
      return;
    }
    if (type === ReportTargetType.Comment) {
      const comment = await this.comments.findOne({ where: { id } });
      if (!comment) throw new NotFoundException('Comment not found');
    }
  }

  private async snippetFor(
    type: ReportTargetType,
    id: string,
  ): Promise<string> {
    if (type === ReportTargetType.Message) {
      const msg = await this.messages.findOne({ where: { id } });
      return this.clip(msg?.body ?? '');
    }
    if (type === ReportTargetType.Moment) {
      const moment = await this.moments.findOne({ where: { id } });
      return this.clip(moment?.body ?? '');
    }
    if (type === ReportTargetType.Comment) {
      const comment = await this.comments.findOne({ where: { id } });
      return this.clip(comment?.body ?? '');
    }
    return '';
  }

  private clip(text: string): string {
    return text.trim().slice(0, 160);
  }

  private reportDto(r: ContentReport) {
    return {
      id: r.id,
      reporterId: r.reporterId,
      targetType: r.targetType,
      targetId: r.targetId,
      source: r.source,
      reason: r.reason,
      snippet: r.snippet,
      status: r.status,
      reviewedBy: r.reviewedBy,
      reviewedAt: r.reviewedAt,
      createdAt: r.createdAt,
    };
  }
}
