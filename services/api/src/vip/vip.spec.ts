// Made by Dr Ali

import {
  allowedTripTransitions,
  consultationPriceId,
  coordinationPriceId,
  effectiveSessionStatus,
  remainingSeconds,
} from './vip';

describe('VIP — two separate products (C7)', () => {
  it('consultations map minutes to USD product PriceIDs', () => {
    expect(consultationPriceId(10)).toBe('PRICE-VIP-CONSULT-10');
    expect(consultationPriceId(60)).toBe('PRICE-VIP-CONSULT-60');
    expect(consultationPriceId(15)).toBeNull();
  });

  it('coordination fee exists only for approved exact durations', () => {
    expect(coordinationPriceId(5)).toBe('PRICE-VIP-TRIP-5D');
    expect(coordinationPriceId(60)).toBe('PRICE-VIP-TRIP-60D');
    // Unlisted durations are never interpolated (VIP-OD-003 open).
    expect(coordinationPriceId(7)).toBeNull();
    expect(coordinationPriceId(45)).toBeNull();
  });
});

describe('consultation hard stop (boss §9)', () => {
  const started = new Date('2026-10-22T00:00:00Z');
  const ends = new Date(started.getTime() + 10 * 60_000);

  it('counts down remaining seconds and never goes negative', () => {
    expect(
      remainingSeconds(
        { status: 'ACTIVE', endsAt: ends, minutes: 10 },
        new Date(started.getTime() + 60_000),
      ),
    ).toBe(540);
    expect(
      remainingSeconds(
        { status: 'ACTIVE', endsAt: ends, minutes: 10 },
        new Date(ends.getTime() + 5_000),
      ),
    ).toBe(0);
  });

  it('an ACTIVE session past its end is ENDED — no auto-extension', () => {
    expect(
      effectiveSessionStatus(
        { status: 'ACTIVE', endsAt: ends },
        new Date(ends.getTime() + 1),
      ),
    ).toBe('ENDED');
    expect(
      effectiveSessionStatus(
        { status: 'ACTIVE', endsAt: ends },
        new Date(ends.getTime() - 1),
      ),
    ).toBe('ACTIVE');
  });
});

describe('trip workflow', () => {
  it('follows DRAFT → QUOTED → ACCEPTED → GROUP_CREATED → IN_PROGRESS → COMPLETED', () => {
    expect(allowedTripTransitions('DRAFT')).toContain('QUOTED');
    expect(allowedTripTransitions('QUOTED')).toContain('ACCEPTED');
    expect(allowedTripTransitions('ACCEPTED')).toContain('GROUP_CREATED');
    expect(allowedTripTransitions('GROUP_CREATED')).toContain('IN_PROGRESS');
    expect(allowedTripTransitions('IN_PROGRESS')).toContain('COMPLETED');
    expect(allowedTripTransitions('DRAFT')).not.toContain('ACCEPTED');
    expect(allowedTripTransitions('COMPLETED')).toEqual([]);
  });

  it('a re-quote after acceptance returns the trip to QUOTED', () => {
    expect(allowedTripTransitions('ACCEPTED')).toContain('QUOTED');
  });
});
