// Made by Dr Ali
// VIP module (boss M06): timed consultations with a hard stop, and trip
// builder with frozen versioned quotations. No in-app payment exists yet —
// staff record an external payment reference, and only then may the
// official group be created (VIP-001). Prices come only from Active
// price versions; while they are Draft, customers get a clear message.

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import {
  Conversation,
  ConversationKind,
} from '../chat/conversation.entity';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { computeQuoteTotals } from '../prices/price';
import { PricesService } from '../prices/prices.service';
import {
  AssignVipDto,
  CreateConsultationDto,
  CreateGroupDto,
  CreateTripDto,
  MarkPaidDto,
  QuoteTripDto,
  TransitionTripDto,
} from './dto/vip.dto';
import { VipConsultation } from './vip-consultation.entity';
import { VipTrip } from './vip-trip.entity';
import {
  assertTripTransition,
  consultationPriceId,
  coordinationPriceId,
  effectiveSessionStatus,
  remainingSeconds,
  type TripStatus,
} from './vip';

@Injectable()
export class VipService {
  constructor(
    @InjectRepository(VipTrip)
    private readonly trips: Repository<VipTrip>,
    @InjectRepository(VipConsultation)
    private readonly sessions: Repository<VipConsultation>,
    @InjectRepository(Conversation)
    private readonly conversations: Repository<Conversation>,
    @InjectRepository(ConversationParticipant)
    private readonly participants: Repository<ConversationParticipant>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
    private readonly prices: PricesService,
  ) {}

  // -------------------------------------------------------- consultations

  async createConsultation(actor: AuthUser, dto: CreateConsultationDto) {
    const priceId = consultationPriceId(dto.minutes);
    if (!priceId) throw new BadRequestException('Unknown consultation length');
    const { lines, missing } = await this.prices.activeLinesByPriceIds([priceId]);
    if (missing.length > 0) {
      throw new BadRequestException(
        'Consultation prices are not published yet. Our team has not activated them; please try again later.',
      );
    }
    const session = await this.sessions.save(
      this.sessions.create({
        userId: actor.userId,
        minutes: dto.minutes,
        priceId,
        priceSnapshot: { ...lines[0], currency: 'USD' },
        status: 'PENDING_PAYMENT',
        paidReference: null,
        staffUserId: null,
        startedAt: null,
        endsAt: null,
        endedAt: null,
      }),
    );
    return this.sessionDto(session);
  }

  async myConsultations(actor: AuthUser) {
    const rows = await this.sessions.find({
      where: { userId: actor.userId },
      order: { createdAt: 'DESC' },
      take: 100,
    });
    const out = [];
    for (const row of rows) out.push(await this.sessionDto(row));
    return { rows: out };
  }

  async getConsultation(actor: AuthUser, id: string) {
    const session = await this.loadSession(id);
    this.assertSessionAccess(actor, session);
    return this.sessionDto(session);
  }

  async startConsultation(actor: AuthUser, id: string) {
    const session = await this.loadSession(id);
    this.assertSessionAccess(actor, session);
    if (session.status !== 'READY') {
      throw new BadRequestException(
        session.status === 'PENDING_PAYMENT'
          ? 'This consultation is waiting for payment'
          : 'This consultation cannot be started now',
      );
    }
    const now = new Date();
    session.status = 'ACTIVE';
    session.startedAt = now;
    session.endsAt = new Date(now.getTime() + session.minutes * 60_000);
    return this.sessionDto(await this.sessions.save(session));
  }

  async endConsultation(actor: AuthUser, id: string) {
    const session = await this.loadSession(id);
    this.assertSessionAccess(actor, session);
    if (session.status !== 'ACTIVE') {
      throw new BadRequestException('This consultation is not running');
    }
    session.status = 'ENDED';
    session.endedAt = new Date();
    return this.sessionDto(await this.sessions.save(session));
  }

  async cancelConsultation(actor: AuthUser, id: string) {
    const session = await this.loadSession(id);
    if (session.userId !== actor.userId && actor.role !== UserRole.SuperAdmin) {
      throw new ForbiddenException('This consultation belongs to another customer');
    }
    if (session.status === 'ENDED' || session.status === 'CANCELLED') {
      throw new BadRequestException('This consultation is already closed');
    }
    session.status = 'CANCELLED';
    session.endedAt = new Date();
    return this.sessionDto(await this.sessions.save(session));
  }

  async adminMarkConsultationPaid(
    actor: AuthUser,
    id: string,
    dto: MarkPaidDto,
  ) {
    const session = await this.loadSession(id);
    if (session.status !== 'PENDING_PAYMENT') {
      throw new BadRequestException('This consultation is not waiting for payment');
    }
    session.status = 'READY';
    session.paidReference = dto.reference.trim();
    const saved = await this.sessions.save(session);
    await this.audit(actor.userId, 'vip_consultation_paid', saved.id, {
      reference: saved.paidReference,
    });
    return this.sessionDto(saved);
  }

