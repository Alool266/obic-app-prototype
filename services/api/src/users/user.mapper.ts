// Made by Dr Ali
// Map User entity → public DTO (never include passwordHash).

import { UserRole } from '../common/enums/user-role.enum';
import { UserAddress } from './user-address.interface';
import { User } from './user.entity';

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
  addresses: UserAddress[];
  createdAt: Date;
}

export function toPublicUser(user: User): PublicUser {
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
    opsAccess: Boolean(user.opsAccess),
    offersAccess: Boolean(user.offersAccess),
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
