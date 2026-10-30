// Made by Dr Ali

import {
  allowedRegistrationTransitions,
  buildChecklist,
  docStatusColor,
  isTerminalRegistrationStatus,
  mandatoryBasketPriceIds,
  resolveEligibility,
  type EligibilityRuleLike,
} from './registration';

describe('registration state machine (boss 10 states)', () => {
  it('allows the happy path DRAFT → … → COMPLETED', () => {
    expect(allowedRegistrationTransitions('DRAFT')).toContain('SUBMITTED');
    expect(allowedRegistrationTransitions('SUBMITTED')).toContain('UNDER_REVIEW');
    expect(allowedRegistrationTransitions('UNDER_REVIEW')).toContain('APPROVED');
    expect(allowedRegistrationTransitions('APPROVED')).toContain('IN_PROGRESS');
    expect(allowedRegistrationTransitions('IN_PROGRESS')).toContain('COMPLETED');
  });

  it('routes missing documents and corrections through customer action', () => {
    expect(allowedRegistrationTransitions('SUBMITTED')).toContain('PENDING_DOCUMENTS');
    expect(allowedRegistrationTransitions('UNDER_REVIEW')).toContain('NEEDS_CUSTOMER_ACTION');
    expect(allowedRegistrationTransitions('NEEDS_CUSTOMER_ACTION')).toContain('UNDER_REVIEW');
  });

  it('terminal states have no exits', () => {
    for (const state of ['REJECTED', 'COMPLETED', 'CANCELLED'] as const) {
      expect(allowedRegistrationTransitions(state)).toEqual([]);
      expect(isTerminalRegistrationStatus(state)).toBe(true);
    }
    expect(isTerminalRegistrationStatus('UNDER_REVIEW')).toBe(false);
  });

  it('never allows skipping review (DRAFT → APPROVED)', () => {
    expect(allowedRegistrationTransitions('DRAFT')).not.toContain('APPROVED');
    expect(allowedRegistrationTransitions('DRAFT')).not.toContain('IN_PROGRESS');
  });
});

describe('document colours (boss §4)', () => {
  it('maps statuses to Green / Yellow / Red', () => {
    expect(docStatusColor('approved')).toBe('Green');
    expect(docStatusColor('blocked')).toBe('Red');
    expect(docStatusColor('missing')).toBe('Yellow');
    expect(docStatusColor('pending')).toBe('Yellow');
    expect(docStatusColor('correction_requested')).toBe('Yellow');
  });
});

describe('checklist', () => {
  it('requires a residence permit only when inside China', () => {
    const inside = buildChecklist(true);
    const outside = buildChecklist(false);
    const insidePermit = inside.find((d) => d.docType === 'residence_permit');
    const outsidePermit = outside.find((d) => d.docType === 'residence_permit');
    expect(insidePermit?.required).toBe(true);
    expect(outsidePermit?.required).toBe(false);
    expect(inside.find((d) => d.docType === 'passport')?.required).toBe(true);
  });
});

describe('eligibility resolution', () => {
  const rules: EligibilityRuleLike[] = [
    {
      city: 'Yiwu',
      activity: 'trading',
      nationality: null,
      insideChina: null,
      outcome: 'eligible',
      reason: 'Approved for trading companies',
      alternativeCities: null,
      version: 'rules-v1',
    },
    {
      city: 'Beijing',
      activity: 'trading',
      nationality: 'Exampleland',
      insideChina: null,
      outcome: 'ineligible',
      reason: 'Not approved for this nationality/activity',
      alternativeCities: ['Yiwu', 'Foshan'],
      version: 'rules-v1',
    },
  ];

  it('returns eligible for an approved rule', () => {
    const result = resolveEligibility(rules, {
      city: 'yiwu',
      activity: 'Trading',
      nationality: 'Any',
      insideChina: false,
    });
    expect(result.outcome).toBe('eligible');
    expect(result.ruleVersion).toBe('rules-v1');
  });

  it('returns alternatives for an ineligible rule', () => {
    const result = resolveEligibility(rules, {
      city: 'Beijing',
      activity: 'trading',
      nationality: 'Exampleland',
      insideChina: true,
    });
    expect(result.outcome).toBe('ineligible');
    expect(result.alternativeCities).toEqual(['Yiwu', 'Foshan']);
  });

  it('never invents a rule: unknown city stays to_be_verified', () => {
    const result = resolveEligibility(rules, {
      city: 'Dongguan',
      activity: 'trading',
      nationality: 'Any',
      insideChina: true,
    });
    expect(result.outcome).toBe('to_be_verified');
    expect(result.ruleVersion).toBeNull();
  });
});

describe('mandatory checkout basket (boss §7.4)', () => {
  it('builds REG + CONSULT + the customer-chosen accountant tier', () => {
    expect(mandatoryBasketPriceIds('Yiwu', 'no_tax')).toEqual([
      'PRICE-YIW-REG',
      'PRICE-YIW-CONSULT',
      'PRICE-YIW-ACC-NOTAX',
    ]);
    expect(mandatoryBasketPriceIds('Beijing', 'tax_lt20')).toEqual([
      'PRICE-BJS-REG',
      'PRICE-BJS-CONSULT',
      'PRICE-BJS-ACC-TAX-LT20',
    ]);
    expect(mandatoryBasketPriceIds('Guangzhou', 'tax_20_50')).toEqual([
      'PRICE-GZH-REG',
      'PRICE-GZH-CONSULT',
      'PRICE-GZH-ACC-TAX-20-50',
    ]);
  });

  it('has no basket for a city without an approved price matrix', () => {
    expect(mandatoryBasketPriceIds('Dongguan', 'no_tax')).toBeNull();
  });
});
