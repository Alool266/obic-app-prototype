// Made by Dr Ali
// Company Registration (Non-VIP) workflow rules — boss workflow UPDATED §§1,3,4,7
// and Master Handoff §10: the server state machine is the source of truth;
// Green/Yellow/Red are display colours derived from document status.
// Unconfirmed boss items are deliberately NOT encoded here: Dongguan price
// (C1), the Yemeni passport-authentication fee (NV-002), discount tiers (OD-03).

export const REGISTRATION_STATUSES = [
  'DRAFT',
  'SUBMITTED',
  'PENDING_DOCUMENTS',
  'UNDER_REVIEW',
  'NEEDS_CUSTOMER_ACTION',
  'APPROVED',
  'REJECTED',
  'IN_PROGRESS',
  'COMPLETED',
  'CANCELLED',
] as const;
export type RegistrationStatus = (typeof REGISTRATION_STATUSES)[number];

export function isRegistrationStatus(
  value: string,
): value is RegistrationStatus {
  return (REGISTRATION_STATUSES as readonly string[]).includes(value);
}

/** Boss 10-state machine (Master Handoff §10). */
export function allowedRegistrationTransitions(
  from: RegistrationStatus,
): RegistrationStatus[] {
  switch (from) {
    case 'DRAFT':
      return ['SUBMITTED', 'CANCELLED'];
    case 'SUBMITTED':
      return ['PENDING_DOCUMENTS', 'UNDER_REVIEW', 'CANCELLED'];
    case 'PENDING_DOCUMENTS':
      return ['UNDER_REVIEW', 'NEEDS_CUSTOMER_ACTION', 'CANCELLED'];
    case 'UNDER_REVIEW':
      return ['APPROVED', 'REJECTED', 'NEEDS_CUSTOMER_ACTION', 'CANCELLED'];
    case 'NEEDS_CUSTOMER_ACTION':
      return ['UNDER_REVIEW', 'PENDING_DOCUMENTS', 'CANCELLED'];
    case 'APPROVED':
      return ['IN_PROGRESS', 'CANCELLED'];
    case 'IN_PROGRESS':
      return ['COMPLETED', 'CANCELLED'];
    case 'REJECTED':
      return [];
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

export function assertRegistrationTransition(
  from: RegistrationStatus,
  to: RegistrationStatus,
): void {
  if (!allowedRegistrationTransitions(from).includes(to)) {
    throw new Error('REGISTRATION_TRANSITION');
  }
}

export function isTerminalRegistrationStatus(
  status: RegistrationStatus,
): boolean {
  switch (status) {
    case 'REJECTED':
    case 'COMPLETED':
    case 'CANCELLED':
      return true;
    case 'DRAFT':
    case 'SUBMITTED':
    case 'PENDING_DOCUMENTS':
    case 'UNDER_REVIEW':
    case 'NEEDS_CUSTOMER_ACTION':
    case 'APPROVED':
    case 'IN_PROGRESS':
      return false;
    default: {
      const neverStatus: never = status;
      throw new Error(neverStatus);
    }
  }
}

// ---------------------------------------------------------------- documents

export const REGISTRATION_DOC_TYPES = [
  'passport',
  'photo',
  'qualification',
  'criminal_record',
  'residence_permit',
  'entry_stamp',
  'experience_cert',
  'other',
] as const;
export type RegistrationDocType = (typeof REGISTRATION_DOC_TYPES)[number];

export const REGISTRATION_DOC_STATUSES = [
  'missing',
  'pending',
  'approved',
  'correction_requested',
  'blocked',
] as const;
export type RegistrationDocStatus = (typeof REGISTRATION_DOC_STATUSES)[number];

/** Boss §4: Green = proceed, Yellow = pending/missing, Red = blocked. */
export function docStatusColor(status: RegistrationDocStatus): string {
  switch (status) {
    case 'approved':
      return 'Green';
    case 'blocked':
      return 'Red';
    case 'missing':
    case 'pending':
    case 'correction_requested':
      return 'Yellow';
    default: {
      const neverStatus: never = status;
      throw new Error(neverStatus);
    }
  }
}

export type ChecklistItem = {
  docType: RegistrationDocType;
  label: string;
  required: boolean;
};

/**
 * Document checklist (boss workflow §§2–3 shared collection). Whether a
 * residence permit applies depends on the inside/outside-China answer;
 * entry stamp and experience certificate are collected when available /
 * required by the approved city policy, so they start optional here.
 */
export function buildChecklist(insideChina: boolean): ChecklistItem[] {
  return [
    { docType: 'passport', label: 'Passport', required: true },
    {
      docType: 'photo',
      label: 'White-background 4x6 photo',
      required: true,
    },
    {
      docType: 'qualification',
      label: 'Latest academic qualification',
      required: true,
    },
    {
      docType: 'criminal_record',
      label: 'Criminal-record certificate',
      required: true,
    },
    {
      docType: 'residence_permit',
      label: 'Residence permit',
      required: insideChina,
    },
    { docType: 'entry_stamp', label: 'Entry stamp', required: false },
    {
      docType: 'experience_cert',
      label: 'Experience certificate',
      required: false,
    },
  ];
}

// -------------------------------------------------------------- eligibility

export const ELIGIBILITY_OUTCOMES = [
  'eligible',
  'ineligible',
  'to_be_verified',
] as const;
export type EligibilityOutcome = (typeof ELIGIBILITY_OUTCOMES)[number];

export type EligibilityRuleLike = {
  city: string;
  activity: string;
  nationality: string | null;
  insideChina: boolean | null;
  outcome: 'eligible' | 'ineligible';
  reason: string | null;
  alternativeCities: string[] | null;
  version: string;
};

export type EligibilityResult = {
  outcome: EligibilityOutcome;
  reason: string | null;
  alternativeCities: string[];
  ruleVersion: string | null;
};

function norm(value: string): string {
  return value.trim().toLowerCase();
}

/**
 * Resolve eligibility from human-approved Active rules only. No matching
 * rule means "to_be_verified" — the system never invents city/legal rules
 * (boss workflow §6, Master Handoff: AI does not invent rules).
 */
export function resolveEligibility(
  rules: readonly EligibilityRuleLike[],
  input: {
    city: string;
    activity: string;
    nationality?: string | null;
    insideChina: boolean;
  },
): EligibilityResult {
  const matches = rules.filter((rule) => {
    if (norm(rule.city) !== norm(input.city)) return false;
    if (norm(rule.activity) !== norm(input.activity)) return false;
    if (
      rule.nationality &&
      (!input.nationality || norm(rule.nationality) !== norm(input.nationality))
    ) {
      return false;
    }
    if (rule.insideChina !== null && rule.insideChina !== input.insideChina) {
      return false;
    }
    return true;
  });
  // Most specific rule wins: one naming the nationality beats a generic one.
  matches.sort(
    (a, b) =>
      Number(b.nationality !== null) - Number(a.nationality !== null) ||
      Number(b.insideChina !== null) - Number(a.insideChina !== null),
  );
  const rule = matches[0];
  if (!rule) {
    return {
      outcome: 'to_be_verified',
      reason:
        'Eligibility for this city and activity has not been approved yet. Our team will verify it before any payment is requested.',
      alternativeCities: [],
      ruleVersion: null,
    };
  }
  return {
    outcome: rule.outcome,
    reason: rule.reason,
    alternativeCities:
      rule.outcome === 'ineligible' ? (rule.alternativeCities ?? []) : [],
    ruleVersion: rule.version,
  };
}

// ----------------------------------------------------------------- checkout

/**
 * Customer-chosen accountant tiers (boss §7.4). The customer must pick one;
 * the tax-refund tier is never silently pre-selected. The unresolved
 * exactly-20 / 50+ boundaries (C3/OD-02) are a guidance question for the
 * boss — the mechanism only records the customer's explicit choice.
 */
export const ACCOUNTANT_TIERS = ['no_tax', 'tax_lt20', 'tax_20_50'] as const;
export type AccountantTier = (typeof ACCOUNTANT_TIERS)[number];

/** City → PriceID prefix, matching the Step-1 seeded price matrix. */
export const REGISTRATION_CITY_CODES: Record<string, string> = {
  Yiwu: 'YIW',
  Foshan: 'FOS',
  Shanghai: 'SHA',
  Hainan: 'HIN',
  Hangzhou: 'HZH',
  Guangzhou: 'GZH',
  Shenzhen: 'SZX',
  Beijing: 'BJS',
};

export function cityCodeFor(city: string): string | null {
  const hit = Object.entries(REGISTRATION_CITY_CODES).find(
    ([name]) => norm(name) === norm(city),
  );
  return hit ? hit[1] : null;
}

/** Mandatory basket PriceIDs for a registration checkout (boss §7.4). */
export function mandatoryBasketPriceIds(
  city: string,
  tier: AccountantTier,
): string[] | null {
  const code = cityCodeFor(city);
  if (!code) return null;
  const tierSuffix = ((): string => {
    switch (tier) {
      case 'no_tax':
        return 'ACC-NOTAX';
      case 'tax_lt20':
        return 'ACC-TAX-LT20';
      case 'tax_20_50':
        return 'ACC-TAX-20-50';
      default: {
        const neverTier: never = tier;
        throw new Error(neverTier);
      }
    }
  })();
  return [
    `PRICE-${code}-REG`,
    `PRICE-${code}-CONSULT`,
    `PRICE-${code}-${tierSuffix}`,
  ];
}
