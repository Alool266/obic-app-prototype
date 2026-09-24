// Made by Dr Ali
// Auth service — bcrypt passwords, JWT access + rotating hashed refresh sessions.

import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { createHash, randomBytes, randomUUID } from 'crypto';
import { IsNull, Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { PublicUser, toPublicUser } from '../users/user.mapper';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { TotpVerifyDto } from './dto/totp-verify.dto';
import { ObicJwtPayload } from './jwt-payload.interface';
import { RefreshSession } from './refresh-session.entity';
import { TotpCryptoService } from './totp/totp-crypto.service';
import { TotpService } from './totp/totp.service';

const BCRYPT_ROUNDS = 12;
const REFRESH_TTL_MS = 1000 * 60 * 60 * 24 * 30; // 30 days
const ACCESS_TTL_SECONDS = 60 * 15; // 15 minutes

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: string;
  tokenType: 'Bearer';
}

export interface AuthResult extends AuthTokens {
  user: PublicUser;
}

/** Password OK — SuperAdmin must complete TOTP before tokens issue. */
export interface TotpPendingResult {
  requiresTotp: true;
  totpSession: string;
  expiresIn: string;
}

export type LoginResult = AuthResult | TotpPendingResult;

@Injectable()
export class AuthService {
  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
    @InjectRepository(RefreshSession)
    private readonly sessionsRepo: Repository<RefreshSession>,
    private readonly totpCrypto: TotpCryptoService,
    private readonly totp: TotpService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResult> {
    const email = this.normalizeEmail(dto.email);
    const phone = this.normalizePhone(dto.phone);
    this.requireEmailOrPhone(email, phone);

    if (email) {
      const taken = await this.usersRepo.exist({ where: { email } });
      if (taken) throw new ConflictException('Email already registered');
    }
    if (phone) {
      const taken = await this.usersRepo.exist({ where: { phone } });
      if (taken) throw new ConflictException('Phone already registered');
    }

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
    const user = this.usersRepo.create({
      email,
      phone,
      passwordHash,
      name: dto.name.trim(),
      role: UserRole.Customer,
    });
    await this.usersRepo.save(user);
    return this.issueAuthResult(user);
  }

  async login(dto: LoginDto): Promise<LoginResult> {
    const email = this.normalizeEmail(dto.email);
    const phone = this.normalizePhone(dto.phone);
    this.requireEmailOrPhone(email, phone);

    const user = email
      ? await this.usersRepo.findOne({ where: { email } })
      : await this.usersRepo.findOne({ where: { phone: phone! } });

    // Same message for missing user / bad password — avoid account enumeration.
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (
      user.role === UserRole.SuperAdmin &&
      user.totpEnabled &&
      user.totpSecretEnc
    ) {
      return this.issueTotpChallenge(user);
    }

    return this.issueAuthResult(user);
  }

  async verifyTotpLogin(dto: TotpVerifyDto): Promise<AuthResult> {
    let payload: { sub?: string; typ?: string };
    try {
      payload = await this.jwt.verifyAsync(dto.totpSession);
    } catch {
      throw new UnauthorizedException('TOTP session expired — sign in again');
    }
    if (payload.typ !== 'totp_pending' || !payload.sub) {
      throw new UnauthorizedException('Invalid TOTP session');
    }

    const user = await this.usersRepo.findOne({ where: { id: payload.sub } });
    if (
      !user ||
      user.role !== UserRole.SuperAdmin ||
      !user.totpEnabled ||
      !user.totpSecretEnc
    ) {
      throw new UnauthorizedException('Invalid TOTP session');
    }

    const secret = this.totpCrypto.decrypt(user.totpSecretEnc);
    if (!this.totp.verify(dto.code, secret)) {
      throw new UnauthorizedException('Invalid authenticator code');
    }

    return this.issueAuthResult(user);
  }

