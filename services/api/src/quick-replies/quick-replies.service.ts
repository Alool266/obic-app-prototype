// Made by Dr Ali
// Quick replies. Staff copy them. The app does not send them. Customers receive 403.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { SaveQuickReplyDto } from './dto/quick-reply.dto';
import { QuickReply } from './quick-reply.entity';
import {
  assertQuickBody,
  assertQuickTitle,
  COMPANY_QUICK_LIMIT,
  PERSONAL_QUICK_LIMIT,
  quickTitleKey,
} from './quick-reply';

@Injectable()
export class QuickRepliesService {
  constructor(
    @InjectRepository(QuickReply)
    private readonly replies: Repository<QuickReply>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const [company, own] = await Promise.all([
      this.replies.find({
        where: { ownerUserId: IsNull(), active: true },
        order: { title: 'ASC' },
      }),
      this.replies.find({ where: { ownerUserId: user.id }, order: { title: 'ASC' } }),
    ]);
    return {
      company: company.map((row) => this.toCard(row)),
      mine: own.map((row) => this.toCard(row)),
    };
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const [rows, people] = await Promise.all([
      this.replies.find({ order: { title: 'ASC' }, take: 200 }),
      this.users.find({
        where: [
          { role: UserRole.Employee, deletedAt: IsNull() },
          { role: UserRole.SuperAdmin, deletedAt: IsNull() },
        ],
      }),
    ]);
    const names = new Map(people.map((person) => [person.id, person.name]));
    return {
      rows: rows.map((row) => ({
        ...this.toCard(row),
        ownerUserId: row.ownerUserId,
        ownerName: row.ownerUserId ? (names.get(row.ownerUserId) ?? null) : null,
      })),
    };
  }

  async createMine(actor: AuthUser, dto: SaveQuickReplyDto) {
    const user = await this.requireStaff(actor);
    const count = await this.replies.count({ where: { ownerUserId: user.id } });
    if (count >= PERSONAL_QUICK_LIMIT) {
      throw new BadRequestException('You already have 20 quick replies');
    }
    const saved = await this.insert(user.id, dto);
    await this.audit(user.id, 'quick_reply_create', saved.id, { title: saved.title });
    return this.toCard(saved);
  }

  async updateMine(actor: AuthUser, id: string, dto: SaveQuickReplyDto) {
    const user = await this.requireStaff(actor);
    const row = await this.replies.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This reply was not found');
    if (row.ownerUserId !== user.id) {
      throw new ForbiddenException('This reply belongs to the company or to someone else');
    }
    const saved = await this.write(row, dto);
    await this.audit(user.id, 'quick_reply_update', saved.id, { title: saved.title });
    return this.toCard(saved);
  }

  async createAdmin(actor: AuthUser, dto: SaveQuickReplyDto) {
    const user = await this.requireSuperAdmin(actor);
    const count = await this.replies.count({ where: { ownerUserId: IsNull() } });
    if (count >= COMPANY_QUICK_LIMIT) {
      throw new BadRequestException('The company already has 40 quick replies');
    }
    const saved = await this.insert(null, dto);
    await this.audit(user.id, 'quick_reply_create', saved.id, { title: saved.title });
    return this.toCard(saved);
  }

  async updateAdmin(actor: AuthUser, id: string, dto: SaveQuickReplyDto) {
    const user = await this.requireSuperAdmin(actor);
    const row = await this.replies.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This reply was not found');
    const saved = await this.write(row, dto);
    await this.audit(user.id, 'quick_reply_update', saved.id, { title: saved.title });
    return this.toCard(saved);
  }

  private async insert(ownerUserId: string | null, dto: SaveQuickReplyDto) {
    const text = this.clean(dto);
    try {
      return await this.replies.save(
        this.replies.create({
          title: text.title,
          titleKey: text.titleKey,
          body: text.body,
          ownerUserId,
          active: dto.active ?? true,
        }),
      );
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new BadRequestException('That reply already exists');
      }
      throw error;
    }
  }

  private async write(row: QuickReply, dto: SaveQuickReplyDto) {
    const text = this.clean(dto);
    row.title = text.title;
    row.titleKey = text.titleKey;
    row.body = text.body;
    if (typeof dto.active === 'boolean') row.active = dto.active;
    try {
      return await this.replies.save(row);
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new BadRequestException('That reply already exists');
      }
      throw error;
    }
  }

  private toCard(row: QuickReply) {
    return { id: row.id, title: row.title, body: row.body, active: row.active };
  }

  private clean(dto: SaveQuickReplyDto): { title: string; titleKey: string; body: string } {
    try {
      const title = assertQuickTitle(dto.title);
      return { title, titleKey: quickTitleKey(title), body: assertQuickBody(dto.body) };
    } catch (error) {
      throw this.statusError(error);
    }
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'QUICK_TITLE':
        return new BadRequestException('Enter a title up to 24 characters');
      case 'QUICK_BODY':
        return new BadRequestException('Enter a reply up to 300 characters');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the reply');
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

  private async audit(
    actorId: string,
    action: string,
    resourceId: string,
    meta: Record<string, unknown>,
  ) {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action,
        resourceType: 'company_quick_reply',
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