  async adminConsultations() {
    const rows = await this.sessions.find({
      order: { createdAt: 'DESC' },
      take: 200,
    });
    const out = [];
    for (const row of rows) out.push(await this.sessionDto(row));
    return { rows: out };
  }

  // ---------------------------------------------------------------- trips

  async createTrip(actor: AuthUser, dto: CreateTripDto) {
    const cities = dto.cities.map((c) => c.trim()).filter(Boolean);
    if (cities.length === 0) {
      throw new BadRequestException('Choose at least one city');
    }
    const trip = await this.trips.save(
      this.trips.create({
        userId: actor.userId,
        trackingId: await this.newTrackingId(),
        purpose: dto.purpose,
        cities,
        days: dto.days,
        people: dto.people ?? 1,
        budgetCents: dto.budgetCents ?? null,
        status: 'DRAFT',
        quotation: null,
        quotationVersion: 0,
        acceptedAt: null,
        paidReference: null,
        groupConversationId: null,
        assignedEmployeeId: null,
        notes: dto.notes?.trim() ? dto.notes.trim() : null,
      }),
    );
    return trip;
  }

  async myTrips(actor: AuthUser) {
    const rows = await this.trips.find({
      where: { userId: actor.userId },
      order: { createdAt: 'DESC' },
      take: 100,
    });
    return { rows };
  }

  async getTrip(actor: AuthUser, id: string) {
    const trip = await this.loadTrip(id);
    this.assertTripAccess(actor, trip);
    return trip;
  }

  async quoteTrip(actor: AuthUser, id: string, dto: QuoteTripDto) {
    const trip = await this.loadTrip(id);
    if (trip.userId !== actor.userId && actor.role !== UserRole.SuperAdmin) {
      // Staff may also prepare a quotation for the customer.
      if (actor.role !== UserRole.Employee) {
        throw new ForbiddenException('This trip belongs to another customer');
      }
    }
    if (trip.status !== 'DRAFT' && trip.status !== 'QUOTED' && trip.status !== 'ACCEPTED') {
      throw new BadRequestException('This trip can no longer be quoted');
    }
    const coordPriceId = coordinationPriceId(trip.days);
    if (!coordPriceId) {
      throw new BadRequestException(
        'There is no approved coordination fee for this many days yet. Our team must approve a rule first — the fee is never guessed.',
      );
    }
    const priceIds = [coordPriceId, ...(dto.addonPriceIds ?? [])];
    const { lines, missing } = await this.prices.activeLinesByPriceIds(priceIds);
    if (missing.length > 0) {
      throw new BadRequestException(
        'Some prices for this trip are not published yet. Our team has not activated them; please try again later.',
      );
    }
    const totals = computeQuoteTotals(lines);
    trip.quotationVersion += 1;
    trip.quotation = {
      currency: 'CNY',
      lines,
      totals,
      version: trip.quotationVersion,
      frozenAt: new Date().toISOString(),
    };
    // A materially new quotation always needs fresh customer acceptance.
    trip.acceptedAt = null;
    this.transition(trip, 'QUOTED', { allowSame: true });
    const saved = await this.trips.save(trip);
    await this.audit(actor.userId, 'vip_trip_quote', saved.id, {
      version: saved.quotationVersion,
      totalCents: totals.totalCents,
    });
    return saved;
  }

  async acceptTrip(actor: AuthUser, id: string) {
    const trip = await this.loadTrip(id);
    if (trip.userId !== actor.userId) {
      throw new ForbiddenException('This trip belongs to another customer');
    }
    this.transition(trip, 'ACCEPTED');
    trip.acceptedAt = new Date();
    return this.trips.save(trip);
  }

  async cancelTrip(actor: AuthUser, id: string) {
    const trip = await this.loadTrip(id);
    if (trip.userId !== actor.userId && actor.role !== UserRole.SuperAdmin) {
      throw new ForbiddenException('This trip belongs to another customer');
    }
    this.transition(trip, 'CANCELLED');
    return this.trips.save(trip);
  }

  async adminTrips(status?: string) {
    const rows = await this.trips.find({
      where: status ? { status: status as TripStatus } : {},
      order: { updatedAt: 'DESC' },
      take: 200,
    });
    return { rows };
  }

  async adminAssignTrip(actor: AuthUser, id: string, dto: AssignVipDto) {
    const trip = await this.loadTrip(id);
    trip.assignedEmployeeId = dto.employeeId;
    const saved = await this.trips.save(trip);
    await this.audit(actor.userId, 'vip_trip_assign', saved.id, {
      employeeId: dto.employeeId,
    });
    return saved;
  }

  async adminMarkTripPaid(actor: AuthUser, id: string, dto: MarkPaidDto) {
    const trip = await this.loadTrip(id);
    if (trip.status !== 'ACCEPTED') {
      throw new BadRequestException(
        'The customer must accept the quotation before payment is recorded',
      );
    }
    trip.paidReference = dto.reference.trim();
    const saved = await this.trips.save(trip);
    await this.audit(actor.userId, 'vip_trip_paid', saved.id, {
      reference: saved.paidReference,
    });
    return saved;
  }

