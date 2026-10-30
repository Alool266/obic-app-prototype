// Made by Dr Ali
// Customer handover. SuperAdmin moves company contacts. Customers receive 403.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CompanyContact } from '../company-contacts/company-contact.entity';
import {
  CompanyContactGroup,
  CompanyContactGroupMember,
} from '../company-groups/company-group.entities';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import {
  assertHandoverIds,
  assertHandoverParties,
  assertOptionalStaffId,
  type HandoverContactSnap,
} from './company-handover';
import { CompanyContactHandover } from './company-handover.entity';
import { CreateHandoverDto } from './dto/company-handover.dto';

@Injectable()
export class CompanyHandoversService {
  constructor(
    @InjectRepository(CompanyContactHandover)
    private readonly handovers: Repository<CompanyContactHandover>,
    @InjectRepository(CompanyContact)
    private readonly contacts: Repository<CompanyContact>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const rows = await this.handovers.find({
      where: [{ fromUserId: user.id }, { toUserId: user.id }],
      order: { createdAt: 'DESC' },
      take: 40,
    });
    const names = await this.namesFor(rows.flatMap((row) => [row.fromUserId, row.toUserId]));
    return {
      rows: rows.map((row) => {
        const direction = row.fromUserId === user.id ? 'given' : 'received';
        const otherId = direction === 'given' ? row.toUserId : row.fromUserId;
        return {
          id: row.id,
          direction,
          otherName: names.get(otherId) ?? null,
          contactCount: row.contactCount,
          contacts: this.snaps(row.contacts),
          createdAt: row.createdAt,
        };
      }),
    };
  }

  async board(actor: AuthUser, fromUserId?: string) {
    await this.requireReviewer(actor);
    let fromId: string | null;
    try {
      fromId = assertOptionalStaffId(fromUserId);
    } catch (error) {
      throw this.statusError(error);
    }
    if (fromId) await this.requireOwner(fromId);
    const [people, rows, owned] = await Promise.all([
      this.users.find({
        where: [
          { role: UserRole.Employee, deletedAt: IsNull() },
          { role: UserRole.SuperAdmin, deletedAt: IsNull() },
        ],
        order: { name: 'ASC' },
      }),
      this.handovers.find({ order: { createdAt: 'DESC' }, take: 40 }),
      fromId
        ? this.contacts.find({
            where: { ownerUserId: fromId },
            order: { displayName: 'ASC' },
            take: 200,
            select: { id: true, displayName: true, active: true },
          })
        : Promise.resolve([] as CompanyContact[]),
    ]);
    const names = await this.namesFor(
      rows.flatMap((row) => [row.fromUserId, row.toUserId, row.actorUserId]),
    );
    return {
      people: people.map((person) => ({ userId: person.id, name: person.name })),
      handovers: rows.map((row) => ({
        id: row.id,
        fromUserId: row.fromUserId,
        fromName: names.get(row.fromUserId) ?? null,
        toUserId: row.toUserId,
        toName: names.get(row.toUserId) ?? null,
        actorName: names.get(row.actorUserId) ?? null,
        contactCount: row.contactCount,
        contacts: this.snaps(row.contacts),
        createdAt: row.createdAt,
      })),
      contacts: owned.map((contact) => ({
        id: contact.id,
        name: contact.displayName,
        active: contact.active,
      })),
    };
  }

  async create(actor: AuthUser, dto: CreateHandoverDto) {
    const user = await this.requireSuperAdmin(actor);
    try {
      assertHandoverParties(dto.fromUserId, dto.toUserId);
    } catch (error) {
      throw this.statusError(error);
    }
    const from = await this.requireOwner(dto.fromUserId);
    const to = await this.requireOwner(dto.toUserId);
    let ids: string[];
    try {
      ids = assertHandoverIds(dto.contactIds);
    } catch (error) {
      throw this.statusError(error);
    }
    const owned = await this.contacts.find({
      where: { id: In(ids), ownerUserId: from.id },
      select: { id: true, displayName: true },
    });
    if (owned.length !== ids.length) {
      throw new BadRequestException('Choose contacts assigned to this person');
    }
    const names = new Map(owned.map((contact) => [contact.id, contact.displayName]));
    const snaps: HandoverContactSnap[] = ids.map((id) => ({
      id,
      name: names.get(id) ?? '',
    }));
    const saved = await this.contacts.manager.transaction(async (manager) => {
      const updated = await manager
        .createQueryBuilder()
        .update(CompanyContact)
        .set({ ownerUserId: to.id })
        .where('id IN (:...ids)', { ids })
        .andWhere('owner_user_id = :fromId', { fromId: from.id })
        .execute();
      if ((updated.affected ?? 0) !== ids.length) {
        throw new BadRequestException('Choose contacts assigned to this person');
      }
      const groupRows = await manager.getRepository(CompanyContactGroup).find({
        where: { ownerUserId: from.id },
        select: { id: true },
      });
      const groupIds = groupRows.map((group) => group.id);
      if (groupIds.length) {
        await manager.getRepository(CompanyContactGroupMember).delete({
          groupId: In(groupIds),
          contactId: In(ids),
        });
      }
      return manager.getRepository(CompanyContactHandover).save(
        manager.getRepository(CompanyContactHandover).create({
          fromUserId: from.id,
          toUserId: to.id,
          actorUserId: user.id,
          contactCount: snaps.length,
          contacts: snaps,
        }),
      );
    });
    await this.audit(user.id, saved.id, {
      fromUserId: from.id,
      toUserId: to.id,
      contactCount: saved.contactCount,
    });
    return { id: saved.id, contactCount: saved.contactCount };
  }

  private snaps(value: unknown): HandoverContactSnap[] {
    if (!Array.isArray(value)) return [];
    const rows: HandoverContactSnap[] = [];
    for (const item of value) {
      if (!item || typeof item !== 'object') continue;
      const row = item as { id?: unknown; name?: unknown };
      if (typeof row.id !== 'string' || typeof row.name !== 'string') continue;
      rows.push({ id: row.id, name: row.name });
    }
    return rows;
  }

  private async namesFor(ids: string[]): Promise<Map<string, string>> {
    const unique = [...new Set(ids)];
    if (!unique.length) return new Map();
    const people = await this.users.find({ where: { id: In(unique) } });
    return new Map(people.map((person) => [person.id, person.name]));
  }

  private async requireOwner(userId: string): Promise<User> {
    const user = await this.users.findOne({ where: { id: userId } });
    if (
      !user ||
      user.deletedAt ||
      (user.role !== UserRole.Employee && user.role !== UserRole.SuperAdmin)
    ) {
      throw new BadRequestException('Choose a staff member');
    }
    return user;
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'HANDOVER_SAME':
        return new BadRequestException('Choose a different staff member');
      case 'HANDOVER_EMPTY':
        return new BadRequestException('Choose at least one contact');
      case 'HANDOVER_COUNT':
        return new BadRequestException('Move at most 200 contacts at a time');
      case 'HANDOVER_STAFF':
        return new BadRequestException('Choose a staff member');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the handover');
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

  private async audit(actorId: string, resourceId: string, meta: Record<string, unknown>) {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action: 'company_contact_handover',
        resourceType: 'company_contact_handover',
        resourceId,
        meta,
      }),
    );
  }
}
