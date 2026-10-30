// Made by Dr Ali
// Richer meetings. Staff see the agenda and the notes. Customers receive 403.
// The app does not start a call and does not send an invitation.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, In, IsNull, Not, Repository } from 'typeorm';
import { zonedParts } from '../attendance/attendance-clock';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import {
  assertCalendarDate,
  assertCalendarSpan,
  calendarListRange,
  formatCalendarClock,
  parseCalendarClock,
  shiftCalendarDate,
} from '../company-calendar/company-calendar';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import {
  assertMeetingAttendees,
  assertMeetingText,
  MEETING_AGENDA_MAX,
  MEETING_NOTES_MAX,
  MEETING_PER_DAY,
  normalizeMeetingTitle,
} from './company-meeting';
import { CompanyMeeting, CompanyMeetingAttendee } from './company-meeting.entities';
import { SaveMeetingDto } from './dto/company-meeting.dto';

const COMPANY_TZ = 'Asia/Shanghai';

@Injectable()
export class CompanyMeetingsService {
  constructor(
    @InjectRepository(CompanyMeeting)
    private readonly meetings: Repository<CompanyMeeting>,
    @InjectRepository(CompanyMeetingAttendee)
    private readonly attendees: Repository<CompanyMeetingAttendee>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const range = this.range();
    const staff = await this.staff();
    const joined = await this.attendees.find({ where: { userId: user.id } });
    const joinedIds = joined.map((row) => row.meetingId);
    const [hosted, invited] = await Promise.all([
      this.meetings.find({
        where: { createdBy: user.id, eventDate: Between(range.from, range.to) },
        order: { eventDate: 'ASC', startMinute: 'ASC' },
        take: 50,
      }),
      joinedIds.length
        ? this.meetings.find({
            where: { id: In(joinedIds), eventDate: Between(range.from, range.to) },
          })
        : Promise.resolve([] as CompanyMeeting[]),
    ]);
    const rows = this.merge(hosted, invited);
    const links = await this.linksFor(rows.map((row) => row.id));
    const names = await this.namesFor([
      ...staff.map((person) => person.id),
      ...rows.map((row) => row.createdBy),
      ...links.map((link) => link.userId),
    ]);
    return {
      today: range.today,
      people: staff
        .filter((person) => person.id !== user.id)
        .map((person) => ({ userId: person.id, name: person.name })),
      rows: rows.map((row) => this.toCard(row, links, names, user.id)),
    };
  }

  async saveMine(actor: AuthUser, dto: SaveMeetingDto, id?: string) {
    const user = await this.requireStaff(actor);
    const existing = id ? await this.requireMeeting(id) : null;
    if (existing && user.role !== UserRole.SuperAdmin && existing.createdBy !== user.id) {
      throw new ForbiddenException('This meeting belongs to someone else');
    }
    const saved = await this.store(user, dto, existing);
    await this.audit(user.id, existing ? 'company_meeting_update' : 'company_meeting_create', saved.id, {
      title: saved.title,
      date: saved.eventDate,
    });
    return this.oneCard(saved, user.id);
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const range = this.range();
    const rows = await this.meetings.find({
      where: { eventDate: Between(range.from, range.to) },
      order: { eventDate: 'ASC', startMinute: 'ASC' },
      take: 80,
    });
    const links = await this.linksFor(rows.map((row) => row.id));
    const staff = await this.staff();
    const names = await this.namesFor([
      ...staff.map((person) => person.id),
      ...rows.map((row) => row.createdBy),
      ...links.map((link) => link.userId),
    ]);
    return {
      today: range.today,
      people: staff.map((person) => ({ userId: person.id, name: person.name })),
      rows: rows.map((row) => this.toCard(row, links, names, null)),
    };
  }

  async saveAdmin(actor: AuthUser, dto: SaveMeetingDto, id?: string) {
    const user = await this.requireSuperAdmin(actor);
    const existing = id ? await this.requireMeeting(id) : null;
    const saved = await this.store(user, dto, existing);
    await this.audit(user.id, existing ? 'company_meeting_update' : 'company_meeting_create', saved.id, {
      title: saved.title,
      date: saved.eventDate,
    });
    return this.oneCard(saved, null);
  }

