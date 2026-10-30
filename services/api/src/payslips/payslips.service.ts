// Made by Dr Ali
// Monthly pay records. Confirming a payslip means the employee has seen it.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { zonedParts } from '../attendance/attendance-clock';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { SavePayslipDto } from './dto/payslip.dto';
import { StaffPayslip } from './payslip.entity';
import {
  assertPayslipLines,
  assertPayslipPeriod,
  assertPayslipWritable,
  payslipNetCents,
  type PayslipLine,
} from './payslip';

const COMPANY_TIMEZONE = 'Asia/Shanghai';

@Injectable()
export class PayslipsService {
  constructor(
    @InjectRepository(StaffPayslip)
    private readonly payslips: Repository<StaffPayslip>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const rows = await this.payslips.find({
      where: { userId: user.id },
      order: { periodKey: 'DESC' },
      take: 24,
    });
    return { rows: rows.map((row) => this.toCard(row, user)) };
  }

  async acknowledge(actor: AuthUser, id: string) {
    const user = await this.requireStaff(actor);
    const row = await this.payslips.findOne({ where: { id, userId: user.id } });
    if (!row) throw new NotFoundException('This payslip was not found');
    if (!row.acknowledgedAt) {
      row.acknowledgedAt = new Date();
      await this.payslips.save(row);
      await this.audit(user.id, 'payslip_acknowledge', row.id, { period: row.periodKey });
    }
    return this.toCard(row, user);
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const [people, rows] = await Promise.all([
      this.users.find({
        where: [
          { role: UserRole.Employee, deletedAt: IsNull() },
          { role: UserRole.SuperAdmin, deletedAt: IsNull() },
        ],
        order: { name: 'ASC' },
      }),
      this.payslips.find({ order: { periodKey: 'DESC' }, take: 80 }),
    ]);
    const byId = new Map(people.map((person) => [person.id, person]));
    return {
      today: this.today().slice(0, 7),
      people: people.map((person) => ({ userId: person.id, name: person.name })),
      rows: rows
        .filter((row) => byId.has(row.userId))
        .map((row) => this.toCard(row, byId.get(row.userId)!)),
    };
  }

  async save(actor: AuthUser, dto: SavePayslipDto) {
    const user = await this.requireSuperAdmin(actor);
    const target = await this.requireTarget(dto.userId);
    const lines = this.cleanLines(dto);
    const note = dto.note?.trim() ? dto.note.trim() : null;
    const existing = await this.payslips.findOne({
      where: { userId: target.id, periodKey: dto.period },
    });
    let saved: StaffPayslip;
    if (existing) {
      this.ensureWritable(existing);
      existing.lines = lines;
      existing.netCents = payslipNetCents(lines);
      existing.note = note;
      existing.currency = 'CNY';
      saved = await this.payslips.save(existing);
    } else {
      try {
        saved = await this.payslips.save(
          this.payslips.create({
            userId: target.id,
            periodKey: dto.period,
            currency: 'CNY',
            note,
            lines,
            netCents: payslipNetCents(lines),
            acknowledgedAt: null,
          }),
        );
      } catch (error) {
        if (!isUniqueViolation(error)) throw error;
        const again = await this.payslips.findOne({
          where: { userId: target.id, periodKey: dto.period },
        });
        if (!again) throw error;
        this.ensureWritable(again);
        again.lines = lines;
        again.netCents = payslipNetCents(lines);
        again.note = note;
        saved = await this.payslips.save(again);
      }
    }
    await this.audit(user.id, 'payslip_save', saved.id, {
      userId: target.id,
      period: dto.period,
    });
    return this.toCard(saved, target);
  }

  private cleanLines(dto: SavePayslipDto): PayslipLine[] {
    try {
      assertPayslipPeriod(dto.period, this.today().slice(0, 7));
      return assertPayslipLines(
        dto.lines.map((line) => ({
          key: line.key,
          label: line.label,
          kind: line.kind,
          cents: line.cents,
        })),
      );
    } catch (error) {
      throw this.statusError(error);
    }
  }

  private ensureWritable(row: StaffPayslip) {
    try {
      assertPayslipWritable(row.acknowledgedAt != null);
    } catch (error) {
      throw this.statusError(error);
    }
  }

  private toCard(row: StaffPayslip, person: User) {
    return {
      id: row.id,
      userId: person.id,
      name: person.name,
      period: row.periodKey,
      currency: row.currency,
      note: row.note,
      lines: row.lines,
      netCents: row.netCents,
      acknowledgedAt: row.acknowledgedAt ? row.acknowledgedAt.toISOString() : null,
      canAcknowledge: row.acknowledgedAt == null,
    };
  }

  private today(): string {
    return zonedParts(new Date(), COMPANY_TIMEZONE).workDate;
  }

  private async requireTarget(userId: string): Promise<User> {
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
      case 'PAYSLIP_PERIOD':
        return new BadRequestException('Choose a month from 2020 through next month');
      case 'PAYSLIP_LINES':
        return new BadRequestException('Add between 1 and 12 lines');
      case 'PAYSLIP_LINE_KEY':
        return new BadRequestException('Each line needs its own key');
      case 'PAYSLIP_LINE_LABEL':
        return new BadRequestException('Each line needs a label');
      case 'PAYSLIP_LINE_KIND':
        return new BadRequestException('Mark each line as pay or a deduction');
      case 'PAYSLIP_AMOUNT':
        return new BadRequestException('Each amount must be from 0 to 1,000,000.00');
      case 'PAYSLIP_LOCKED':
        return new BadRequestException('This payslip was already confirmed');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the payslip');
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
        resourceType: 'staff_payslip',
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
