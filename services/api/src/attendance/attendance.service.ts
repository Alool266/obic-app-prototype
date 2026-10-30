// Made by Dr Ali
// Staff clock-in. The mark is stored with the punch so a later rule change does not rewrite it.

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
import {
  assertClockRule,
  classifyPunch,
  formatMinute,
  formatWeekdays,
  parseWeekdays,
  shiftDateKey,
  zonedParts,
  type ClockRule,
  type PunchKind,
  type PunchMark,
} from './attendance-clock';
import {
  AttendancePunch,
  AttendanceRule,
  DEFAULT_ATTENDANCE_RULE_ID,
} from './attendance.entities';
import { PunchDto, UpdateAttendanceRuleDto } from './dto/attendance.dto';

const HISTORY_DAYS = 14;

export type AttendanceRuleDto = {
  timezone: string;
  startMinute: number;
  endMinute: number;
  graceMinutes: number;
  weekdays: number[];
};

export type AttendancePunchDto = {
  id: string;
  workDate: string;
  kind: PunchKind;
  punchedAt: string;
  clock: string;
  note: string | null;
  mark: PunchMark;
};

export type AttendanceBoardRow = {
  userId: string;
  name: string;
  staffTitle: string | null;
  branchLabel: string | null;
  clockIn: AttendancePunchDto | null;
  clockOut: AttendancePunchDto | null;
};

@Injectable()
export class AttendanceService {
  constructor(
    @InjectRepository(AttendanceRule)
    private readonly rules: Repository<AttendanceRule>,
    @InjectRepository(AttendancePunch)
    private readonly punches: Repository<AttendancePunch>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async home(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const rule = await this.requireRule();
    const clock = this.toClock(rule);
    const today = zonedParts(new Date(), clock.timezone).workDate;
    const from = shiftDateKey(today, -(HISTORY_DAYS - 1));
    const rows = await this.punches
      .createQueryBuilder('punch')
      .where('punch.user_id = :userId', { userId: user.id })
      .andWhere('punch.work_date >= :from', { from })
      .orderBy('punch.work_date', 'DESC')
      .addOrderBy('punch.kind', 'ASC')
      .getMany();
    return {
      rule: this.toRuleDto(rule),
      today,
      punches: rows.map((row) => this.toPunchDto(row, clock.timezone)),
    };
  }

  async punch(actor: AuthUser, dto: PunchDto) {
    const user = await this.requireStaff(actor);
    const rule = await this.requireRule();
    const clock = this.toClock(rule);
    const now = new Date();
    const parts = zonedParts(now, clock.timezone);
    const existing = await this.punches
      .createQueryBuilder('punch')
      .where('punch.user_id = :userId', { userId: user.id })
      .andWhere('punch.work_date = :workDate', { workDate: parts.workDate })
      .getMany();
    if (existing.some((row) => row.kind === dto.kind)) {
      throw new BadRequestException('Already clocked this way today');
    }
    if (dto.kind === 'out' && !existing.some((row) => row.kind === 'in')) {
      throw new BadRequestException('Clock in before you clock out');
    }
    const mark = classifyPunch({
      kind: dto.kind,
      weekday: parts.weekday,
      minuteOfDay: parts.minuteOfDay,
      rule: clock,
    });
    const note = dto.note?.trim() ? dto.note.trim() : null;
    try {
      const saved = await this.punches.save(
        this.punches.create({
          userId: user.id,
          workDate: parts.workDate,
          kind: dto.kind,
          punchedAt: now,
          note,
          mark,
        }),
      );
      await this.audit(user.id, 'attendance_punch', saved.id, {
        kind: dto.kind,
        workDate: parts.workDate,
        mark,
      });
      return this.toPunchDto(saved, clock.timezone);
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new BadRequestException('Already clocked this way today');
      }
      throw error;
    }
  }

