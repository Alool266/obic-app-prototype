// Made by Dr Ali
// Customer groups. A group holds company contacts followed by one staff member.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { CompanyContact } from '../company-contacts/company-contact.entity';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { CompanyContactGroup, CompanyContactGroupMember } from './company-group.entities';
import {
  assertGroupMembers,
  assertGroupNote,
  GROUPS_PER_OWNER,
  groupNameKey,
  normalizeGroupName,
} from './company-group';
import { AdminSaveCompanyGroupDto, SaveCompanyGroupDto } from './dto/company-group.dto';

@Injectable()
export class CompanyGroupsService {
  constructor(
    @InjectRepository(CompanyContactGroup)
    private readonly groups: Repository<CompanyContactGroup>,
    @InjectRepository(CompanyContactGroupMember)
    private readonly members: Repository<CompanyContactGroupMember>,
    @InjectRepository(CompanyContact)
    private readonly contacts: Repository<CompanyContact>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const [groups, contacts] = await Promise.all([
      this.groups.find({ where: { ownerUserId: user.id }, order: { name: 'ASC' } }),
      this.contacts.find({
        where: { ownerUserId: user.id },
        select: { id: true, displayName: true },
        order: { displayName: 'ASC' },
        take: 500,
      }),
    ]);
    const links = await this.linksFor(groups.map((group) => group.id));
    return {
      contacts: contacts.map((contact) => ({ id: contact.id, name: contact.displayName })),
      groups: groups.map((group) => this.toCard(group, user, links, contacts)),
    };
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const [people, groups, contacts] = await Promise.all([
      this.users.find({
        where: [
          { role: UserRole.Employee, deletedAt: IsNull() },
          { role: UserRole.SuperAdmin, deletedAt: IsNull() },
        ],
        order: { name: 'ASC' },
      }),
      this.groups.find({ order: { name: 'ASC' }, take: 200 }),
      this.contacts.find({
        select: { id: true, displayName: true, ownerUserId: true },
        order: { displayName: 'ASC' },
        take: 500,
      }),
    ]);
    const links = await this.linksFor(groups.map((group) => group.id));
    const byId = new Map(people.map((person) => [person.id, person]));
    return {
      people: people.map((person) => ({ userId: person.id, name: person.name })),
      contacts: contacts.map((contact) => ({
        id: contact.id,
        name: contact.displayName,
        ownerUserId: contact.ownerUserId,
      })),
      groups: groups.map((group) => this.toCard(group, byId.get(group.ownerUserId) ?? null, links, contacts)),
    };
  }

  async createMine(actor: AuthUser, dto: SaveCompanyGroupDto) {
    const user = await this.requireStaff(actor);
    const saved = await this.insert(user.id, dto);
    await this.audit(user.id, 'company_contact_group_create', saved.id, {
      ownerUserId: user.id,
      memberCount: dto.contactIds.length,
    });
    return this.one(saved.id, user);
  }

  async updateMine(actor: AuthUser, id: string, dto: SaveCompanyGroupDto) {
    const user = await this.requireStaff(actor);
    const row = await this.groups.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This group was not found');
    if (row.ownerUserId !== user.id) {
      throw new ForbiddenException('This group belongs to someone else');
    }
    await this.write(row, user.id, dto);
    await this.audit(user.id, 'company_contact_group_update', row.id, {
      ownerUserId: user.id,
      memberCount: dto.contactIds.length,
    });
    return this.one(row.id, user);
  }

  async saveAdmin(actor: AuthUser, dto: AdminSaveCompanyGroupDto, id?: string) {
    const user = await this.requireSuperAdmin(actor);
    const owner = await this.requireOwner(dto.ownerUserId);
    if (!id) {
      const saved = await this.insert(owner.id, dto);
      await this.audit(user.id, 'company_contact_group_create', saved.id, {
        ownerUserId: owner.id,
        memberCount: dto.contactIds.length,
      });
      return this.one(saved.id, owner);
    }
    const row = await this.groups.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This group was not found');
    await this.write(row, owner.id, dto);
    await this.audit(user.id, 'company_contact_group_update', row.id, {
      ownerUserId: owner.id,
      memberCount: dto.contactIds.length,
    });
    return this.one(row.id, owner);
  }

