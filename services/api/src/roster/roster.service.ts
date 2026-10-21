// Made by Dr Ali
// The company roster. Confirming a leave records the last day and leaves the login open.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { shiftDateKey, zonedParts } from '../attendance/attendance-clock';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { RecordJoinDto, RequestLeaveDto } from './dto/roster.dto';
import { StaffEmployment } from './roster.entity';
import {
  assertRosterDate,
  isEmploymentStatus,
  nextCancelledLeave,
  nextConfirmedLeave,
  nextJoin,
  nextLeaveRequest,
  type EmploymentStatus,
} from './roster-status';

const COMPANY_TIMEZONE = 'Asia/Shanghai';

@Injectable()
export class RosterService {
  constructor(
    @InjectRepository(StaffEmployment)
    private readonly employments: Repository<StaffEmployment>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const row = await this.employments.findOne({ where: { userId: user.id } });
    return this.toCard(user, row);
  }

  async requestLeave(actor: AuthUser, dto: RequestLeaveDto) {
    const user = await this.requireStaff(actor);
    const row = await this.employments.findOne({ where: { userId: user.id } });
    if (!row || !isEmploymentStatus(row.status)) {
      throw new BadRequestException('Your join date is not on the roster yet');
    }
    const today = this.today();
    try {
      assertRosterDate(dto.lastDay, today, shiftDateKey(today, 365));
      nextLeaveRequest(row.status);
    } catch (error) {
      throw this.statusError(error);
    }
    row.status = 'leaving';
    row.lastDay = dto.lastDay;
    row.leaveNote = dto.note?.trim() ? dto.note.trim() : null;
    const saved = await this.employments.save(row);
    await this.audit(user.id, 'roster_leave_request', user.id, {
      lastDay: saved.lastDay,
    });
    return this.toCard(user, saved);
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
      this.employments.find(),
    ]);
    const byUser = new Map(rows.map((row) => [row.userId, row]));
    return {
      today: this.today(),
      rows: people.map((person) => this.toCard(person, byUser.get(person.id) ?? null)),
    };
  }

  async recordJoin(actor: AuthUser, dto: RecordJoinDto) {
    const user = await this.requireSuperAdmin(actor);
    const target = await this.requireTarget(dto.userId);
    const today = this.today();
    const existing = await this.employments.findOne({ where: { userId: target.id } });
    const status = existing && isEmploymentStatus(existing.status) ? existing.status : null;
    try {
      assertRosterDate(dto.joinedOn, '1990-01-01', shiftDateKey(today, 90));
      nextJoin(status);
    } catch (error) {
      throw this.statusError(error);
    }
    const saved = existing
      ? await this.employments.save(
          Object.assign(existing, {
            joinedOn: dto.joinedOn,
            status: 'active' as const,
            lastDay: null,
            leaveNote: null,
          }),
        )
      : await this.employments.save(
          this.employments.create({
            userId: target.id,
            joinedOn: dto.joinedOn,
            status: 'active' as const,
            lastDay: null,
            leaveNote: null,
          }),
        );
    await this.audit(user.id, 'roster_join', target.id, { joinedOn: dto.joinedOn });
    return this.toCard(target, saved);
  }

  async confirmLeave(actor: AuthUser, userId: string) {
    return this.finishLeave(actor, userId, 'confirm');
  }

  async cancelLeave(actor: AuthUser, userId: string) {
    return this.finishLeave(actor, userId, 'cancel');
  }

  private async finishLeave(
    actor: AuthUser,
    userId: string,
    action: 'confirm' | 'cancel',
  ) {
    const user = await this.requireSuperAdmin(actor);
    const target = await this.requireTarget(userId);
    const row = await this.employments.findOne({ where: { userId: target.id } });
    if (!row || !isEmploymentStatus(row.status)) {
      throw new NotFoundException('This person is not on the roster');
    }
    try {
      if (action === 'confirm') nextConfirmedLeave(row.status);
      else nextCancelledLeave(row.status);
    } catch (error) {
      throw this.statusError(error);
    }
    if (action === 'confirm') {
      row.status = 'left';
    } else {
      row.status = 'active';
      row.lastDay = null;
      row.leaveNote = null;
    }
    const saved = await this.employments.save(row);
    await this.audit(
      user.id,
      action === 'confirm' ? 'roster_leave_confirm' : 'roster_leave_cancel',
      target.id,
      { lastDay: saved.lastDay },
    );
    return this.toCard(target, saved);
  }

  private toCard(person: User, row: StaffEmployment | null) {
    const status: EmploymentStatus | 'unrecorded' =
      row && isEmploymentStatus(row.status) ? row.status : 'unrecorded';
    return {
      userId: person.id,
      name: person.name,
      staffTitle: person.staffTitle ?? null,
      branchLabel: person.branchLabel ?? null,
      status,
      joinedOn: row?.joinedOn ?? null,
      lastDay: row?.lastDay ?? null,
      leaveNote: row?.leaveNote ?? null,
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
      case 'ALREADY_EMPLOYED':
        return new BadRequestException('This person is already on the roster');
      case 'LEAVE_NOT_OPEN':
        return new BadRequestException('A leave request is not open');
      case 'LEAVE_NOT_PENDING':
        return new BadRequestException('There is no leave request to decide');
      case 'ROSTER_DATE':
        return new BadRequestException('Choose a date inside the allowed window');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the roster change');
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
        resourceType: 'staff_roster',
        resourceId,
        meta,
      }),
    );
  }
}