  async board(actor: AuthUser, date: string | undefined) {
    await this.requireReviewer(actor);
    const rule = await this.requireRule();
    const clock = this.toClock(rule);
    const workDate = date?.trim() || zonedParts(new Date(), clock.timezone).workDate;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(workDate)) {
      throw new BadRequestException('Choose a date as YYYY-MM-DD');
    }
    const [people, punches] = await Promise.all([
      this.users.find({
        where: [
          { role: UserRole.Employee, deletedAt: IsNull() },
          { role: UserRole.SuperAdmin, deletedAt: IsNull() },
        ],
        order: { name: 'ASC' },
      }),
      this.punches
        .createQueryBuilder('punch')
        .where('punch.work_date = :workDate', { workDate })
        .getMany(),
    ]);
    const byUser = new Map<string, AttendancePunch[]>();
    for (const punch of punches) {
      const list = byUser.get(punch.userId) ?? [];
      list.push(punch);
      byUser.set(punch.userId, list);
    }
    const rows: AttendanceBoardRow[] = people.map((person) => {
      const mine = byUser.get(person.id) ?? [];
      const clockIn = mine.find((row) => row.kind === 'in');
      const clockOut = mine.find((row) => row.kind === 'out');
      return {
        userId: person.id,
        name: person.name,
        staffTitle: person.staffTitle ?? null,
        branchLabel: person.branchLabel ?? null,
        clockIn: clockIn ? this.toPunchDto(clockIn, clock.timezone) : null,
        clockOut: clockOut ? this.toPunchDto(clockOut, clock.timezone) : null,
      };
    });
    return { date: workDate, rule: this.toRuleDto(rule), rows };
  }

  async updateRule(actor: AuthUser, dto: UpdateAttendanceRuleDto) {
    const user = await this.requireSuperAdmin(actor);
    const next: ClockRule = {
      timezone: dto.timezone.trim(),
      startMinute: dto.startMinute,
      endMinute: dto.endMinute,
      graceMinutes: dto.graceMinutes,
      weekdays: [...new Set(dto.weekdays)].sort((a, b) => a - b),
    };
    try {
      assertClockRule(next);
    } catch (error) {
      if (error instanceof Error && error.message === 'INVALID_TIMEZONE') {
        throw new BadRequestException('Choose a valid timezone');
      }
      if (error instanceof Error && error.message === 'INVALID_RULE') {
        throw new BadRequestException(
          'The workday must start before it ends, on at least one weekday',
        );
      }
      throw error;
    }
    const rule = await this.requireRule();
    rule.timezone = next.timezone;
    rule.startMinute = next.startMinute;
    rule.endMinute = next.endMinute;
    rule.graceMinutes = next.graceMinutes;
    rule.weekdays = formatWeekdays(next.weekdays);
    const saved = await this.rules.save(rule);
    await this.audit(user.id, 'admin_update_attendance_rule', saved.id, {
      timezone: saved.timezone,
      startMinute: saved.startMinute,
      endMinute: saved.endMinute,
      graceMinutes: saved.graceMinutes,
      weekdays: saved.weekdays,
    });
    return this.toRuleDto(saved);
  }

  private toClock(rule: AttendanceRule): ClockRule {
    return {
      timezone: rule.timezone,
      startMinute: rule.startMinute,
      endMinute: rule.endMinute,
      graceMinutes: rule.graceMinutes,
      weekdays: parseWeekdays(rule.weekdays),
    };
  }

  private toRuleDto(rule: AttendanceRule): AttendanceRuleDto {
    const clock = this.toClock(rule);
    return {
      timezone: clock.timezone,
      startMinute: clock.startMinute,
      endMinute: clock.endMinute,
      graceMinutes: clock.graceMinutes,
      weekdays: clock.weekdays,
    };
  }

  private toPunchDto(row: AttendancePunch, timezone: string): AttendancePunchDto {
    const punchedAt = new Date(row.punchedAt);
    return {
      id: row.id,
      workDate: dateKey(row.workDate),
      kind: row.kind,
      punchedAt: punchedAt.toISOString(),
      clock: formatMinute(zonedParts(punchedAt, timezone).minuteOfDay),
      note: row.note,
      mark: row.mark,
    };
  }

  private async requireRule(): Promise<AttendanceRule> {
    const rule = await this.rules.findOne({
      where: { id: DEFAULT_ATTENDANCE_RULE_ID },
    });
    if (!rule) {
      throw new NotFoundException('Clock rule is not set up');
    }
    return rule;
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
        resourceType: 'attendance',
        resourceId,
        meta,
      }),
    );
  }
}

function dateKey(value: string | Date): string {
  if (typeof value === 'string') return value.slice(0, 10);
  const year = value.getUTCFullYear();
  const month = String(value.getUTCMonth() + 1).padStart(2, '0');
  const day = String(value.getUTCDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function isUniqueViolation(error: unknown): boolean {
  if (!error || typeof error !== 'object') return false;
  const row = error as { code?: string; driverError?: { code?: string } };
  return row.code === '23505' || row.driverError?.code === '23505';
}
