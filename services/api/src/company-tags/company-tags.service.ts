// Made by Dr Ali
// Company tags. Staff attach them to contacts they follow. Customers receive 403.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { CompanyContact } from '../company-contacts/company-contact.entity';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { CompanyContactTag, CompanyTag } from './company-tag.entities';
import { assertTagSelection, normalizeTagName, TAG_LIMIT, tagNameKey } from './company-tag';
import { SaveCompanyTagDto, SetContactTagsDto } from './dto/company-tag.dto';

@Injectable()
export class CompanyTagsService {
  constructor(
    @InjectRepository(CompanyTag)
    private readonly tags: Repository<CompanyTag>,
    @InjectRepository(CompanyContactTag)
    private readonly links: Repository<CompanyContactTag>,
    @InjectRepository(CompanyContact)
    private readonly contacts: Repository<CompanyContact>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const [catalog, ownContacts] = await Promise.all([
      this.tags.find({ order: { name: 'ASC' } }),
      this.contacts.find({
        where: { ownerUserId: user.id },
        select: { id: true, displayName: true },
        order: { displayName: 'ASC' },
      }),
    ]);
    const links = await this.linksFor(ownContacts.map((contact) => contact.id));
    const used = new Set(links.map((link) => link.tagId));
    return {
      tags: catalog
        .filter((tag) => tag.active || used.has(tag.id))
        .map((tag) => this.toTag(tag)),
      assignments: ownContacts.map((contact) => ({
        contactId: contact.id,
        name: contact.displayName,
        tagIds: links.filter((link) => link.contactId === contact.id).map((link) => link.tagId),
      })),
    };
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const [catalog, links] = await Promise.all([
      this.tags.find({ order: { name: 'ASC' } }),
      this.links.find(),
    ]);
    return {
      tags: catalog.map((tag) => ({
        ...this.toTag(tag),
        contactCount: links.filter((link) => link.tagId === tag.id).length,
      })),
      assignments: this.groupAssignments(links),
    };
  }

  async create(actor: AuthUser, dto: SaveCompanyTagDto) {
    const user = await this.requireSuperAdmin(actor);
    const count = await this.tags.count();
    if (count >= TAG_LIMIT) {
      throw new BadRequestException('The company already has 40 tags');
    }
    const name = this.cleanName(dto.name);
    try {
      const saved = await this.tags.save(
        this.tags.create({
          name,
          nameKey: tagNameKey(name),
          active: dto.active ?? true,
        }),
      );
      await this.audit(user.id, 'company_tag_create', saved.id, { name: saved.name });
      return this.toTag(saved);
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new BadRequestException('That tag already exists');
      }
      throw error;
    }
  }

  async update(actor: AuthUser, id: string, dto: SaveCompanyTagDto) {
    const user = await this.requireSuperAdmin(actor);
    const row = await this.tags.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This tag was not found');
    const name = this.cleanName(dto.name);
    row.name = name;
    row.nameKey = tagNameKey(name);
    if (typeof dto.active === 'boolean') row.active = dto.active;
    try {
      const saved = await this.tags.save(row);
      await this.audit(user.id, 'company_tag_update', saved.id, { name: saved.name, active: saved.active });
      return this.toTag(saved);
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new BadRequestException('That tag already exists');
      }
      throw error;
    }
  }

  async setMine(actor: AuthUser, contactId: string, dto: SetContactTagsDto) {
    const user = await this.requireStaff(actor);
    return this.replaceTags(user, contactId, dto.tagIds, false);
  }

  async setAdmin(actor: AuthUser, contactId: string, dto: SetContactTagsDto) {
    const user = await this.requireSuperAdmin(actor);
    return this.replaceTags(user, contactId, dto.tagIds, true);
  }

  private async replaceTags(actor: User, contactId: string, tagIds: string[], asAdmin: boolean) {
    const contact = await this.contacts.findOne({ where: { id: contactId } });
    if (!contact) throw new NotFoundException('This contact was not found');
    if (!asAdmin && contact.ownerUserId !== actor.id) {
      throw new ForbiddenException('This contact is assigned to someone else');
    }
    const existing = await this.links.find({ where: { contactId } });
    const existingIds = existing.map((link) => link.tagId);
    const catalog = await this.tags.find();
    const allowed = new Set(catalog.filter((tag) => tag.active).map((tag) => tag.id));
    for (const id of existingIds) allowed.add(id);
    let next: string[];
    try {
      next = assertTagSelection(tagIds, allowed);
    } catch (error) {
      throw this.statusError(error);
    }
    const nextSet = new Set(next);
    await this.links.manager.transaction(async (manager) => {
      const repo = manager.getRepository(CompanyContactTag);
      const remove = existingIds.filter((id) => !nextSet.has(id));
      if (remove.length) await repo.delete({ contactId, tagId: In(remove) });
      const have = new Set(existingIds);
      const add = next.filter((id) => !have.has(id));
      if (add.length) {
        await repo.save(add.map((tagId) => repo.create({ contactId, tagId })));
      }
    });
    await this.audit(actor.id, 'company_contact_tags', contactId, { tagCount: next.length });
    return { contactId, tagIds: next };
  }

  private async linksFor(contactIds: string[]): Promise<CompanyContactTag[]> {
    if (!contactIds.length) return [];
    return this.links.find({ where: { contactId: In(contactIds) } });
  }

  private groupAssignments(links: CompanyContactTag[]) {
    const byContact = new Map<string, string[]>();
    for (const link of links) {
      const current = byContact.get(link.contactId) ?? [];
      current.push(link.tagId);
      byContact.set(link.contactId, current);
    }
    return [...byContact.entries()].map(([contactId, tagIds]) => ({ contactId, tagIds }));
  }

  private toTag(tag: CompanyTag) {
    return { id: tag.id, name: tag.name, active: tag.active };
  }

  private cleanName(value: string): string {
    try {
      return normalizeTagName(value);
    } catch (error) {
      throw this.statusError(error);
    }
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'TAG_NAME':
        return new BadRequestException('Enter a tag name up to 24 characters');
      case 'TAG_UNKNOWN':
        return new BadRequestException('Choose a tag from the company list');
      case 'TAG_COUNT':
        return new BadRequestException('Use at most 8 tags');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the tag');
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
        resourceType: 'company_tag',
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
