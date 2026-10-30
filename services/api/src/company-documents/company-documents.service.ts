// Made by Dr Ali
// Shared documents. Staff can update the text. Customers receive 403.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import {
  assertDocBody,
  DOC_LIMIT,
  docTitleKey,
  normalizeDocTitle,
} from './company-document';
import { CompanyDocument } from './company-document.entity';
import { SaveDocumentBodyDto, SaveDocumentDto } from './dto/company-document.dto';

const listColumns = {
  id: true,
  title: true,
  active: true,
  updatedBy: true,
  updatedAt: true,
} as const;

@Injectable()
export class CompanyDocumentsService {
  constructor(
    @InjectRepository(CompanyDocument)
    private readonly documents: Repository<CompanyDocument>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    await this.requireStaff(actor);
    const rows = await this.documents.find({
      where: { active: true },
      order: { title: 'ASC' },
      take: DOC_LIMIT,
      select: listColumns,
    });
    const names = await this.namesFor(rows.map((row) => row.updatedBy));
    return { rows: rows.map((row) => this.toListCard(row, names)) };
  }

  async one(actor: AuthUser, id: string) {
    await this.requireStaff(actor);
    const row = await this.requireDocument(id);
    if (!row.active) throw new BadRequestException('This document is paused');
    const names = await this.namesFor([row.updatedBy]);
    return this.toCard(row, names);
  }

  async updateBody(actor: AuthUser, id: string, dto: SaveDocumentBodyDto) {
    const user = await this.requireStaff(actor);
    const row = await this.requireDocument(id);
    if (!row.active) throw new BadRequestException('This document is paused');
    try {
      row.body = assertDocBody(dto.body);
    } catch (error) {
      throw this.statusError(error);
    }
    row.updatedBy = user.id;
    const saved = await this.documents.save(row);
    await this.audit(user.id, 'company_document_update', saved.id, {
      title: saved.title,
      bodyLength: saved.body.length,
    });
    const names = await this.namesFor([saved.updatedBy]);
    return this.toCard(saved, names);
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const rows = await this.documents.find({
      order: { title: 'ASC' },
      take: DOC_LIMIT,
      select: listColumns,
    });
    const names = await this.namesFor(rows.map((row) => row.updatedBy));
    return {
      rows: rows.map((row) => ({ ...this.toListCard(row, names), active: row.active })),
    };
  }

  async adminOne(actor: AuthUser, id: string) {
    await this.requireReviewer(actor);
    const row = await this.requireDocument(id);
    const names = await this.namesFor([row.updatedBy]);
    return { ...this.toCard(row, names), active: row.active };
  }

  async saveAdmin(actor: AuthUser, dto: SaveDocumentDto, id?: string) {
    const user = await this.requireSuperAdmin(actor);
    if (!id) {
      const count = await this.documents.count();
      if (count >= DOC_LIMIT) throw new BadRequestException('The company already has 40 documents');
    }
    const row = id
      ? await this.requireDocument(id)
      : this.documents.create({
          title: 'pending',
          titleKey: 'pending',
          body: 'pending',
          active: true,
          updatedBy: user.id,
        });
    try {
      const title = normalizeDocTitle(dto.title);
      row.title = title;
      row.titleKey = docTitleKey(title);
      row.body = assertDocBody(dto.body);
      if (typeof dto.active === 'boolean') row.active = dto.active;
    } catch (error) {
      throw this.statusError(error);
    }
    row.updatedBy = user.id;
    let saved: CompanyDocument;
    try {
      saved = await this.documents.save(row);
    } catch (error) {
      if (isUniqueViolation(error)) throw new BadRequestException('That document already exists');
      throw error;
    }
    await this.audit(user.id, id ? 'company_document_update' : 'company_document_create', saved.id, {
      title: saved.title,
      bodyLength: saved.body.length,
    });
    const names = await this.namesFor([saved.updatedBy]);
    return { ...this.toCard(saved, names), active: saved.active };
  }

  private toListCard(
    row: Pick<CompanyDocument, 'id' | 'title' | 'updatedBy' | 'updatedAt'>,
    names: Map<string, string>,
  ) {
    return {
      id: row.id,
      title: row.title,
      editorName: names.get(row.updatedBy) ?? null,
      updatedAt: row.updatedAt,
    };
  }

  private toCard(row: CompanyDocument, names: Map<string, string>) {
    return { ...this.toListCard(row, names), body: row.body };
  }

  private async namesFor(ids: string[]): Promise<Map<string, string>> {
    const unique = [...new Set(ids)];
    if (!unique.length) return new Map();
    const people = await this.users.find({ where: { id: In(unique) } });
    return new Map(people.map((person) => [person.id, person.name]));
  }

  private async requireDocument(id: string): Promise<CompanyDocument> {
    const row = await this.documents.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This document was not found');
    return row;
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'DOC_TITLE':
        return new BadRequestException('Enter a title up to 80 characters');
      case 'DOC_BODY':
        return new BadRequestException('Enter a document up to 8000 characters');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the document');
    }
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

  private async audit(actorId: string, action: string, resourceId: string, meta: Record<string, unknown>) {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action,
        resourceType: 'company_document',
        resourceId,
        meta,
      }),
    );
  }
}

function isUniqueViolation(error: unknown): boolean {
  if (!error || typeof error !== 'object') return false;
  const row = error as { code?: string; driverError?: { code?: string } };
  return row.code === '23505' || row.driverError?.code === '23505';
}