  private async store(actor: User, dto: SaveMeetingDto, existing: CompanyMeeting | null) {
    const staff = await this.staff();
    const allowed = new Set(staff.map((person) => person.id));
    const organizerId = existing?.createdBy ?? actor.id;
    const today = this.today();
    let title: string;
    let date: string;
    let start: number;
    let end: number;
    let agenda: string | null;
    let notes: string | null;
    let userIds: string[];
    try {
      title = normalizeMeetingTitle(dto.title);
      date = dto.date;
      assertCalendarDate(date, shiftCalendarDate(today, -30), shiftCalendarDate(today, 180));
      start = parseCalendarClock(dto.start);
      end = parseCalendarClock(dto.end);
      assertCalendarSpan(start, end);
      agenda = assertMeetingText(dto.agenda, MEETING_AGENDA_MAX, 'MEETING_AGENDA');
      notes = assertMeetingText(dto.notes, MEETING_NOTES_MAX, 'MEETING_NOTES');
      userIds = assertMeetingAttendees(dto.userIds, organizerId, allowed);
    } catch (error) {
      throw this.statusError(error);
    }
    await this.assertDayCapacity(date, existing?.id);
    return this.meetings.manager.transaction(async (manager) => {
      const meetings = manager.getRepository(CompanyMeeting);
      const seats = manager.getRepository(CompanyMeetingAttendee);
      const row = existing ?? meetings.create({ createdBy: actor.id, active: true });
      row.title = title;
      row.eventDate = date;
      row.startMinute = start;
      row.endMinute = end;
      row.agenda = agenda;
      row.notes = notes;
      if (typeof dto.active === 'boolean') row.active = dto.active;
      const saved = await meetings.save(row);
      await seats.delete({ meetingId: saved.id });
      await seats.save(userIds.map((userId) => seats.create({ meetingId: saved.id, userId })));
      return saved;
    });
  }

  private async oneCard(row: CompanyMeeting, actorId: string | null) {
    const links = await this.linksFor([row.id]);
    const names = await this.namesFor([row.createdBy, ...links.map((link) => link.userId)]);
    return this.toCard(row, links, names, actorId);
  }

  private merge(hosted: CompanyMeeting[], invited: CompanyMeeting[]): CompanyMeeting[] {
    const byId = new Map<string, CompanyMeeting>();
    for (const row of hosted) byId.set(row.id, row);
    for (const row of invited) byId.set(row.id, row);
    return [...byId.values()]
      .sort((a, b) => a.eventDate.localeCompare(b.eventDate) || a.startMinute - b.startMinute)
      .slice(0, 50);
  }

  private async linksFor(ids: string[]): Promise<CompanyMeetingAttendee[]> {
    if (!ids.length) return [];
    return this.attendees.find({ where: { meetingId: In(ids) } });
  }

  private async assertDayCapacity(date: string, ignoreId?: string) {
    const count = await this.meetings.count({
      where: ignoreId ? { eventDate: date, id: Not(ignoreId) } : { eventDate: date },
    });
    if (count >= MEETING_PER_DAY) throw new BadRequestException('This day already has 12 meetings');
  }

  private toCard(
    row: CompanyMeeting,
    links: CompanyMeetingAttendee[],
    names: Map<string, string>,
    actorId: string | null,
  ) {
    return {
      id: row.id,
      title: row.title,
      date: row.eventDate,
      start: formatCalendarClock(row.startMinute),
      end: formatCalendarClock(row.endMinute),
      agenda: row.agenda,
      notes: row.notes,
      active: row.active,
      createdBy: row.createdBy,
      organizerName: names.get(row.createdBy) ?? null,
      attendeeNames: links
        .filter((link) => link.meetingId === row.id)
        .map((link) => names.get(link.userId) ?? null)
        .filter((name): name is string => name != null),
      userIds: links.filter((link) => link.meetingId === row.id).map((link) => link.userId),
      mine: actorId != null && row.createdBy === actorId,
    };
  }

  private range() {
    const today = this.today();
    return { today, ...calendarListRange(today, undefined, undefined) };
  }

  private today(): string {
    return zonedParts(new Date(), COMPANY_TZ).workDate;
  }

  private async staff(): Promise<User[]> {
    return this.users.find({
      where: [
        { role: UserRole.Employee, deletedAt: IsNull() },
        { role: UserRole.SuperAdmin, deletedAt: IsNull() },
      ],
      order: { name: 'ASC' },
    });
  }

  private async namesFor(ids: string[]): Promise<Map<string, string>> {
    const unique = [...new Set(ids)];
    if (!unique.length) return new Map();
    const people = await this.users.find({ where: { id: In(unique) } });
    return new Map(people.map((person) => [person.id, person.name]));
  }

  private async requireMeeting(id: string): Promise<CompanyMeeting> {
    const row = await this.meetings.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This meeting was not found');
    return row;
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'MEETING_TITLE':
        return new BadRequestException('Enter a title up to 80 characters');
      case 'MEETING_AGENDA':
        return new BadRequestException('The agenda is too long');
      case 'MEETING_NOTES':
        return new BadRequestException('The notes are too long');
      case 'MEETING_ATTENDEE':
        return new BadRequestException('Choose a staff member');
      case 'MEETING_COUNT':
        return new BadRequestException('Choose at most 12 people');
      case 'CALENDAR_DATE':
        return new BadRequestException('Choose a date from 30 days ago through 180 days ahead');
      case 'CALENDAR_CLOCK':
        return new BadRequestException('Use a time like 09:00');
      case 'CALENDAR_SPAN':
        return new BadRequestException('A meeting runs from 15 minutes to 12 hours');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the meeting');
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
        resourceType: 'company_meeting',
        resourceId,
        meta,
      }),
    );
  }
}
