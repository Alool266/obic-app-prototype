// Made by Dr Ali
// Company web tools for staff. Customers receive 403.
// The page stays on its own site. This list does not host a package or issue an API key.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import {
  APP_LIMIT,
  appNameKey,
  assertAppNote,
  assertAppUrl,
  normalizeAppName,
} from './company-app';
import { CompanyApp } from './company-app.entity';
import { SaveCompanyAppDto } from './dto/company-app.dto';

@Injectable()
export class CompanyAppsService {
  constructor(
    @InjectRepository(CompanyApp)
    private readonly apps: Repository<CompanyApp>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    await this.requireStaff(actor);
    const rows = await this.apps.find({
      where: { active: true },
      order: { name: 'ASC' },
      take: APP_LIMIT,
    });
    return { rows: rows.map((row) => this.toCard(row)) };
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const rows = await this.apps.find({ order: { name: 'ASC' }, take: APP_LIMIT });
    return { rows: rows.map((row) => this.toCard(row)) };
  }

  async saveAdmin(actor: AuthUser, dto: SaveCompanyAppDto, id?: string) {
    const user = await this.requireSuperAdmin(actor);
    const existing = id ? await this.requireApp(id) : null;
    if (!existing) {
      const count = await this.apps.count();
      if (count >= APP_LIMIT) throw new BadRequestException('The company already has 20 apps');
    }
    let name: string;
    let note: string | null;
    let url: string;
    try {
      name = normalizeAppName(dto.name);
      note = assertAppNote(dto.note);
      url = assertAppUrl(dto.url);
    } catch (error) {
      throw this.statusError(error);
    }
    const row = existing ?? this.apps.create({ createdBy: user.id, active: true });
    row.name = name;
    row.nameKey = appNameKey(name);
    row.note = note;
    row.url = url;
    if (typeof dto.active === 'boolean') row.active = dto.active;
    try {
      const saved = await this.apps.save(row);
      await this.auditLogs.save(
        this.auditLogs.create({
          actorId: user.id,
          action: existing ? 'company_app_update' : 'company_app_create',
          resourceType: 'company_app',
          resourceId: saved.id,
          meta: { name: saved.name },
        }),
      );
      return this.toCard(saved);
    } catch (error) {
      if (isUniqueViolation(error)) throw new BadRequestException('That app already exists');
      throw error;
    }
  }

  private toCard(row: CompanyApp) {
    return {
      id: row.id,
      name: row.name,
      note: row.note,
      url: row.url,
      active: row.active,
    };
  }

  private async requireApp(id: string): Promise<CompanyApp> {
    const row = await this.apps.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This app was not found');
    return row;
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'APP_NAME':
        return new BadRequestException('Enter a name up to 40 characters');
      case 'APP_NOTE':
        return new BadRequestException('The note is too long');
      case 'APP_URL':
        return new BadRequestException('Enter an HTTPS address up to 200 characters');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the app');
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
}

function isUniqueViolation(error: unknown): boolean {
  if (!error || typeof error !== 'object') return false;
  const row = error as { code?: string; driverError?: { code?: string } };
  return row.code === '23505' || row.driverError?.code === '23505';
}
