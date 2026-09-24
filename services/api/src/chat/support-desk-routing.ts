// Made by Dr Ali
// Generic support-chat desk queue — Form2 branch + desk (no round-robin).
// Seed path: scripts/seed-staff-db.js → temp.{branch}.{desk}@obic.local
// Admin: SuperAdmin Staff desk can grant opsAccess / set branchLabel for live staff.

import {
  branchEmailDesk,
  deskKeyForServiceSlug,
} from '../orders/order-routing';

/** Default branch when customer has no recent order preferredBranch. */
export const DEFAULT_SUPPORT_BRANCH = 'Yiwu';

/**
 * Support queue desk key — secretary handles general client service / docs.
 * Aligns with order-routing fallback (`SERVICE_DESK` default).
 */
export const SUPPORT_DESK_KEY = 'secretary';

/** Form2 seed desks (scripts/seed-staff-db.js DESKS). */
export const SUPPORT_DESK_KEYS = [
  'secretary',
  'marketing',
  'marketer',
  'dataentry',
  'branchmgr',
  'finance',
  'cashier',
  'scholarships',
] as const;

export type SupportDeskKey = (typeof SUPPORT_DESK_KEYS)[number];

const DESK_KEY_SET = new Set<string>(SUPPORT_DESK_KEYS);

/**
 * Resolve desk key from explicit desk or Form1/Form2 service slug.
 * Unknown values fall back to secretary.
 */
export function resolveSupportDeskKey(
  deskOrServiceKey?: string | null,
): SupportDeskKey {
  const raw = (deskOrServiceKey ?? '').trim().toLowerCase();
  if (!raw) return SUPPORT_DESK_KEY;
  if (DESK_KEY_SET.has(raw)) return raw as SupportDeskKey;
  const fromSlug = deskKeyForServiceSlug(raw);
  if (DESK_KEY_SET.has(fromSlug)) return fromSlug as SupportDeskKey;
  return SUPPORT_DESK_KEY;
}

export function supportDeskEmail(
  branch: string,
  deskOrServiceKey?: string | null,
): string {
  const b = (branch ?? '').trim() || DEFAULT_SUPPORT_BRANCH;
  const desk = resolveSupportDeskKey(deskOrServiceKey);
  return branchEmailDesk(b, desk);
}

/**
 * Pick a branch for support routing.
 * Prefer explicit preferredBranch (e.g. from form or latest order), else default Yiwu.
 */
export function resolveSupportBranch(
  preferredBranch: string | null | undefined,
): string {
  const b = (preferredBranch ?? '').trim();
  return b.length ? b : DEFAULT_SUPPORT_BRANCH;
}
