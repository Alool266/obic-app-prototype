// Made by Dr Ali
// Auth service — bcrypt passwords, JWT access + rotating hashed refresh sessions.

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { createHash, randomBytes, randomUUID } from 'crypto';
import { IsNull, Not, Repository } from 'typeorm';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { UserRole } from '../common/enums/user-role.enum';
import { StartEmailVerifyDto } from '../users/dto/start-email-verify.dto';
import { StartPhoneVerifyDto } from '../users/dto/start-phone-verify.dto';
import { User } from '../users/user.entity';
import { PublicUser, toPublicUser } from '../users/user.mapper';
import { isChinaRegionCode, normalizeRegionCode } from './china-cohort.util';
import { normalizeChinaMobile } from './china-phone.util';
import {
  normalizeSmsMobile,
  smsCountryOf,
  SMS_PHONE_COUNTRIES_MSG,
} from './sms-phone.util';
import { LoginDto } from './dto/login.dto';
import { PhoneLoginStartDto } from './dto/phone-login.dto';
import { RegisterDto } from './dto/register.dto';
import { SocialSignInDto } from './dto/social-sign-in.dto';
import { TotpVerifyDto } from './dto/totp-verify.dto';
import { ObicJwtPayload } from './jwt-payload.interface';
import { RefreshSession } from './refresh-session.entity';
import {
  PROVIDER_EMAIL_NOT_VERIFIED,
  SOCIAL_LOGIN_ROLE_NOT_ALLOWED,
  SocialProvider,
  VerifiedSocialIdentity,
} from './social-identity';
import { SocialTokenVerifier } from './social-token.verifier';
import { TotpCryptoService } from './totp/totp-crypto.service';
import { TotpService } from './totp/totp.service';
import {
  VerificationService,
  VerifyPendingResult,
} from './verification.service';

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

