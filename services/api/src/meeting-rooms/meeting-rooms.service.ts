// Made by Dr Ali
// Staff book a room. The room row is locked so two people cannot take the same time.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { BookMeetingRoomDto, SaveMeetingRoomDto } from './dto/meeting-room.dto';
import { MeetingBooking, MeetingRoom } from './meeting-room.entities';
import { assertBookingWindow } from './meeting-slot';

const DAY_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class MeetingRoomsService {
  constructor(
    @InjectRepository(MeetingRoom)
    private readonly rooms: Repository<MeetingRoom>,
    @InjectRepository(MeetingBooking)
    private readonly bookings: Repository<MeetingBooking>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async schedule(actor: AuthUser, from?: string, to?: string) {
    const user = await this.requireStaff(actor);
    const range = this.range(from, to, 7);
    const rooms = await this.rooms.find({
      where: { active: true },
      order: { nameEn: 'ASC' },
    });
    return {
      rooms: rooms.map((room) => this.toRoom(room)),
      bookings: await this.bookingsIn(rooms.map((room) => room.id), range, user),
    };
  }

  async board(actor: AuthUser, from?: string, to?: string) {
    const user = await this.requireReviewer(actor);
    const range = this.range(from, to, 14);
    const rooms = await this.rooms.find({ order: { nameEn: 'ASC' } });
    return {
      rooms: rooms.map((room) => this.toRoom(room)),
      bookings: await this.bookingsIn(rooms.map((room) => room.id), range, user),
    };
  }

  async book(actor: AuthUser, dto: BookMeetingRoomDto) {
    const user = await this.requireStaff(actor);
    const start = new Date(dto.startsAt);
    const end = new Date(dto.endsAt);
    try {
      assertBookingWindow({ start, end, now: new Date() });
    } catch (error) {
      throw this.windowError(error);
    }
    const saved = await this.rooms.manager.transaction(async (manager) => {
      const room = await manager.findOne(MeetingRoom, {
        where: { id: dto.roomId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!room || !room.active) {
        throw new BadRequestException('This room is not open for booking');
      }
      const clash = await manager
        .createQueryBuilder(MeetingBooking, 'booking')
        .setLock('pessimistic_write')
        .where('booking.room_id = :roomId', { roomId: room.id })
        .andWhere("booking.status = 'booked'")
        .andWhere('booking.starts_at < :end', { end })
        .andWhere('booking.ends_at > :start', { start })
        .getOne();
      if (clash) {
        throw new BadRequestException('That room is already booked then');
      }
      return manager.save(
        manager.create(MeetingBooking, {
          roomId: room.id,
          userId: user.id,
          title: dto.title.trim(),
          startsAt: start,
          endsAt: end,
          status: 'booked' as const,
        }),
      );
    });
    await this.audit(user.id, 'meeting_room_book', saved.id, {
      roomId: saved.roomId,
      startsAt: start.toISOString(),
      endsAt: end.toISOString(),
    });
    const [card] = await this.bookingsIn([saved.roomId], { start, end }, user);
    return card ?? this.toBooking(saved, user, new Map([[user.id, user]]));
  }

  async cancel(actor: AuthUser, id: string) {
    const user = await this.requireStaff(actor);
    const booking = await this.bookings.findOne({ where: { id } });
    if (!booking || booking.status !== 'booked') {
      throw new NotFoundException('Booking not found');
    }
    const isOwner = booking.userId === user.id;
    const isSuper = user.role === UserRole.SuperAdmin;
    if (!isOwner && !isSuper) {
      throw new ForbiddenException('You can cancel only your own booking');
    }
    if (!isSuper && booking.endsAt.getTime() <= Date.now()) {
      throw new BadRequestException('This booking has finished');
    }
    booking.status = 'cancelled';
    const saved = await this.bookings.save(booking);
    await this.audit(user.id, 'meeting_room_cancel', saved.id, {
      roomId: saved.roomId,
    });
    return { id: saved.id, status: saved.status };
  }

  async createRoom(actor: AuthUser, dto: SaveMeetingRoomDto) {
    const user = await this.requireSuperAdmin(actor);
    const saved = await this.rooms.save(
      this.rooms.create({
        nameEn: dto.nameEn.trim(),
        nameAr: dto.nameAr.trim(),
        nameZh: dto.nameZh.trim(),
        branchLabel: this.branch(dto.branchLabel),
        capacity: dto.capacity,
        active: dto.active,
      }),
    );
    await this.audit(user.id, 'admin_create_meeting_room', saved.id, {
      nameEn: saved.nameEn,
    });
    return this.board(actor);
  }

  async updateRoom(actor: AuthUser, id: string, dto: SaveMeetingRoomDto) {
    const user = await this.requireSuperAdmin(actor);
    const room = await this.rooms.findOne({ where: { id } });
    if (!room) throw new NotFoundException('Room not found');
    room.nameEn = dto.nameEn.trim();
    room.nameAr = dto.nameAr.trim();
    room.nameZh = dto.nameZh.trim();
    room.branchLabel = this.branch(dto.branchLabel);
    room.capacity = dto.capacity;
    room.active = dto.active;
    await this.rooms.save(room);
    await this.audit(user.id, 'admin_update_meeting_room', room.id, {
      active: room.active,
    });
    return this.board(actor);
  }

  private range(from: string | undefined, to: string | undefined, days: number) {
    const now = new Date();
    const start = from ? new Date(from) : now;
    const end = to ? new Date(to) : new Date(start.getTime() + days * DAY_MS);
    if (
      Number.isNaN(start.getTime()) ||
      Number.isNaN(end.getTime()) ||
      end.getTime() <= start.getTime()
    ) {
      throw new BadRequestException('Choose a valid time range');
    }
    if (end.getTime() - start.getTime() > 31 * DAY_MS) {
      throw new BadRequestException('Choose a range of 31 days or less');
    }
    return { start, end };
  }

  private async bookingsIn(
    roomIds: string[],
    range: { start: Date; end: Date },
    viewer: User,
  ) {
    if (!roomIds.length) return [];
    const rows = await this.bookings
      .createQueryBuilder('booking')
      .where('booking.room_id IN (:...roomIds)', { roomIds })
      .andWhere("booking.status = 'booked'")
      .andWhere('booking.starts_at < :end', { end: range.end })
      .andWhere('booking.ends_at > :start', { start: range.start })
      .orderBy('booking.starts_at', 'ASC')
      .getMany();
    const userIds = [...new Set(rows.map((row) => row.userId))];
    const people = userIds.length
      ? await this.users.find({ where: { id: In(userIds) } })
      : [];
    const byId = new Map(people.map((person) => [person.id, person]));
    if (!byId.has(viewer.id)) byId.set(viewer.id, viewer);
    return rows.map((row) => this.toBooking(row, viewer, byId));
  }

  private toRoom(room: MeetingRoom) {
    return {
      id: room.id,
      nameEn: room.nameEn,
      nameAr: room.nameAr,
      nameZh: room.nameZh,
      branchLabel: room.branchLabel,
      capacity: room.capacity,
      active: room.active,
    };
  }

  private toBooking(
    row: MeetingBooking,
    viewer: User,
    people: Map<string, User>,
  ) {
    const owner = row.userId === viewer.id;
    const isSuper = viewer.role === UserRole.SuperAdmin;
    const finished = row.endsAt.getTime() <= Date.now();
    return {
      id: row.id,
      roomId: row.roomId,
      title: row.title,
      startsAt: new Date(row.startsAt).toISOString(),
      endsAt: new Date(row.endsAt).toISOString(),
      bookerId: row.userId,
      bookerName: people.get(row.userId)?.name ?? '',
      canCancel: row.status === 'booked' && (isSuper || (owner && !finished)),
    };
  }

  private branch(value: string | undefined): string | null {
    const trimmed = (value ?? '').trim();
    return trimmed.length ? trimmed : null;
  }

  private windowError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'BOOKING_RANGE':
        return new BadRequestException('The end must be after the start');
      case 'BOOKING_LENGTH':
        return new BadRequestException('Book between 15 minutes and 8 hours');
      case 'BOOKING_PAST':
        return new BadRequestException(
          'Choose a start time that has not already passed',
        );
      case 'BOOKING_HORIZON':
        return new BadRequestException('Book within the next 30 days');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the booking time');
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
        resourceType: 'meeting_room',
        resourceId,
        meta,
      }),
    );
  }
}
