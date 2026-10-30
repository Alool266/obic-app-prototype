// Made by Dr Ali
// Company contacts. An employee sees the people assigned to them. Customers receive 403.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { CompanyContact } from './company-contact.entity';
import {
  assertContactName,
  assertContactText,
  normalizeContactPhone,
} from './company-contact';
import {
  AdminSaveCompanyContactDto,
  SaveCompanyContactDto,
} from './dto/company-contact.dto';

@Injectable()
export class CompanyContactsService {
  constructor(
    @InjectRepository(CompanyContact)
    private readonly contacts: Repository<CompanyContact>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser, q?: string) {
    const user = await this.requireStaff(actor);
    const rows = await this.list(user.id, q);
    return { rows: rows.map((row) => this.toCard(row, user)) };
  }

  async createMine(actor: AuthUser, dto: SaveCompanyContactDto) {
    const user = await this.requireStaff(actor);
    const saved = await this.insert(dto, user.id);
    await this.audit(user.id, 'company_contact_create', saved.id, { ownerUserId: user.id });
    return this.toCard(saved, user);
  }

  async updateMine(actor: AuthUser, id: string, dto: SaveCompanyContactDto) {
    const user = await this.requireStaff(actor);
    const row = await this.contacts.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This contact was not found');
    if (row.ownerUserId !== user.id) {
      throw new ForbiddenException('This contact is assigned to someone else');
    }
    await this.apply(row, dto);
    const saved = await this.save(row);
    await this.audit(user.id, 'company_contact_update', saved.id, { ownerUserId: user.id });
    return this.toCard(saved, user);
  }

  async board(actor: AuthUser, q?: string) {
    await this.requireReviewer(actor);
    const [people, rows] = await Promise.all([
      this.users.find({
        where: [
          { role: UserRole.Employee, deletedAt: IsNull() },
          { role: UserRole.SuperAdmin, deletedAt: IsNull() },
        ],
        order: { name: 'ASC' },
      }),
      this.list(null, q),
    ]);
    const ownerIds = [...new Set(rows.map((row) => row.ownerUserId))];
    const owners = ownerIds.length
      ? await this.users.find({ where: { id: In(ownerIds) } })
      : [];
    const byId = new Map(owners.map((owner) => [owner.id, owner]));
    return {
      people: people.map((person) => ({ userId: person.id, name: person.name })),
      rows: rows.map((row) => this.toCard(row, byId.get(row.ownerUserId) ?? null)),
    };
  }

  async saveAdmin(actor: AuthUser, dto: AdminSaveCompanyContactDto, id?: string) {
    const user = await this.requireSuperAdmin(actor);
    const owner = await this.requireOwner(dto.ownerUserId);
    if (!id) {
      const saved = await this.insert(dto, owner.id);
      await this.audit(user.id, 'company_contact_create', saved.id, { ownerUserId: owner.id });
      return this.toCard(saved, owner);
    }
    const row = await this.contacts.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This contact was not found');
    const previousOwner = row.ownerUserId;
    row.ownerUserId = owner.id;
    await this.apply(row, dto);
    const saved = await this.save(row);
    await this.audit(
      user.id,
      previousOwner === owner.id ? 'company_contact_update' : 'company_contact_reassign',
      saved.id,
      { ownerUserId: owner.id, previousOwnerUserId: previousOwner },
    );
    return this.toCard(saved, owner);
  }

  private async insert(dto: SaveCompanyContactDto, ownerUserId: string) {
    const row = this.contacts.create({
      displayName: 'pending',
      phone: null,
      orgName: null,
      note: null,
      ownerUserId,
      active: dto.active ?? true,
    });
    await this.apply(row, dto);
    return this.save(row);
  }

  private async apply(row: CompanyContact, dto: SaveCompanyContactDto) {
    try {
      row.displayName = assertContactName(dto.name);
      row.phone = normalizeContactPhone(dto.phone);
      row.orgName = assertContactText(dto.orgName, 80, 'CONTACT_ORG');
      row.note = assertContactText(dto.note, 500, 'CONTACT_NOTE');
      if (typeof dto.active === 'boolean') row.active = dto.active;
    } catch (error) {
      throw this.statusError(error);
    }
  }

  private async save(row: CompanyContact): Promise<CompanyContact> {
    try {
      return await this.contacts.save(row);
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new BadRequestException('This phone is already on a company contact');
      }
      throw error;
    }
  }

  private async list(ownerId: string | null, q?: string): Promise<CompanyContact[]> {
    const query = (q ?? '').trim().slice(0, 80).replace(/[%_]/g, '');
    const qb = this.contacts
      .createQueryBuilder('contact')
      .orderBy('contact.displayName', 'ASC')
      .take(200);
    if (ownerId) qb.where('contact.ownerUserId = :ownerId', { ownerId });
    if (query) {
      qb.andWhere(
        '(contact.displayName ILIKE :q OR contact.phone ILIKE :q OR contact.orgName ILIKE :q)',
        { q: `%${query}%` },
      );
    }
    return qb.getMany();
  }

  private toCard(row: CompanyContact, owner: User | null) {
    return {
      id: row.id,
      name: row.displayName,
      phone: row.phone,
      orgName: row.orgName,
      note: row.note,
      ownerUserId: row.ownerUserId,
      ownerName: owner?.name ?? null,
      active: row.active,
    };
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
      case 'CONTACT_NAME':
        return new BadRequestException('Enter a name');
      case 'CONTACT_PHONE':
        return new BadRequestException('Enter a phone with 6 to 20 digits');
      case 'CONTACT_ORG':
        return new BadRequestException('The organization name is too long');
      case 'CONTACT_NOTE':
        return new BadRequestException('The note is too long');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the contact');
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
        resourceType: 'company_contact',
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
