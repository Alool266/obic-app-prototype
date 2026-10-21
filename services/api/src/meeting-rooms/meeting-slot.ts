// Made by Dr Ali
// A room booking is a half-open window: the end of one meeting can be the start of the next.

export type BookingWindow = {
  start: Date;
  end: Date;
};

export function bookingsOverlap(left: BookingWindow, right: BookingWindow): boolean {
  return left.start < right.end && right.start < left.end;
}

/** 15 minutes through 8 hours, starting no earlier than now and within 30 days. */
export function assertBookingWindow(input: BookingWindow & { now: Date }): void {
  if (!(input.start < input.end)) {
    throw new Error('BOOKING_RANGE');
  }
  const minutes = (input.end.getTime() - input.start.getTime()) / 60_000;
  if (minutes < 15 || minutes > 8 * 60) {
    throw new Error('BOOKING_LENGTH');
  }
  if (input.start.getTime() < input.now.getTime() - 60_000) {
    throw new Error('BOOKING_PAST');
  }
  const horizon = input.now.getTime() + 30 * 24 * 60 * 60 * 1000;
  if (input.start.getTime() > horizon) {
    throw new Error('BOOKING_HORIZON');
  }
}