export type LoginResult = AuthResult | TotpPendingResult | VerifyPendingResult;
export type RegisterResult = AuthResult | VerifyPendingResult;

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
    private readonly verification: VerificationService,
    private readonly socialTokens: SocialTokenVerifier,
  ) {}

  async register(dto: RegisterDto): Promise<RegisterResult> {
    const email = this.normalizeEmail(dto.email);
    const phone = this.normalizePhoneRegister(dto.phone);
    const chinaRegister =
      isChinaRegionCode(dto.regionCountry) || dto.locale === 'zh';

    // China cohort: mainland mobile + SMS OTP required (no email-only signup).
    if (chinaRegister) {
      if (!phone) {
        throw new BadRequestException(
          'China registration requires a China mainland mobile number',
        );
      }
      if (!email) {
        throw new BadRequestException(
          'EMAIL_REQUIRED_FOR_PHONE_VERIFY',
        );
      }
    } else {
      this.requireEmailOrPhone(email, phone);
    }

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
      country: chinaRegister
        ? (dto.regionCountry?.trim().toUpperCase() || 'CN')
        : null,
      emailVerifiedAt: null,
      phoneVerifiedAt: null,
    });
    await this.usersRepo.save(user);

    // China: verify email first (Resend), then phone gate after login.
    // Non-China: email if present, else phone.
    const channel: 'email' | 'phone' = chinaRegister
      ? 'email'
      : phone && !email
        ? 'phone'
        : 'email';
    const destination = (channel === 'phone' ? phone : email)!;
    return this.verification.startChallenge({
      user,
      channel,
      purpose: 'register',
      destination,
      backupEmail: email,
      locale: dto.locale,
    });
  }

  /**
   * WeChat-style phone sign-in: phone number + SMS code, no password.
   * Known customer number → login OTP. New number → account is created
   * (Customer, phone unverified) and the same code completes registration.
   * Completing the OTP marks the phone verified — for +86 numbers this is
   * also the China mainland phone verification. Staff/SuperAdmin accounts
   * are refused here so TOTP/password policy can never be bypassed.
   */
  async startPhoneLogin(
    dto: PhoneLoginStartDto,
  ): Promise<VerifyPendingResult> {
    const phone = normalizeSmsMobile(dto.phone);
    if (!phone) {
      throw new BadRequestException(SMS_PHONE_COUNTRIES_MSG);
    }

    let user = await this.usersRepo.findOne({ where: { phone } });
    if (user?.deletedAt) {
      throw new UnauthorizedException('Account deactivated');
    }
    if (user && user.role !== UserRole.Customer) {
      throw new ForbiddenException('PHONE_LOGIN_CUSTOMERS_ONLY');
    }

    if (!user) {
      user = this.usersRepo.create({
        email: null,
        phone,
        // Unusable random password — this account signs in by code only.
        passwordHash: await bcrypt.hash(randomUUID(), BCRYPT_ROUNDS),
        name: 'OBIC user',
        role: UserRole.Customer,
        country:
          normalizeRegionCode(dto.regionCountry) ??
          smsCountryOf(phone) ??
          null,
        emailVerifiedAt: null,
        phoneVerifiedAt: null,
      });
      await this.usersRepo.save(user);
      return this.startPhoneChallenge(user, phone, 'register', dto.locale);
    }

    return this.startPhoneChallenge(
      user,
      phone,
      'login',
      dto.locale,
      user.email,
    );
  }

  /**
   * Phone OTP challenge with an honest error when no SMS provider is
   * configured and there is no email inbox to fall back to (trial mode
   * delivers codes by email; real SMS needs Aliyun/Tencent/Twilio keys).
   */
  private async startPhoneChallenge(
    user: User,
    phone: string,
    purpose: 'register' | 'login',
    locale?: string,
    backupEmail?: string | null,
  ): Promise<VerifyPendingResult> {
    try {
      return await this.verification.startChallenge({
        user,
        channel: 'phone',
        purpose,
        destination: phone,
        backupEmail,
        locale,
      });
    } catch (err) {
      if (
        err instanceof BadRequestException &&
        err.message === 'EMAIL_REQUIRED_FOR_PHONE_VERIFY' &&
        !backupEmail
      ) {
        throw new BadRequestException('SMS_NOT_CONFIGURED');
      }
      throw err;
    }
  }

  /**
   * Logged-in: start OTP to add/verify China mainland mobile.
   * Trial (no SMS keys): code emailed to account email. Completing OTP sets phone.
   */
  async startPhoneVerify(
    actor: AuthUser,
    dto: StartPhoneVerifyDto,
  ): Promise<VerifyPendingResult> {
    const user = await this.usersRepo.findOne({ where: { id: actor.userId } });
    if (!user || user.deletedAt) {
      throw new NotFoundException('User not found');
    }
    const phone = normalizeSmsMobile(dto.phone);
    if (!phone) {
      throw new BadRequestException(SMS_PHONE_COUNTRIES_MSG);
    }
    const taken = await this.usersRepo.exist({
      where: { phone, id: Not(user.id) },
    });
    if (taken) {
      throw new ConflictException('Phone already registered');
    }

    // Trial phone verify needs an email inbox for the OTP.
    let backupEmail = user.email?.trim() || null;
    if (!backupEmail) {
      const incoming = this.normalizeEmail(dto.email);
      if (!incoming) {
        throw new BadRequestException('EMAIL_REQUIRED_FOR_PHONE_VERIFY');
      }
      const emailTaken = await this.usersRepo.exist({
        where: { email: incoming, id: Not(user.id) },
      });
      if (emailTaken) {
        throw new ConflictException('Email already in use');
      }
      user.email = incoming;
      await this.usersRepo.save(user);
      backupEmail = incoming;
    }

    return this.verification.startChallenge({
      user,
      channel: 'phone',
      purpose: 'change_phone',
      destination: phone,
      pendingValue: phone,
      backupEmail,
      locale: dto.locale,
    });
  }

  /**
   * Logged-in: start email OTP (China cohort must verify email before full use).
   */
  async startEmailVerify(
    actor: AuthUser,
    dto: StartEmailVerifyDto,
  ): Promise<VerifyPendingResult> {
    const user = await this.usersRepo.findOne({ where: { id: actor.userId } });
    if (!user || user.deletedAt) {
      throw new NotFoundException('User not found');
    }

    let email = user.email?.trim() || null;
    if (!email) {
      const incoming = this.normalizeEmail(dto.email);
      if (!incoming) {
        throw new BadRequestException('EMAIL_REQUIRED_FOR_PHONE_VERIFY');
      }
      const emailTaken = await this.usersRepo.exist({
        where: { email: incoming, id: Not(user.id) },
      });
      if (emailTaken) {
        throw new ConflictException('Email already in use');
      }
      user.email = incoming;
      await this.usersRepo.save(user);
      email = incoming;
    }

    if (user.emailVerifiedAt) {
      throw new BadRequestException('Email already verified');
    }

    return this.verification.startChallenge({
      user,
      channel: 'email',
      purpose: 'login',
      destination: email,
      locale: dto.locale,
    });
  }

  async login(dto: LoginDto): Promise<LoginResult> {
    const email = this.normalizeEmail(dto.email);
    const phone = this.normalizePhoneLogin(dto.phone);
    this.requireEmailOrPhone(email, phone);

    const user = email
      ? await this.usersRepo.findOne({ where: { email } })
      : await this.usersRepo.findOne({ where: { phone: phone! } });

    // Same message for missing user / bad password — avoid account enumeration.
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }
    if (user.deletedAt) {
      throw new UnauthorizedException('Account deactivated');
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

    const channel = this.verification.primaryChannel(user);
    if (channel) {
      const destination =
        channel === 'email' ? user.email! : user.phone!;
      return this.verification.startChallenge({
        user,
        channel,
        purpose: 'login',
        destination,
        backupEmail: user.email,
      });
    }

    return this.issueAuthResult(user);
  }

  /**
   * Google or Apple sign-in.
   * The provider token is verified here. A verified provider email skips OBIC
   * email OTP and sets emailVerifiedAt. Phone is never marked verified — China
   * cohort still hits the existing phone gate. New users are always Customers.
   */
  async socialSignIn(dto: SocialSignInDto): Promise<AuthResult> {
    const identity = await this.socialTokens.verify(dto.provider, dto.idToken);
    const email = identity.email;

    let user = await this.usersRepo.findOne({
      where: this.socialSubjectWhere(dto.provider, identity.subject),
    });
    if (!user && email && identity.emailVerified) {
      user = await this.usersRepo.findOne({ where: { email } });
    }

    if (!user) {
      if (!email || !identity.emailVerified) {
        throw new BadRequestException(PROVIDER_EMAIL_NOT_VERIFIED);
      }
      const created = await this.createSocialUser(dto, identity, email);
      return this.issueAuthResult(created);
    }

    if (user.deletedAt) {
      throw new UnauthorizedException('Account deactivated');
    }
    // Staff and SuperAdmin stay on password (+ TOTP). Never link or promote.
    if (user.role !== UserRole.Customer) {
      throw new ForbiddenException(SOCIAL_LOGIN_ROLE_NOT_ALLOWED);
    }

    this.linkSocialSubject(user, dto.provider, identity.subject);
    if (
      identity.emailVerified &&
      email &&
      user.email &&
      user.email.trim().toLowerCase() === email &&
      !user.emailVerifiedAt
    ) {
      user.emailVerifiedAt = new Date();
    }
    await this.usersRepo.save(user);
    return this.issueAuthResult(user);
  }

  async verifyOtp(opts: {
    verifySession: string;
    code: string;
  }): Promise<AuthResult> {
    const { userId } = await this.verification.verifyCode(
      opts.verifySession,
      opts.code,
    );
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user || user.deletedAt) {
      throw new UnauthorizedException('Account unavailable');
    }
    return this.issueAuthResult(user);
  }

  async resendOtp(verifySession: string): Promise<VerifyPendingResult> {
    return this.verification.resend(verifySession);
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

    // Issue a new access JWT only. Do not rotate the refresh token.
    // Rotation + reuse-detection signed people out when the app was closed
    // before the new refresh token was saved, or when two requests refreshed
    // the same token at once (the second looked like theft and revoked the family).
    const expiresInConfig = this.config.get<string>('JWT_EXPIRES_IN') ?? '15m';
    const accessToken = await this.jwt.signAsync(
      {
        sub: user.id,
        sid: session.id,
        role: user.role,
      } satisfies ObicJwtPayload,
      { expiresIn: this.parseExpiresInSeconds(expiresInConfig) },
    );

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      expiresIn: `${this.parseExpiresInSeconds(expiresInConfig)}s`,
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

  private async createSocialUser(
    dto: SocialSignInDto,
    identity: VerifiedSocialIdentity,
    email: string,
  ): Promise<User> {
    const region = normalizeRegionCode(dto.regionCountry);
    const china = isChinaRegionCode(region);
    const passwordHash = await bcrypt.hash(
      randomBytes(32).toString('base64url'),
      BCRYPT_ROUNDS,
    );
    const user = this.usersRepo.create({
      email,
      phone: null,
      passwordHash,
      name: this.socialDisplayName(dto.name, identity.name, email),
      role: UserRole.Customer,
      country: china ? region : null,
      emailVerifiedAt: new Date(),
      phoneVerifiedAt: null,
      googleSub: null,
      appleSub: null,
    });
    this.linkSocialSubject(user, dto.provider, identity.subject);
    await this.usersRepo.save(user);
    return user;
  }

  private socialDisplayName(
    explicit: string | undefined,
    tokenName: string | null,
    email: string,
  ): string {
    const fromEmail = email.split('@')[0] ?? '';
    const raw = (explicit?.trim() || tokenName?.trim() || fromEmail || 'OBIC')
      .replace(/\s+/g, ' ')
      .slice(0, 120);
    return raw.length >= 2 ? raw : 'OBIC user';
  }

  private socialSubjectWhere(
    provider: SocialProvider,
    subject: string,
  ): { googleSub: string } | { appleSub: string } {
    switch (provider) {
      case 'google':
        return { googleSub: subject };
      case 'apple':
        return { appleSub: subject };
      default: {
        const _exhaustive: never = provider;
        throw new BadRequestException(String(_exhaustive));
      }
    }
  }

  private linkSocialSubject(
    user: User,
    provider: SocialProvider,
    subject: string,
  ): void {
    switch (provider) {
      case 'google':
        if (user.googleSub && user.googleSub !== subject) {
          throw new ConflictException('SOCIAL_ACCOUNT_ALREADY_LINKED');
        }
        user.googleSub = subject;
        return;
      case 'apple':
        if (user.appleSub && user.appleSub !== subject) {
          throw new ConflictException('SOCIAL_ACCOUNT_ALREADY_LINKED');
        }
        user.appleSub = subject;
        return;
      default: {
        const _exhaustive: never = provider;
        throw new BadRequestException(String(_exhaustive));
      }
    }
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

  /** Register: China, Saudi Arabia, or Yemen mobile. */
  private normalizePhoneRegister(phone?: string): string | null {
    if (!phone?.trim()) return null;
    const normalized = normalizeSmsMobile(phone);
    if (!normalized) {
      throw new BadRequestException(SMS_PHONE_COUNTRIES_MSG);
    }
    return normalized;
  }

  /**
   * Login: China, Saudi Arabia, or Yemen E.164; else cleaned digits for older rows.
   */
  private normalizePhoneLogin(phone?: string): string | null {
    if (!phone?.trim()) return null;
    const sms = normalizeSmsMobile(phone);
    if (sms) return sms;
    const cn = normalizeChinaMobile(phone);
    if (cn) return cn;
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
