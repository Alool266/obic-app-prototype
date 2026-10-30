// Made by Dr Ali — known OBIC branches (same list as mobile / seed).
import { FORM2_DESK_TITLES } from './org';

/** Form2 order — Yiwu primary, Shanghai added. */
export const OBIC_BRANCHES = [
  'Yiwu',
  'Guangzhou',
  'Foshan',
  'Hangzhou',
  'Hainan',
  'Yemen',
  'Shanghai',
] as const;

export type ObicBranch = (typeof OBIC_BRANCHES)[number];

/** Extra labels used for Super Admin / HQ placeholders. */
export const OBIC_BRANCH_OPTIONS = [
  ...OBIC_BRANCHES,
  'All branches',
  'HQ (temp)',
] as const;

/** Form2 + legacy desk titles. Display only — not AuthZ. */
export const OBIC_DESK_TITLES = FORM2_DESK_TITLES;
