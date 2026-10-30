// Made by Dr Ali

import {
  allowedPriceTransitions,
  assertActivatable,
  assertPriceTransition,
  computeQuoteTotals,
} from './price';

describe('price workflow', () => {
  it('follows Draft → Review → Approved → Active → Retired', () => {
    expect(allowedPriceTransitions('Draft')).toContain('Review');
    expect(allowedPriceTransitions('Review')).toContain('Approved');
    expect(allowedPriceTransitions('Approved')).toContain('Active');
    expect(allowedPriceTransitions('Active')).toEqual(['Retired']);
    expect(allowedPriceTransitions('Retired')).toEqual([]);
    expect(() => assertPriceTransition('Draft', 'Active')).toThrow(
      'PRICE_TRANSITION',
    );
    expect(() => assertPriceTransition('Review', 'Approved')).not.toThrow();
  });

  it('needs an effective date and approver to go active', () => {
    expect(() =>
      assertActivatable({ effectiveFrom: null, approverId: 'u1' }),
    ).toThrow('PRICE_ACTIVATION');
    expect(() =>
      assertActivatable({ effectiveFrom: '2026-11-01', approverId: null }),
    ).toThrow('PRICE_ACTIVATION');
    expect(() =>
      assertActivatable({ effectiveFrom: '2026-11-01', approverId: 'u1' }),
    ).not.toThrow();
  });
});

describe('computeQuoteTotals', () => {
  it('separates OBIC fees from external fees and totals in cents', () => {
    // Yiwu mandatory basket: registration ¥500 + consulting ¥3,000 + accountant ¥3,600.
    const totals = computeQuoteTotals([
      { priceId: 'PRICE-YIW-REG', version: 'v1', obicFeeCents: 50000, externalFeeCents: 0 },
      { priceId: 'PRICE-YIW-CONSULT', version: 'v1', obicFeeCents: 300000, externalFeeCents: 0 },
      { priceId: 'PRICE-YIW-ACC-NOTAX', version: 'v1', obicFeeCents: 360000, externalFeeCents: 20000 },
    ]);
    expect(totals.obicFeeCents).toBe(710000);
    expect(totals.externalFeeCents).toBe(20000);
    expect(totals.totalCents).toBe(730000);
  });

  it('rejects a discount larger than the quote and negative cents', () => {
    expect(() =>
      computeQuoteTotals(
        [{ priceId: 'P', version: 'v1', obicFeeCents: 100, externalFeeCents: 0 }],
        101,
      ),
    ).toThrow('PRICE_DISCOUNT');
    expect(() =>
      computeQuoteTotals([
        { priceId: 'P', version: 'v1', obicFeeCents: -1, externalFeeCents: 0 },
      ]),
    ).toThrow('PRICE_AMOUNT');
  });
});