  private async insert(ownerUserId: string, dto: SaveCompanyGroupDto) {
    const count = await this.groups.count({ where: { ownerUserId } });
    if (count >= GROUPS_PER_OWNER) {
      throw new BadRequestException('This person already has 40 groups');
    }
    const row = this.groups.create({
      name: 'pending',
      nameKey: 'pending',
      note: null,
      ownerUserId,
      active: dto.active ?? true,
    });
    await this.write(row, ownerUserId, dto);
    return row;
  }

  private async write(row: CompanyContactGroup, ownerUserId: string, dto: SaveCompanyGroupDto) {
    const named = this.clean(dto);
    const owned = await this.contacts.find({
      where: { ownerUserId },
      select: { id: true },
    });
    let contactIds: string[];
    try {
      contactIds = assertGroupMembers(dto.contactIds, new Set(owned.map((contact) => contact.id)));
    } catch (error) {
      throw this.statusError(error);
    }
    row.name = named.name;
    row.nameKey = named.nameKey;
    row.note = named.note;
    row.ownerUserId = ownerUserId;
    if (typeof dto.active === 'boolean') row.active = dto.active;
    let saved: CompanyContactGroup;
    try {
      saved = await this.groups.save(row);
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new BadRequestException('This person already has a group with that name');
      }
      throw error;
    }
    await this.replaceMembers(saved.id, contactIds);
  }

  private async replaceMembers(groupId: string, contactIds: string[]) {
    const existing = await this.members.find({ where: { groupId } });
    const existingIds = existing.map((member) => member.contactId);
    const next = new Set(contactIds);
    await this.members.manager.transaction(async (manager) => {
      const repo = manager.getRepository(CompanyContactGroupMember);
      const remove = existingIds.filter((id) => !next.has(id));
      if (remove.length) await repo.delete({ groupId, contactId: In(remove) });
      const have = new Set(existingIds);
      const add = contactIds.filter((id) => !have.has(id));
      if (add.length) {
        await repo.save(add.map((contactId) => repo.create({ groupId, contactId })));
      }
    });
  }

  private async one(id: string, owner: User) {
    const group = await this.groups.findOne({ where: { id } });
    if (!group) throw new NotFoundException('This group was not found');
    const links = await this.members.find({ where: { groupId: id } });
    const contactIds = links.map((link) => link.contactId);
    const contacts = contactIds.length
      ? await this.contacts.find({ where: { id: In(contactIds) } })
      : [];
    return this.toCard(group, owner, links, contacts);
  }

  private async linksFor(groupIds: string[]): Promise<CompanyContactGroupMember[]> {
    if (!groupIds.length) return [];
    return this.members.find({ where: { groupId: In(groupIds) } });
  }

  private toCard(
    group: CompanyContactGroup,
    owner: User | null,
    links: CompanyContactGroupMember[],
    contacts: Pick<CompanyContact, 'id' | 'displayName'>[],
  ) {
    const names = new Map(contacts.map((contact) => [contact.id, contact.displayName]));
    return {
      id: group.id,
      name: group.name,
      note: group.note,
      active: group.active,
      ownerUserId: group.ownerUserId,
      ownerName: owner?.name ?? null,
      members: links
        .filter((link) => link.groupId === group.id)
        .map((link) => ({ contactId: link.contactId, name: names.get(link.contactId) ?? '' }))
        .filter((member) => member.name),
    };
  }

  private clean(dto: SaveCompanyGroupDto): { name: string; nameKey: string; note: string | null } {
    try {
      const name = normalizeGroupName(dto.name);
      return { name, nameKey: groupNameKey(name), note: assertGroupNote(dto.note) };
    } catch (error) {
      throw this.statusError(error);
    }
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
      case 'GROUP_NAME':
        return new BadRequestException('Enter a group name up to 40 characters');
      case 'GROUP_NOTE':
        return new BadRequestException('The note is too long');
      case 'GROUP_MEMBER':
        return new BadRequestException('Choose contacts assigned to this person');
      case 'GROUP_COUNT':
        return new BadRequestException('A group can hold up to 80 contacts');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the group');
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
        resourceType: 'company_contact_group',
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
