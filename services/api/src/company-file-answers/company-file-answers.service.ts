// Made by Dr Ali
// Staff questions over shared documents. Customers receive 403.
// The customer catalog is not searched. A missing AI key still returns the matching lines.

import { BadRequestException, ForbiddenException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { AiService } from '../ai/ai.service';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CompanyDocument } from '../company-documents/company-document.entity';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import {
  draftFromHits,
  normalizeFileQuestion,
  rankCompanyDocuments,
} from './company-file-answer';
import { CompanyFileAnswer } from './company-file-answer.entity';
import { AskCompanyFilesDto } from './dto/company-file-answer.dto';

const NONE = 'The company documents do not say.';

type AnsweredBy = 'documents' | 'ai';

@Injectable()
export class CompanyFileAnswersService {
  constructor(
    @InjectRepository(CompanyFileAnswer)
    private readonly answers: Repository<CompanyFileAnswer>,
    @InjectRepository(CompanyDocument)
    private readonly documents: Repository<CompanyDocument>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
    private readonly ai: AiService,
  ) {}

  async mine(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const rows = await this.answers.find({
      where: { userId: user.id },
      order: { createdAt: 'DESC' },
      take: 20,
    });
    return { aiEnabled: this.ai.status().enabled, rows: rows.map((row) => this.toCard(row)) };
  }

  async ask(actor: AuthUser, dto: AskCompanyFilesDto) {
    const user = await this.requireStaff(actor);
    const saved = await this.answerFor(user, dto.question);
    return this.toCard(saved);
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const rows = await this.answers.find({
      order: { createdAt: 'DESC' },
      take: 40,
    });
    const names = await this.namesFor(rows.map((row) => row.userId));
    return {
      aiEnabled: this.ai.status().enabled,
      rows: rows.map((row) => ({ ...this.toCard(row), askerName: names.get(row.userId) ?? null })),
    };
  }

  async askAdmin(actor: AuthUser, dto: AskCompanyFilesDto) {
    const user = await this.requireSuperAdmin(actor);
    const saved = await this.answerFor(user, dto.question);
    const names = await this.namesFor([saved.userId]);
    return { ...this.toCard(saved), askerName: names.get(saved.userId) ?? null };
  }

  private async answerFor(user: User, raw: string): Promise<CompanyFileAnswer> {
    let question: string;
    try {
      question = normalizeFileQuestion(raw);
    } catch (error) {
      throw this.statusError(error);
    }
    const docs = await this.documents.find({
      where: { active: true },
      select: { id: true, title: true, body: true },
    });
    const hits = rankCompanyDocuments(
      question,
      docs.map((doc) => ({ id: doc.id, title: doc.title, body: doc.body })),
    );
    const draft = draftFromHits(hits);
    const replied = await this.reply(user.id, question, draft);
    const saved = await this.answers.save(
      this.answers.create({
        userId: user.id,
        question,
        answer: replied.answer,
        sources: hits.map((hit) => hit.title),
        answeredBy: replied.answeredBy,
      }),
    );
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId: user.id,
        action: 'company_file_answer',
        resourceType: 'company_file_answer',
        resourceId: saved.id,
        meta: { sourceCount: hits.length, answeredBy: replied.answeredBy },
      }),
    );
    return saved;
  }

  private async reply(
    userId: string,
    question: string,
    draft: string | null,
  ): Promise<{ answer: string; answeredBy: AnsweredBy }> {
    if (!draft) return { answer: NONE, answeredBy: 'documents' };
    if (!this.ai.status().enabled) return { answer: draft, answeredBy: 'documents' };
    try {
      const written = await this.ai.completeFromCompanyFiles({ userId, question, excerpts: draft });
      if (!written) return { answer: draft, answeredBy: 'documents' };
      return { answer: written, answeredBy: 'ai' };
    } catch {
      return { answer: draft, answeredBy: 'documents' };
    }
  }

  private toCard(row: CompanyFileAnswer) {
    return {
      id: row.id,
      question: row.question,
      answer: row.answer,
      sources: Array.isArray(row.sources) ? row.sources.filter((item) => typeof item === 'string') : [],
      answeredBy: this.readAnsweredBy(row.answeredBy),
      createdAt: row.createdAt.toISOString(),
    };
  }

  private readAnsweredBy(value: string): AnsweredBy {
    switch (value) {
      case 'documents':
      case 'ai':
        return value;
      default:
        return 'documents';
    }
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'FILE_QUESTION':
        return new BadRequestException('Enter a question up to 300 characters');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the question');
    }
  }

  private async namesFor(ids: string[]): Promise<Map<string, string>> {
    const unique = [...new Set(ids)];
    if (!unique.length) return new Map();
    const people = await this.users.find({ where: { id: In(unique) } });
    return new Map(people.map((person) => [person.id, person.name]));
  }

  private async requireStaff(actor: AuthUser): Promise<User> {
    const user = await this.users.findOne({ where: { id: actor.userId } });
    if (
      !user ||
      user.deletedAt ||
      (user.role !== UserRole.Employee && user.role !== UserRole.SuperAdmin)
    ) {
      throw new ForbiddenException('Staff only');
    }
    return user;
  }

  private async requireReviewer(actor: AuthUser): Promise<User> {
    const user = await this.requireStaff(actor);
    if (!canOpenInternalOps(user)) {
      throw new ForbiddenException('SuperAdmin or Internal Ops only');
    }
    return user;
  }

  private async requireSuperAdmin(actor: AuthUser): Promise<User> {
    const user = await this.requireStaff(actor);
    if (user.role !== UserRole.SuperAdmin) {
      throw new ForbiddenException('SuperAdmin only');
    }
    return user;
  }
}
