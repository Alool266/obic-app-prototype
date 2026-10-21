// Made by Dr Ali
// Versioned price rules (boss M02/M15, Oct 2026). Prices are configuration,
// never hard-coded in clients. A price is only customer-visible when Active.

export const PRICE_STATUSES = [
  'Draft',
  'Review',
  'Approved',
  'Active',
  'Retired',
] as const;
export type PriceStatus = (typeof PRICE_STATUSES)[number];

export const PRICING_BASES = [
  'per_order',
  'per_year',
  'per_document',
  'per_job',
  'percentage_of_annual_rent',
] as const;
export type PricingBasis = (typeof PRICING_BASES)[number];

export function isPriceStatus(value: string): value is PriceStatus {
  return (PRICE_STATUSES as readonly string[]).includes(value);
}

export function isPricingBasis(value: string): value is PricingBasis {
  return (PRICING_BASES as readonly string[]).includes(value);
}

/** Boss workflow: Draft → Review → Approved → Active → Retired. */
export function allowedPriceTransitions(from: PriceStatus): PriceStatus[] {
  switch (from) {
    case 'Draft':
      return ['Review', 'Retired'];
    case 'Review':
      return ['Approved', 'Draft', 'Retired'];
    case 'Approved':
      return ['Active', 'Retired'];
    case 'Active':
      return ['Retired'];
    case 'Retired':
      return [];
    default: {
      const neverStatus: never = from;
      throw new Error(neverStatus);
    }
  }
}

export function assertPriceTransition(from: PriceStatus, to: PriceStatus): void {
  if (!allowedPriceTransitions(from).includes(to)) {
    throw new Error('PRICE_TRANSITION');
  }
}

/** Activating a price requires an effective date and a recorded approver. */
export function assertActivatable(input: {
  effectiveFrom: string | null;
  approverId: string | null;
}): void {
  if (!input.effectiveFrom || !input.approverId) {
    throw new Error('PRICE_ACTIVATION');
  }
}

export type QuoteLine = {
  priceId: string;
  version: string;
  obicFeeCents: number;
  externalFeeCents: number;
};

export type QuoteTotals = {
  obicFeeCents: number;
  externalFeeCents: number;
  discountCents: number;
  taxCents: number;
  totalCents: number;
};

function assertCents(value: number): void {
  if (!Number.isInteger(value) || value < 0) throw new Error('PRICE_AMOUNT');
}

export function computeQuoteTotals(
  lines: readonly QuoteLine[],
  discountCents = 0,
  taxCents = 0,
): QuoteTotals {
  let obicFeeCents = 0;
  let externalFeeCents = 0;
  for (const line of lines) {
    assertCents(line.obicFeeCents);
    assertCents(line.externalFeeCents);
    obicFeeCents += line.obicFeeCents;
    externalFeeCents += line.externalFeeCents;
  }
  assertCents(discountCents);
  assertCents(taxCents);
  if (discountCents > obicFeeCents + externalFeeCents) {
    throw new Error('PRICE_DISCOUNT');
  }
  return {
    obicFeeCents,
    externalFeeCents,
    discountCents,
    taxCents,
    totalCents: obicFeeCents + externalFeeCents - discountCents + taxCents,
  };
}
