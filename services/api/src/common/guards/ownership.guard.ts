// Made by Dr Ali
// OwnershipGuard stub — AuthGuard → RolesGuard → THIS.
// Private resources must be scoped to the authenticated principal (or assignment).
// Never trust a client-supplied userId / customerId for "my" data.

import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuthUser } from '../interfaces/auth-user.interface';
import { UserRole } from '../enums/user-role.enum';

/**
 * Example ownership check helper used by feature services.
 * Controllers should load the resource server-side, then call assertOwnership.
 */
export function assertOwnership(options: {
  resourceOwnerId: string | null | undefined;
  actor: AuthUser;
  /** Prefer 404 over 403 for cross-tenant probes when product policy says so */
  preferNotFound?: boolean;
}): void {
  const { resourceOwnerId, actor, preferNotFound = true } = options;
  if (!resourceOwnerId || resourceOwnerId !== actor.userId) {
    if (preferNotFound) {
      throw new NotFoundException('Resource not found');
    }
    throw new ForbiddenException('Not your resource');
  }
}

/**
 * Employee assignment scope — employees see assigned work only, never peers' queues.
 */
export function assertAssignment(options: {
  assignedEmployeeId: string | null | undefined;
  actor: AuthUser;
  preferNotFound?: boolean;
}): void {
  const { assignedEmployeeId, actor, preferNotFound = true } = options;
  if (actor.role === UserRole.SuperAdmin) {
    // Oversight is allowed — audit logging is mandatory when wired (Phase 4).
    return;
  }
  if (
    actor.role !== UserRole.Employee ||
    !assignedEmployeeId ||
    assignedEmployeeId !== actor.userId
  ) {
    if (preferNotFound) {
      throw new NotFoundException('Resource not found');
    }
    throw new ForbiddenException('Not assigned to you');
  }
}

/**
 * Guard stub for routes that declare an ownership param (e.g. :orderId).
 * Feature modules will inject repositories and replace the placeholder lookup.
 */
@Injectable()
export class OwnershipGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{ user?: AuthUser }>();
    if (!request.user?.userId) {
      throw new ForbiddenException('Ownership check requires an authenticated user');
    }
    // Real ownership predicates live next to each resource query
    // (WHERE customer_id = :userId). This guard documents the pipeline order.
    return true;
  }
}
