// Made by Dr Ali
// RolesGuard — JWT role is a UI hint only. Privilege always re-checked from DB.
// AuthGuard → THIS → handlers. Never trust client-sent role strings.

import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../users/user.entity';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { UserRole } from '../enums/user-role.enum';
import { AuthUser } from '../interfaces/auth-user.interface';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    @InjectRepository(User)
    private readonly users: Repository<User>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const required = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required?.length) {
      return true;
    }

    const request = context.switchToHttp().getRequest<{ user?: AuthUser }>();
    const actor = request.user;
    if (!actor?.userId) {
      throw new UnauthorizedException('Authentication required');
    }

    // Source of truth: database role — not the JWT claim (could be stale/forged claim).
    const row = await this.users.findOne({
      where: { id: actor.userId },
      select: ['id', 'role'],
    });
    if (!row) {
      throw new UnauthorizedException('User not found');
    }
    if (!required.includes(row.role)) {
      throw new ForbiddenException('Insufficient role');
    }

    // Refresh in-request principal so downstream services see DB role.
    request.user = new AuthUser(actor.userId, actor.sessionId, row.role);
    return true;
  }
}
