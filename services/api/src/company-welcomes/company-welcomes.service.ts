// Made by Dr Ali
// Company greetings. The employee sees one. The app does not send it.

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
import { CompanyWelcome, CompanyWelcomeAssignment } from './company-welcome.entities';
import {
  assertWelcomeBody,
  assertWelcomeTitle,
  pickWelcome,
  WELCOME_LIMIT,
} from './company-welcome';
import { AssignWelcomeDto, SaveWelcomeDto } from './dto/company-welcome.dto';

@Injectable()
export class CompanyWelcomesService {
  constructor(
    @InjectRepository(CompanyWelcome)
    private readonly welcomes: Repository<CompanyWelcome>,
    @InjectRepository(CompanyWelcomeAssignment)
    private readonly assignments: Repository<CompanyWelcomeAssignment>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const assignment = await this.assignments.findOne({ where: { userId: user.id } });
    const assigned = assignment
      ? await this.welcomes.findOne({ where: { id: assignment.welcomeId } })
      : null;
    const company = await this.welcomes.findOne({ where: { isDefault: true } });
    return {
      welcome: pickWelcome(
        assigned ? this.text(assigned) : null,
        company ? this.text(company) : null,
      ),
    };
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const [welcomes, people, assignments] = await Promise.all([
      this.welcomes.find({ order: { title: 'ASC' } }),
      this.users.find({
        where: [
          { role: UserRole.Employee, deletedAt: IsNull() },
          { role: UserRole.SuperAdmin, deletedAt: IsNull() },
        ],
        order: { name: 'ASC' },
      }),
      this.assignments.find(),
    ]);
    return {
      welcomes: welcomes.map((row) => this.toRow(row)),
      people: people.map((person) => ({ userId: person.id, name: person.name })),
      assignments: assignments.map((row) => ({ userId: row.userId, welcomeId: row.welcomeId })),
    };
  }

  async create(actor: AuthUser, dto: SaveWelcomeDto) {
    const user = await this.requireSuperAdmin(actor);
    const count = await this.welcomes.count();
    if (count >= WELCOME_LIMIT) {
      throw new BadRequestException('The company already has 20 greetings');
    }
    const text = this.clean(dto);
    const saved = await this.store(
      this.welcomes.create({
        title: text.title,
        body: text.body,
        active: dto.active ?? true,
        isDefault: false,
      }),
      dto.isDefault === true,
    );
    await this.audit(user.id, 'company_welcome_create', saved.id, { title: saved.title });
    return this.toRow(saved);
  }

  async update(actor: AuthUser, id: string, dto: SaveWelcomeDto) {
    const user = await this.requireSuperAdmin(actor);
    const row = await this.welcomes.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This greeting was not found');
    const text = this.clean(dto);
    row.title = text.title;
    row.body = text.body;
    if (typeof dto.active === 'boolean') row.active = dto.active;
    const saved = await this.store(row, dto.isDefault === true);
    await this.audit(user.id, 'company_welcome_update', saved.id, { title: saved.title });
    return this.toRow(saved);
  }

  async assign(actor: AuthUser, dto: AssignWelcomeDto) {
    const user = await this.requireSuperAdmin(actor);
    const target = await this.requireOwner(dto.userId);
    if (dto.welcomeId) {
      const welcome = await this.welcomes.findOne({ where: { id: dto.welcomeId } });
      if (!welcome) throw new NotFoundException('This greeting was not found');
      await this.assignments.save(
        this.assignments.create({ userId: target.id, welcomeId: welcome.id }),
      );
    } else {
      await this.assignments.delete({ userId: target.id });
    }
    await this.audit(user.id, 'company_welcome_assign', target.id, {
      welcomeId: dto.welcomeId ?? null,
    });
    return { userId: target.id, welcomeId: dto.welcomeId ?? null };
  }

  private async store(row: CompanyWelcome, isDefault: boolean) {
    try {
      return await this.welcomes.manager.transaction(async (manager) => {
        const repo = manager.getRepository(CompanyWelcome);
        if (isDefault) {
          await repo
            .createQueryBuilder()
            .update()
            .set({ isDefault: false })
            .where('is_default = true')
            .execute();
        }
        row.isDefault = isDefault;
        return repo.save(row);
      });
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new BadRequestException('Another greeting is already the company default');
      }
      throw error;
    }
  }

  private text(row: CompanyWelcome) {
    return { title: row.title, body: row.body, active: row.active };
  }

  private toRow(row: CompanyWelcome) {
    return {
      id: row.id,
      title: row.title,
      body: row.body,
      active: row.active,
      isDefault: row.isDefault,
    };
  }

  private clean(dto: SaveWelcomeDto): { title: string; body: string } {
    try {
      return { title: assertWelcomeTitle(dto.title), body: assertWelcomeBody(dto.body) };
    } catch (error) {
      throw this.statusError(error);
    }
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'WELCOME_TITLE':
        return new BadRequestException('Enter a title up to 40 characters');
      case 'WELCOME_BODY':
        return new BadRequestException('Enter a greeting up to 500 characters');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the greeting');
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
        resourceType: 'company_welcome',
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
