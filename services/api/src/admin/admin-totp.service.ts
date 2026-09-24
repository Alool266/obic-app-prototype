// Made by Dr Ali
// SuperAdmin TOTP enrollment — server-side only.

import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { adminRequireTotp } from '../common/admin-security';
import { UserRole } from '../common/enums/user-role.enum';
import { TotpCryptoService } from '../auth/totp/totp-crypto.service';
import { TotpService } from '../auth/totp/totp.service';
import { User } from '../users/user.entity';

@Injectable()
export class AdminTotpService {
  constructor(
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
    private readonly totp: TotpService,
    private readonly crypto: TotpCryptoService,
    private readonly config: ConfigService,
  ) {}

  async status(userId: string): Promise<{
    enabled: boolean;
    pendingEnroll: boolean;
    required: boolean;
  }> {
    const user = await this.requireSuperAdmin(userId);
    return {
      enabled: user.totpEnabled === true,
      pendingEnroll: !!user.totpPendingSecretEnc && !user.totpEnabled,
      required: adminRequireTotp(this.config),
    };
  }

  async enroll(userId: string): Promise<{ otpauthUrl: string; secret: string }> {
    const user = await this.requireSuperAdmin(userId);
    const secret = this.totp.generateSecret();
    user.totpPendingSecretEnc = this.crypto.encrypt(secret);
    await this.usersRepo.save(user);
    const label = user.email ?? user.name ?? user.id;
    return {
      otpauthUrl: this.totp.keyUri(label, secret),
      secret,
    };
  }

  async confirm(userId: string, code: string): Promise<{ enabled: true }> {
    const user = await this.requireSuperAdmin(userId);
    if (!user.totpPendingSecretEnc) {
      throw new BadRequestException('No pending TOTP enrollment');
    }
    const secret = this.crypto.decrypt(user.totpPendingSecretEnc);
    if (!this.totp.verify(code, secret)) {
      throw new UnauthorizedException('Invalid authenticator code');
    }
    user.totpSecretEnc = user.totpPendingSecretEnc;
    user.totpPendingSecretEnc = null;
    user.totpEnabled = true;
    await this.usersRepo.save(user);
    return { enabled: true };
  }

  async disable(
    userId: string,
    password: string,
    code: string,
  ): Promise<{ enabled: false }> {
    const user = await this.requireSuperAdmin(userId);
    if (adminRequireTotp(this.config)) {
      throw new BadRequestException(
        'TOTP cannot be disabled while ADMIN_REQUIRE_TOTP is on',
      );
    }
    if (!user.totpEnabled || !user.totpSecretEnc) {
      throw new BadRequestException('TOTP is not enabled');
    }
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Invalid password');
    const secret = this.crypto.decrypt(user.totpSecretEnc);
    if (!this.totp.verify(code, secret)) {
      throw new UnauthorizedException('Invalid authenticator code');
    }
    user.totpSecretEnc = null;
    user.totpPendingSecretEnc = null;
    user.totpEnabled = false;
    await this.usersRepo.save(user);
    return { enabled: false };
  }

  decryptActiveSecret(user: User): string | null {
    if (!user.totpEnabled || !user.totpSecretEnc) return null;
    return this.crypto.decrypt(user.totpSecretEnc);
  }

  private async requireSuperAdmin(userId: string): Promise<User> {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user || user.role !== UserRole.SuperAdmin) {
      throw new UnauthorizedException('SuperAdmin only');
    }
    return user;
  }
}