  async adminTransitionTrip(actor: AuthUser, id: string, dto: TransitionTripDto) {
    const trip = await this.loadTrip(id);
    if (dto.status === 'GROUP_CREATED') {
      throw new BadRequestException('Use create-group so the roster is recorded');
    }
    this.transition(trip, dto.status);
    return this.trips.save(trip);
  }

  /**
   * VIP-001: after acceptance + recorded payment, create the official
   * group with the standing roster. Unlike customer groups, membership is
   * by staff roster — the friend-only rule does not apply here.
   */
  async adminCreateGroup(actor: AuthUser, id: string, dto: CreateGroupDto) {
    const trip = await this.loadTrip(id);
    if (trip.groupConversationId) {
      throw new ConflictException('The official group already exists');
    }
    if (trip.status !== 'ACCEPTED' || !trip.paidReference) {
      throw new BadRequestException(
        'The official group is created after the customer accepts and payment is recorded',
      );
    }
    const memberIds = [...new Set([trip.userId, ...dto.memberUserIds])];
    if (memberIds.length < 2) {
      throw new BadRequestException('The group needs the customer plus staff');
    }
    for (const memberId of memberIds) {
      const user = await this.users.findOne({ where: { id: memberId } });
      if (!user) throw new NotFoundException(`Member not found: ${memberId}`);
    }
    const customer = await this.users.findOne({ where: { id: trip.userId } });
    const title =
      dto.title?.trim() ||
      `VIP ${trip.trackingId} — ${customer?.name ?? 'Customer'}`;
    const conv = await this.conversations.save(
      this.conversations.create({
        kind: ConversationKind.Group,
        title: title.slice(0, 120),
      }),
    );
    await this.participants.save(
      memberIds.map((userId) =>
        this.participants.create({ conversationId: conv.id, userId }),
      ),
    );
    this.transition(trip, 'GROUP_CREATED');
    trip.groupConversationId = conv.id;
    const saved = await this.trips.save(trip);
    await this.audit(actor.userId, 'vip_trip_group_created', saved.id, {
      conversationId: conv.id,
      members: memberIds.length,
    });
    return saved;
  }

  // -------------------------------------------------------------- helpers

  private transition(trip: VipTrip, to: TripStatus, opts?: { allowSame?: boolean }): void {
    if (opts?.allowSame && trip.status === to) return;
    try {
      assertTripTransition(trip.status, to);
    } catch {
      throw new BadRequestException(
        `Cannot move a trip from ${trip.status} to ${to}`,
      );
    }
    trip.status = to;
  }

  private async sessionDto(session: VipConsultation) {
    // Hard stop: an ACTIVE session past its end reads as ENDED everywhere.
    const effective = effectiveSessionStatus(session, new Date());
    if (effective !== session.status) {
      session.status = effective;
      session.endedAt = session.endsAt;
      await this.sessions.save(session);
    }
    return {
      id: session.id,
      userId: session.userId,
      minutes: session.minutes,
      priceId: session.priceId,
      priceSnapshot: session.priceSnapshot,
      status: session.status,
      paidReference: session.paidReference,
      staffUserId: session.staffUserId,
      startedAt: session.startedAt,
      endsAt: session.endsAt,
      endedAt: session.endedAt,
      remainingSeconds: remainingSeconds(session, new Date()),
      createdAt: session.createdAt,
    };
  }

  private async loadSession(id: string): Promise<VipConsultation> {
    const session = await this.sessions.findOne({ where: { id } });
    if (!session) throw new NotFoundException('This consultation was not found');
    return session;
  }

  private async loadTrip(id: string): Promise<VipTrip> {
    const trip = await this.trips.findOne({ where: { id } });
    if (!trip) throw new NotFoundException('This trip was not found');
    return trip;
  }

  private assertSessionAccess(actor: AuthUser, session: VipConsultation): void {
    if (session.userId === actor.userId) return;
    if (actor.role === UserRole.Employee || actor.role === UserRole.SuperAdmin) return;
    throw new ForbiddenException('This consultation belongs to another customer');
  }

  private assertTripAccess(actor: AuthUser, trip: VipTrip): void {
    if (trip.userId === actor.userId) return;
    if (actor.role === UserRole.Employee || actor.role === UserRole.SuperAdmin) return;
    throw new ForbiddenException('This trip belongs to another customer');
  }

  private async newTrackingId(): Promise<string> {
    const year = new Date().getFullYear();
    for (let attempt = 0; attempt < 8; attempt += 1) {
      const suffix = Math.floor(100000 + Math.random() * 900000);
      const candidate = `OBIC-VIP-${year}-${suffix}`;
      const exists = await this.trips.findOne({
        where: { trackingId: candidate },
      });
      if (!exists) return candidate;
    }
    throw new ConflictException('Could not allocate a tracking ID');
  }

  private async audit(
    actorId: string,
    action: string,
    resourceId: string,
    meta: Record<string, unknown>,
  ): Promise<void> {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action,
        resourceType: 'vip',
        resourceId,
        meta,
      }),
    );
  }
}