  async refresh(rawRefreshToken: string): Promise<AuthTokens> {
    const tokenHash = this.hashToken(rawRefreshToken);
    const session = await this.sessionsRepo.findOne({
      where: { tokenHash },
    });

    if (!session) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    // Reuse of a rotated/revoked token → kill the whole family.
    if (session.revokedAt) {
      await this.revokeFamily(session.familyId);
      throw new UnauthorizedException('Refresh token reuse detected');
    }

    if (session.expiresAt.getTime() < Date.now()) {
      session.revokedAt = new Date();
      await this.sessionsRepo.save(session);
      throw new UnauthorizedException('Refresh token expired');
    }

    const user = await this.usersRepo.findOne({ where: { id: session.userId } });
    if (!user) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    // Rotate: revoke current, issue a sibling in the same family.
    const tokens = await this.issueTokenPair(user, session.familyId);
    session.revokedAt = new Date();
    session.replacedById = tokens.sessionId;
    await this.sessionsRepo.save(session);

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresIn: tokens.expiresIn,
      tokenType: 'Bearer',
    };
  }

  async logout(rawRefreshToken: string): Promise<{ ok: true }> {
    const tokenHash = this.hashToken(rawRefreshToken);
    const session = await this.sessionsRepo.findOne({ where: { tokenHash } });
    if (session && !session.revokedAt) {
      session.revokedAt = new Date();
      await this.sessionsRepo.save(session);
    }
    // Always OK — do not leak whether the token existed.
    return { ok: true };
  }

  private issueTotpChallenge(user: User): TotpPendingResult {
    const totpSession = this.jwt.sign(
      { sub: user.id, typ: 'totp_pending', role: user.role },
      { expiresIn: 300 },
    );
    return {
      requiresTotp: true,
      totpSession,
      expiresIn: '300s',
    };
  }

  private async issueAuthResult(user: User): Promise<AuthResult> {
    const familyId = randomUUID();
    const tokens = await this.issueTokenPair(user, familyId);
    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresIn: tokens.expiresIn,
      tokenType: 'Bearer',
      user: toPublicUser(user),
    };
  }

  private async issueTokenPair(
    user: User,
    familyId: string,
  ): Promise<AuthTokens & { sessionId: string }> {
    const sessionId = randomUUID();
    const payload: ObicJwtPayload = {
      sub: user.id,
      sid: sessionId,
      role: user.role,
    };

    const expiresInConfig = this.config.get<string>('JWT_EXPIRES_IN') ?? '15m';
    const accessToken = await this.jwt.signAsync(payload, {
      expiresIn: this.parseExpiresInSeconds(expiresInConfig),
    });

    const refreshToken = randomBytes(48).toString('base64url');
    const session = this.sessionsRepo.create({
      id: sessionId,
      userId: user.id,
      tokenHash: this.hashToken(refreshToken),
      familyId,
      expiresAt: new Date(Date.now() + REFRESH_TTL_MS),
      revokedAt: null,
      replacedById: null,
    });
    await this.sessionsRepo.save(session);

    return {
      accessToken,
      refreshToken,
      expiresIn: `${this.parseExpiresInSeconds(expiresInConfig)}s`,
      tokenType: 'Bearer',
      sessionId,
    };
  }

  private async revokeFamily(familyId: string): Promise<void> {
    await this.sessionsRepo.update(
      { familyId, revokedAt: IsNull() },
      { revokedAt: new Date() },
    );
  }

  private hashToken(raw: string): string {
    return createHash('sha256').update(raw).digest('hex');
  }

  private normalizeEmail(email?: string): string | null {
    if (!email?.trim()) return null;
    return email.trim().toLowerCase();
  }

  private normalizePhone(phone?: string): string | null {
    if (!phone?.trim()) return null;
    // Keep digits and optional leading +.
    const cleaned = phone.trim().replace(/[^\d+]/g, '');
    return cleaned.length ? cleaned : null;
  }

  private requireEmailOrPhone(
    email: string | null,
    phone: string | null,
  ): void {
    if (!email && !phone) {
      throw new BadRequestException('Provide email or phone');
    }
  }

  private parseExpiresInSeconds(value: string): number {
    const m = /^(\d+)([smhd])?$/.exec(value.trim());
    if (!m) return ACCESS_TTL_SECONDS;
    const n = Number(m[1]);
    const unit = m[2] ?? 's';
    switch (unit) {
      case 'm':
        return n * 60;
      case 'h':
        return n * 3600;
      case 'd':
        return n * 86400;
      default:
        return n;
    }
  }
}
