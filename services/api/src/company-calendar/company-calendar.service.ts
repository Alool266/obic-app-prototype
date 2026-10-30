// Made by Dr Ali
// Company calendar. Staff share events. Customers receive 403. No invitations are sent.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, In, Not, Repository } from 'typeorm';
import { zonedParts } from '../attendance/attendance-clock';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import {
  assertCalendarDate,
  assertCalendarNote,
  assertCalendarSpan,
  CALENDAR_PER_DAY,
  calendarListRange,
  formatCalendarClock,
  normalizeCalendarTitle,
  parseCalendarClock,
  shiftCalendarDate,
} from './company-calendar';
import { CompanyCalendarEvent } from './company-calendar.entity';
import { SaveCalendarEventDto } from './dto/company-calendar.dto';

const COMPANY_TZ = 'Asia/Shanghai';

@Injectable()
export class CompanyCalendarService {
  constructor(
    @InjectRepository(CompanyCalendarEvent)
    private readonly events: Repository<CompanyCalendarEvent>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser, from?: string, to?: string) {
    const user = await this.requireStaff(actor);
    const range = this.range(from, to);
    const rows = await this.events.find({
      where: [
        { eventDate: Between(range.from, range.to), active: true },
        { eventDate: Between(range.from, range.to), active: false, createdBy: user.id },
      ],
      order: { eventDate: 'ASC', startMinute: 'ASC' },
      take: 100,
    });
    const names = await this.namesFor(rows.map((row) => row.createdBy));
    return {
      today: range.today,
      rows: rows.map((row) => this.toCard(row, names, user.id)),
    };
  }

  async createMine(actor: AuthUser, dto: SaveCalendarEventDto) {
    const user = await this.requireStaff(actor);
    const saved = await this.insert(user, dto);
    await this.audit(user.id, 'company_calendar_create', saved.id, {
      title: saved.title,
      date: saved.eventDate,
    });
    const names = await this.namesFor([saved.createdBy]);
    return this.toCard(saved, names, user.id);
  }

  async updateMine(actor: AuthUser, id: string, dto: SaveCalendarEventDto) {
    const user = await this.requireStaff(actor);
    const row = await this.requireEvent(id);
    if (user.role !== UserRole.SuperAdmin && row.createdBy !== user.id) {
      throw new ForbiddenException('This event belongs to someone else');
    }
    await this.apply(row, dto, row.id);
    const saved = await this.events.save(row);
    await this.audit(user.id, 'company_calendar_update', saved.id, {
      title: saved.title,
      date: saved.eventDate,
    });
    const names = await this.namesFor([saved.createdBy]);
    return this.toCard(saved, names, user.id);
  }

  async board(actor: AuthUser, from?: string, to?: string) {
    await this.requireReviewer(actor);
    const range = this.range(from, to);
    const rows = await this.events.find({
      where: { eventDate: Between(range.from, range.to) },
      order: { eventDate: 'ASC', startMinute: 'ASC' },
      take: 100,
    });
    const names = await this.namesFor(rows.map((row) => row.createdBy));
    return {
      today: range.today,
      rows: rows.map((row) => this.toCard(row, names, null)),
    };
  }

  async saveAdmin(actor: AuthUser, dto: SaveCalendarEventDto, id?: string) {
    const user = await this.requireSuperAdmin(actor);
    const row = id ? await this.requireEvent(id) : null;
    const saved = row ? await this.write(row, dto) : await this.insert(user, dto);
    await this.audit(user.id, id ? 'company_calendar_update' : 'company_calendar_create', saved.id, {
      title: saved.title,
      date: saved.eventDate,
    });
    const names = await this.namesFor([saved.createdBy]);
    return this.toCard(saved, names, null);
  }

  private async insert(user: User, dto: SaveCalendarEventDto) {
    const row = this.events.create({
      title: 'pending',
      eventDate: '2020-01-01',
      startMinute: 0,
      endMinute: 15,
      note: null,
      active: true,
      createdBy: user.id,
    });
    await this.apply(row, dto);
    return this.events.save(row);
  }

  private async write(row: CompanyCalendarEvent, dto: SaveCalendarEventDto) {
    await this.apply(row, dto, row.id);
    return this.events.save(row);
  }

  private async apply(row: CompanyCalendarEvent, dto: SaveCalendarEventDto, ignoreId?: string) {
    const today = this.today();
    let title: string;
    let date: string;
    let start: number;
    let end: number;
    let note: string | null;
    try {
      title = normalizeCalendarTitle(dto.title);
      date = dto.date;
      assertCalendarDate(date, shiftCalendarDate(today, -30), shiftCalendarDate(today, 180));
      start = parseCalendarClock(dto.start);
      end = parseCalendarClock(dto.end);
      assertCalendarSpan(start, end);
      note = assertCalendarNote(dto.note);
    } catch (error) {
      throw this.statusError(error);
    }
    await this.assertDayCapacity(date, ignoreId);
    row.title = title;
    row.eventDate = date;
    row.startMinute = start;
    row.endMinute = end;
    row.note = note;
    if (typeof dto.active === 'boolean') row.active = dto.active;
  }

  private async assertDayCapacity(date: string, ignoreId?: string) {
    const count = await this.events.count({
      where: ignoreId ? { eventDate: date, id: Not(ignoreId) } : { eventDate: date },
    });
    if (count >= CALENDAR_PER_DAY) {
      throw new BadRequestException('This day already has 12 events');
    }
  }

  private range(from?: string, to?: string) {
    const today = this.today();
    try {
      return { today, ...calendarListRange(today, from, to) };
    } catch (error) {
      throw this.statusError(error);
    }
  }

  private today(): string {
    return zonedParts(new Date(), COMPANY_TZ).workDate;
  }

  private toCard(row: CompanyCalendarEvent, names: Map<string, string>, actorId: string | null) {
    return {
      id: row.id,
      title: row.title,
      date: row.eventDate,
      start: formatCalendarClock(row.startMinute),
      end: formatCalendarClock(row.endMinute),
      note: row.note,
      active: row.active,
      createdBy: row.createdBy,
      creatorName: names.get(row.createdBy) ?? null,
      mine: actorId != null && row.createdBy === actorId,
    };
  }

  private async namesFor(ids: string[]): Promise<Map<string, string>> {
    const unique = [...new Set(ids)];
    if (!unique.length) return new Map();
    const people = await this.users.find({ where: { id: In(unique) } });
    return new Map(people.map((person) => [person.id, person.name]));
  }

  private async requireEvent(id: string): Promise<CompanyCalendarEvent> {
    const row = await this.events.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This event was not found');
    return row;
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'CALENDAR_TITLE':
        return new BadRequestException('Enter a title up to 80 characters');
      case 'CALENDAR_NOTE':
        return new BadRequestException('The note is too long');
      case 'CALENDAR_DATE':
        return new BadRequestException('Choose a date from 30 days ago through 180 days ahead');
      case 'CALENDAR_CLOCK':
        return new BadRequestException('Use a time like 09:00');
      case 'CALENDAR_SPAN':
        return new BadRequestException('An event runs from 15 minutes to 12 hours');
      case 'CALENDAR_RANGE':
        return new BadRequestException('Choose a range of at most 120 days');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the event');
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

  private async audit(actorId: string, action: string, resourceId: string, meta: Record<string, unknown>) {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action,
        resourceType: 'company_calendar_event',
        resourceId,
        meta,
      }),
    );
  }
}
