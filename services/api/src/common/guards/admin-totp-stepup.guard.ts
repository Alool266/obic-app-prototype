// Made by Dr Ali
// Step-up MFA: privileged SuperAdmin mutations require X-OBIC-TOTP header.

import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TotpCryptoService } from '../../auth/totp/totp-crypto.service';
import { TotpService } from '../../auth/totp/totp.service';
import { UserRole } from '../enums/user-role.enum';
import { User } from '../../users/user.entity';
import { adminRequireTotp } from '../admin-security';

export const TOTP_HEADER = 'x-obic-totp';

@Injectable()
export class AdminTotpStepUpGuard implements CanActivate {
  constructor(
    private readonly config: ConfigService,
    @InjectRepository(User) private readonly users: Repository<User>,
    private readonly totp: TotpService,
    private readonly crypto: TotpCryptoService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    // Always require step-up for decorated routes when TOTP is required,
    // or when the actor already has TOTP enabled.
    const req = ctx.switchToHttp().getRequest<{
      user?: { userId?: string; sub?: string };
      headers: Record<string, string | string[] | undefined>;
    }>();
    const userId = req.user?.userId ?? req.user?.sub;
    if (!userId) return true;

    const user = await this.users.findOne({ where: { id: userId } });
    if (!user || user.role !== UserRole.SuperAdmin) return true;

    const must =
      adminRequireTotp(this.config) ||
      (user.totpEnabled === true && !!user.totpSecretEnc);

    if (!must) return true;

    if (!user.totpEnabled || !user.totpSecretEnc) {
      throw new ForbiddenException({
        message: 'SuperAdmin must enable TOTP before privileged actions',
        code: 'TOTP_ENROLL_REQUIRED',
      });
    }

    const raw = req.headers[TOTP_HEADER];
    const code = (Array.isArray(raw) ? raw[0] : raw)?.trim() ?? '';
    if (!/^\d{6}$/.test(code)) {
      throw new UnauthorizedException({
        message: 'Authenticator code required (header X-OBIC-TOTP)',
        code: 'TOTP_STEPUP_REQUIRED',
      });
    }

    const secret = this.crypto.decrypt(user.totpSecretEnc);
    if (!this.totp.verify(code, secret)) {
      throw new UnauthorizedException({
        message: 'Invalid authenticator code',
        code: 'TOTP_INVALID',
      });
    }
    return true;
  }
}
