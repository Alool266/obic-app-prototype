// Made by Dr Ali
// When ADMIN_REQUIRE_TOTP: SuperAdmin must enroll before using Admin (except totp + me).

import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserRole } from '../enums/user-role.enum';
import { User } from '../../users/user.entity';
import { adminRequireTotp } from '../admin-security';

@Injectable()
export class AdminTotpEnrollGuard implements CanActivate {
  constructor(
    private readonly config: ConfigService,
    @InjectRepository(User) private readonly users: Repository<User>,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    if (!adminRequireTotp(this.config)) return true;

    const req = ctx.switchToHttp().getRequest<{
      user?: { userId?: string; sub?: string };
      method?: string;
      route?: { path?: string };
      url?: string;
      path?: string;
    }>();
    const userId = req.user?.userId ?? req.user?.sub;
    if (!userId) return true;

    const path = String(req.path || req.url || '');
    // Allow session + TOTP lifecycle while forcing enroll elsewhere.
    if (
      path.includes('/admin/me') ||
      path.includes('/admin/totp')
    ) {
      return true;
    }

    const user = await this.users.findOne({ where: { id: userId } });
    if (!user || user.role !== UserRole.SuperAdmin) return true;
    if (user.totpEnabled && user.totpSecretEnc) return true;

    throw new ForbiddenException({
      message: 'SuperAdmin must enable TOTP before using Admin',
      code: 'TOTP_ENROLL_REQUIRED',
    });
  }
}
