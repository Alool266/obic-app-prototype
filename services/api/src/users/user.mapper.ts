// Made by Dr Ali
// Map User entity → public DTO (never include passwordHash).

import { UserRole } from '../common/enums/user-role.enum';
import { UserAddress } from './user-address.interface';
import { User } from './user.entity';
import { nextObicIdChangeAt } from './obic-id.util';
import { needsPhoneVerification } from '../auth/china-cohort.util';

export interface PublicUser {
  id: string;
  email: string | null;
  phone: string | null;
  name: string;
  role: UserRole;
  /** Desk title — display only; privilege is still `role`. */
  staffTitle: string | null;
  branchLabel: string | null;
  avatarUrl: string | null;
  city: string | null;
  country: string | null;
  /** WeChat-style vanity ID (lowercase). Null until first set. */
  obicId: string | null;
  /** When OBIC ID was last set/changed. */
  obicIdChangedAt: Date | null;
  /** Earliest time a change is allowed (null if never set or already eligible). */
  obicIdNextChangeAt: Date | null;
  /** Moments album cover URL. */
  momentsCoverUrl: string | null;
  /**
   * Stored Ops flag. Clients: SuperAdmin always may open Ops;
   * Employees only when this is true. Customers never.
   */
  opsAccess: boolean;
  /**
   * Stored offers flag. Clients: SuperAdmin always may manage hotel/flight offers;
   * Employees only when this is true. Customers never.
   */
  offersAccess: boolean;
  emailVerified: boolean;
  phoneVerified: boolean;
  /**
   * China cohort without verified mainland mobile — soft-block chat/orders
   * until the user completes SMS OTP.
   */
  needsPhoneVerification: boolean;
  addresses: UserAddress[];
  createdAt: Date;
}

export function toPublicUser(user: User): PublicUser {
  const changedAt = user.obicIdChangedAt ?? null;
  const nextAt = nextObicIdChangeAt(changedAt);
  const now = Date.now();
  return {
    id: user.id,
    email: user.email,
    phone: user.phone,
    name: user.name,
    role: user.role,
    staffTitle: user.staffTitle ?? null,
    branchLabel: user.branchLabel ?? null,
    avatarUrl: user.avatarUrl ?? null,
    city: user.city ?? null,
    country: user.country ?? null,
    obicId: user.obicId ?? null,
    obicIdChangedAt: changedAt,
    obicIdNextChangeAt:
      nextAt && nextAt.getTime() > now ? nextAt : null,
    momentsCoverUrl: user.momentsCoverUrl ?? null,
    opsAccess: Boolean(user.opsAccess),
    offersAccess: Boolean(user.offersAccess),
    emailVerified: Boolean(user.emailVerifiedAt),
    phoneVerified: Boolean(user.phoneVerifiedAt),
    needsPhoneVerification: needsPhoneVerification(user),
    addresses: Array.isArray(user.addresses) ? user.addresses : [],
    createdAt: user.createdAt,
  };
}

/** Effective Internal Ops gate (server-side helper). */
export function canOpenInternalOps(user: User): boolean {
  if (user.role === UserRole.SuperAdmin) return true;
  if (user.role === UserRole.Employee && user.opsAccess) return true;
  return false;
}

/** Effective hotel/flight offers manage gate (server-side helper). */
export function canManageOffers(user: User): boolean {
  if (user.role === UserRole.SuperAdmin) return true;
  if (user.role === UserRole.Employee && user.offersAccess) return true;
  return false;
}
