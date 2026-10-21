// Made by Dr Ali
// VIP rules — two SEPARATE products (boss Master Handoff §9 + VIP Spec §2):
// (a) timed consultations in USD, hard stop, no auto-extension;
// (b) trip coordination in CNY by exact duration table.
// Unlisted durations have NO price — nobody may interpolate (VIP-OD-003 open).

export const CONSULTATION_OPTIONS = [
  { minutes: 10, priceId: 'PRICE-VIP-CONSULT-10' },
  { minutes: 20, priceId: 'PRICE-VIP-CONSULT-20' },
  { minutes: 30, priceId: 'PRICE-VIP-CONSULT-30' },
  { minutes: 60, priceId: 'PRICE-VIP-CONSULT-60' },
] as const;

export function consultationPriceId(minutes: number): string | null {
  return (
    CONSULTATION_OPTIONS.find((o) => o.minutes === minutes)?.priceId ?? null
  );
}

/** Approved coordination fees: exact days → PriceID. Anything else = null. */
export const COORDINATION_DAYS = [5, 10, 15, 20, 30, 60] as const;

export function coordinationPriceId(days: number): string | null {
  return (COORDINATION_DAYS as readonly number[]).includes(days)
    ? `PRICE-VIP-TRIP-${days}D`
    : null;
}

export const TRIP_PURPOSES = ['BIZ', 'TOUR', 'MED', 'STU', 'INV', 'MIX'] as const;
export type TripPurpose = (typeof TRIP_PURPOSES)[number];

export const TRIP_STATUSES = [
  'DRAFT',
  'QUOTED',
  'ACCEPTED',
  'GROUP_CREATED',
  'IN_PROGRESS',
  'COMPLETED',
  'CANCELLED',
] as const;
export type TripStatus = (typeof TRIP_STATUSES)[number];

export function allowedTripTransitions(from: TripStatus): TripStatus[] {
  switch (from) {
    case 'DRAFT':
      return ['QUOTED', 'CANCELLED'];
    case 'QUOTED':
      return ['ACCEPTED', 'DRAFT', 'CANCELLED'];
    case 'ACCEPTED':
      return ['GROUP_CREATED', 'QUOTED', 'CANCELLED'];
    case 'GROUP_CREATED':
      return ['IN_PROGRESS', 'CANCELLED'];
    case 'IN_PROGRESS':
      return ['COMPLETED', 'CANCELLED'];
    case 'COMPLETED':
      return [];
    case 'CANCELLED':
      return [];
    default: {
      const neverStatus: never = from;
      throw new Error(neverStatus);
    }
  }
}

export function assertTripTransition(from: TripStatus, to: TripStatus): void {
  if (!allowedTripTransitions(from).includes(to)) {
    throw new Error('VIP_TRIP_TRANSITION');
  }
}

export const SESSION_STATUSES = [
  'PENDING_PAYMENT',
  'READY',
  'ACTIVE',
  'ENDED',
  'CANCELLED',
] as const;
export type SessionStatus = (typeof SESSION_STATUSES)[number];

/** Seconds left in a live consultation; never negative, never extended. */
export function remainingSeconds(input: {
  status: SessionStatus;
  endsAt: Date | null;
  minutes: number;
}, now: Date): number {
  switch (input.status) {
    case 'ACTIVE':
      if (!input.endsAt) return 0;
      return Math.max(
        0,
        Math.floor((input.endsAt.getTime() - now.getTime()) / 1000),
      );
    case 'READY':
      return input.minutes * 60;
    case 'PENDING_PAYMENT':
    case 'ENDED':
    case 'CANCELLED':
      return 0;
    default: {
      const neverStatus: never = input.status;
      throw new Error(neverStatus);
    }
  }
}

/** An ACTIVE session past its end time is ENDED — the hard stop (boss §9). */
export function effectiveSessionStatus(input: {
  status: SessionStatus;
  endsAt: Date | null;
}, now: Date): SessionStatus {
  if (
    input.status === 'ACTIVE' &&
    input.endsAt &&
    input.endsAt.getTime() <= now.getTime()
  ) {
    return 'ENDED';
  }
  return input.status;
}
