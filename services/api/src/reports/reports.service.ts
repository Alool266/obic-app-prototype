// Made by Dr Ali
// Staff write the current day, week, or month. A past period stays as it was sent.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { zonedParts, isValidTimezone } from '../attendance/attendance-clock';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { SubmitReportDto, UpdateReportReviewersDto } from './dto/report.dto';
import {
  DEFAULT_REPORT_SETTING_ID,
  WorkReport,
  WorkReportReviewer,
  WorkReportSetting,
} from './report.entities';
import {
  REPORT_KINDS,
  isReportKind,
  reportPeriodKey,
  type ReportKind,
} from './report-period';

const LIST_LIMIT = 40;

export type ReportCard = {
  id: string;
  kind: ReportKind;
  periodKey: string;
  done: string;
  plan: string;
  blockers: string;
  authorId: string;
  authorName: string;
  updatedAt: string;
  canEdit: boolean;
};

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(WorkReportSetting)
    private readonly settings: Repository<WorkReportSetting>,
    @InjectRepository(WorkReportReviewer)
    private readonly reviewers: Repository<WorkReportReviewer>,
    @InjectRepository(WorkReport)
    private readonly reports: Repository<WorkReport>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async home(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const setting = await this.requireSetting();
    const reviewerRows = await this.reviewerRows();
    const workDate = zonedParts(new Date(), setting.timezone).workDate;
    const current = this.currentKeys(workDate);
    const [mineRows, inboxRows, currentRows, people] = await Promise.all([
      this.reports.find({
        where: { userId: user.id },
        order: { updatedAt: 'DESC' },
        take: LIST_LIMIT,
      }),
      this.canReadOthers(user, reviewerRows)
        ? this.reports
            .createQueryBuilder('report')
            .where('report.user_id != :userId', { userId: user.id })
            .orderBy('report.updated_at', 'DESC')
            .take(LIST_LIMIT)
            .getMany()
        : Promise.resolve([]),
      this.reports.find({
        where: REPORT_KINDS.map((kind) => ({
          userId: user.id,
          kind,
          periodKey: current[kind],
        })),
      }),
      this.users.find({
        where: { id: In(this.peopleIds(user.id, reviewerRows)) },
      }),
    ]);
    const uniqueRows = new Map<string, WorkReport>();
    for (const row of [...currentRows, ...mineRows, ...inboxRows]) {
      uniqueRows.set(row.id, row);
    }
    const named = await this.withAuthors(
      [...uniqueRows.values()],
      current,
      user.id,
      people,
    );
    return {
      timezone: setting.timezone,
      today: workDate,
      reviewers: reviewerRows.map((row) => ({
        id: row.userId,
        name: this.nameOf(people, row.userId),
      })),
      periods: REPORT_KINDS.map((kind) => {
        const periodKey = current[kind];
        const report =
          named.find(
            (row) =>
              row.authorId === user.id &&
              row.kind === kind &&
              row.periodKey === periodKey,
          ) ?? null;
        return { kind, periodKey, report };
      }),
      mine: named.filter((row) => row.authorId === user.id),
      inbox: named.filter((row) => row.authorId !== user.id),
    };
  }

  async submit(actor: AuthUser, dto: SubmitReportDto) {
    const user = await this.requireStaff(actor);
    const setting = await this.requireSetting();
    const workDate = zonedParts(new Date(), setting.timezone).workDate;
    const periodKey = reportPeriodKey(dto.kind, workDate);
    const done = dto.done.trim();
    const plan = dto.plan.trim();
    const blockers = dto.blockers?.trim() ?? '';
    if (!done || !plan) {
      throw new BadRequestException('Write what you finished and what is next');
    }
    const existing = await this.reports.findOne({
      where: { userId: user.id, kind: dto.kind, periodKey },
    });
    const saved = await this.saveReport(existing, {
      userId: user.id,
      kind: dto.kind,
      periodKey,
      done,
      plan,
      blockers,
    });
    await this.audit(user.id, 'report_submit', saved.id, {
      kind: dto.kind,
      periodKey,
    });
    const [card] = await this.withAuthors(
      [saved],
      this.currentKeys(workDate),
      user.id,
      [user],
    );
    if (!card) {
      throw new NotFoundException('Report was not saved');
    }
    return card;
  }

  async board(actor: AuthUser, kind: string | undefined) {
    await this.requireReviewer(actor);
    const setting = await this.requireSetting();
    const reviewerRows = await this.reviewerRows();
    if (kind && !isReportKind(kind)) {
      throw new BadRequestException('Choose a daily, weekly, or monthly report');
    }
    const query = this.reports
      .createQueryBuilder('report')
      .orderBy('report.updated_at', 'DESC')
      .take(LIST_LIMIT);
    if (kind && isReportKind(kind)) {
      query.andWhere('report.kind = :kind', { kind });
    }
    const rows = await query.getMany();
    const workDate = zonedParts(new Date(), setting.timezone).workDate;
    const cards = await this.withAuthors(
      rows,
      this.currentKeys(workDate),
      actor.userId,
    );
    const reviewerIds = reviewerRows.map((row) => row.userId);
    const people = reviewerIds.length
      ? await this.users.find({ where: { id: In(reviewerIds) } })
      : [];
    return {
      timezone: setting.timezone,
      reviewers: reviewerRows.map((row) => ({
        id: row.userId,
        name: this.nameOf(people, row.userId),
      })),
      rows: cards,
    };
  }

  async updateReviewers(actor: AuthUser, dto: UpdateReportReviewersDto) {
    const user = await this.requireSuperAdmin(actor);
    const timezone = dto.timezone.trim();
    if (!isValidTimezone(timezone)) {
      throw new BadRequestException('Choose a valid timezone');
    }
    const reviewerIds = [...new Set(dto.reviewerIds)];
    if (reviewerIds.length) {
      const staff = await this.users.find({
        where: { id: In(reviewerIds), deletedAt: IsNull() },
      });
      const allowed = new Set(
        staff
          .filter(
            (person) =>
              person.role === UserRole.Employee ||
              person.role === UserRole.SuperAdmin,
          )
          .map((person) => person.id),
      );
      if (reviewerIds.some((id) => !allowed.has(id))) {
        throw new BadRequestException('Receivers must be staff');
      }
    }
    const setting = await this.requireSetting();
    setting.timezone = timezone;
    await this.settings.manager.transaction(async (manager) => {
      await manager.delete(WorkReportReviewer, { settingId: setting.id });
      await manager.save(setting);
      if (reviewerIds.length) {
        await manager.save(
          reviewerIds.map((userId, position) =>
            manager.create(WorkReportReviewer, {
              userId,
              settingId: setting.id,
              position,
            }),
          ),
        );
      }
    });
    await this.audit(user.id, 'admin_update_report_reviewers', setting.id, {
      timezone,
      reviewerIds,
    });
    return this.board(actor, undefined);
  }

  private currentKeys(workDate: string): Record<ReportKind, string> {
    return {
      daily: reportPeriodKey('daily', workDate),
      weekly: reportPeriodKey('weekly', workDate),
      monthly: reportPeriodKey('monthly', workDate),
    };
  }

  private async saveReport(
    existing: WorkReport | null,
    input: {
      userId: string;
      kind: ReportKind;
      periodKey: string;
      done: string;
      plan: string;
      blockers: string;
    },
  ): Promise<WorkReport> {
    if (existing) {
      existing.done = input.done;
      existing.plan = input.plan;
      existing.blockers = input.blockers;
      return this.reports.save(existing);
    }
    try {
      return await this.reports.save(this.reports.create(input));
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;
      const again = await this.reports.findOne({
        where: {
          userId: input.userId,
          kind: input.kind,
          periodKey: input.periodKey,
        },
      });
      if (!again) throw error;
      return this.saveReport(again, input);
    }
  }

  private async withAuthors(
    rows: WorkReport[],
    current: Record<ReportKind, string>,
    viewerId: string,
    known: User[] = [],
  ): Promise<ReportCard[]> {
    const missing = [
      ...new Set(rows.map((row) => row.userId)),
    ].filter((id) => !known.some((person) => person.id === id));
    const loaded = missing.length
      ? await this.users.find({ where: { id: In(missing) } })
      : [];
    const people = [...known, ...loaded];
    return rows.map((row) => ({
      id: row.id,
      kind: row.kind,
      periodKey: row.periodKey,
      done: row.done,
      plan: row.plan,
      blockers: row.blockers,
      authorId: row.userId,
      authorName: this.nameOf(people, row.userId),
      updatedAt: new Date(row.updatedAt).toISOString(),
      canEdit: row.userId === viewerId && current[row.kind] === row.periodKey,
    }));
  }

  private nameOf(people: User[], userId: string): string {
    return people.find((person) => person.id === userId)?.name ?? '';
  }

  private peopleIds(actorId: string, reviewers: WorkReportReviewer[]): string[] {
    return [...new Set([actorId, ...reviewers.map((row) => row.userId)])];
  }

  private canReadOthers(user: User, reviewers: WorkReportReviewer[]): boolean {
    if (user.role === UserRole.SuperAdmin) return true;
    return reviewers.some((row) => row.userId === user.id);
  }

  private async reviewerRows(): Promise<WorkReportReviewer[]> {
    return this.reviewers.find({ order: { position: 'ASC' } });
  }

  private async requireSetting(): Promise<WorkReportSetting> {
    const setting = await this.settings.findOne({
      where: { id: DEFAULT_REPORT_SETTING_ID },
    });
    if (!setting) {
      throw new NotFoundException('Report receivers are not set up');
    }
    return setting;
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
        resourceType: 'work_report',
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
