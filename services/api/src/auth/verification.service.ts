// Made by Dr Ali
// Email/phone OTP verification — Resend (email) + Twilio (SMS) with trial log fallback.

import {
  BadRequestException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { createHash, randomInt } from 'crypto';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import { MailSenderService } from './mail-sender.service';
import { SmsSenderService } from './sms-sender.service';
import {
  VerificationChallenge,
  VerificationChannel,
  VerificationPurpose,
} from './verification-challenge.entity';

const OTP_TTL_MS = 10 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_ATTEMPTS = 8;

export interface VerifyPendingResult {
  requiresVerification: true;
  verifySession: string;
  channel: VerificationChannel;
  destinationMasked: string;
  expiresIn: string;
  delivery: string;
  /** Trial only — never in production when real providers are configured. */
  debugCode?: string;
}

@Injectable()
export class VerificationService {
  private readonly log = new Logger(VerificationService.name);

  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly mail: MailSenderService,
    private readonly sms: SmsSenderService,
    @InjectRepository(VerificationChallenge)
    private readonly challenges: Repository<VerificationChallenge>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
  ) {}

  needsEmailVerify(user: User): boolean {
    return Boolean(user.email) && !user.emailVerifiedAt;
  }

  needsPhoneVerify(user: User): boolean {
    return Boolean(user.phone) && !user.phoneVerifiedAt;
  }

  /** Primary channel for register/login gate. */
  primaryChannel(user: User): VerificationChannel | null {
    if (user.email && !user.emailVerifiedAt) return 'email';
    if (user.phone && !user.phoneVerifiedAt) return 'phone';
    return null;
  }

  async startChallenge(opts: {
    user: User;
    channel: VerificationChannel;
    purpose: VerificationPurpose;
    destination: string;
    pendingValue?: string | null;
    backupEmail?: string | null;
    locale?: string | null;
  }): Promise<VerifyPendingResult> {
    const code = String(randomInt(100000, 999999));
    const codeHash = this.hashCode(code);
    const now = new Date();
    const expiresAt = new Date(now.getTime() + OTP_TTL_MS);

    let delivery = 'log';
    if (opts.channel === 'email') {
      const sent = await this.mail.sendOtpEmail({
        to: opts.destination,
        code,
        purpose: opts.purpose,
        locale: opts.locale,
      });
      delivery = sent.ok ? sent.via : 'log';
    } else {
      const sent = await this.sms.sendOtpSms({
        toPhone: opts.destination,
        code,
        purpose: opts.purpose,
        backupEmail: opts.backupEmail ?? opts.user.email,
        locale: opts.locale,
      });
      delivery = sent.ok ? sent.via : 'log';
    }

    const row = this.challenges.create({
      userId: opts.user.id,
      channel: opts.channel,
      purpose: opts.purpose,
      destination: opts.destination,
      codeHash,
      expiresAt,
      lastSentAt: now,
      attempts: 0,
      pendingValue: opts.pendingValue ?? null,
      debugCode: delivery === 'log' || delivery === 'email_backup' ? code : null,
      delivery,
    });
    await this.challenges.save(row);

    const verifySession = this.jwt.sign(
      {
        sub: opts.user.id,
        typ: 'verify_otp',
        ch: opts.channel,
        purpose: opts.purpose,
        cid: row.id,
      },
      { expiresIn: '15m' },
    );

    const exposeDebug =
      delivery === 'log' ||
      this.config.get<string>('VERIFICATION_DEBUG') === 'true';

    return {
      requiresVerification: true,
      verifySession,
      channel: opts.channel,
      destinationMasked: this.mask(opts.destination, opts.channel),
      expiresIn: '15m',
      delivery,
      ...(exposeDebug ? { debugCode: code } : {}),
    };
  }

  async resend(verifySession: string): Promise<VerifyPendingResult> {
    const payload = await this.parseSession(verifySession);
    const user = await this.users.findOne({ where: { id: payload.sub } });
    if (!user) throw new UnauthorizedException('Invalid session');

    const prev = await this.challenges.findOne({ where: { id: payload.cid } });
    if (!prev) throw new BadRequestException('Challenge expired — register again');

    const elapsed = Date.now() - prev.lastSentAt.getTime();
    if (elapsed < RESEND_COOLDOWN_MS) {
      const wait = Math.ceil((RESEND_COOLDOWN_MS - elapsed) / 1000);
      throw new BadRequestException(`Wait ${wait}s before resending`);
    }

    return this.startChallenge({
      user,
      channel: prev.channel,
      purpose: prev.purpose,
      destination: prev.destination,
      pendingValue: prev.pendingValue,
      backupEmail: user.email,
    });
  }

  async verifyCode(
    verifySession: string,
    code: string,
  ): Promise<{ userId: string; purpose: VerificationPurpose }> {
    const payload = await this.parseSession(verifySession);
    const challenge = await this.challenges.findOne({
      where: { id: payload.cid },
    });
    if (!challenge || challenge.userId !== payload.sub) {
      throw new UnauthorizedException('Invalid verification session');
    }
    if (challenge.expiresAt.getTime() < Date.now()) {
      throw new BadRequestException('Code expired — request a new one');
    }
    if (challenge.attempts >= MAX_ATTEMPTS) {
      throw new BadRequestException('Too many attempts — request a new code');
    }

    challenge.attempts += 1;
    await this.challenges.save(challenge);

    if (this.hashCode(code.trim()) !== challenge.codeHash) {
      throw new UnauthorizedException('Invalid code');
    }

    const user = await this.users.findOne({ where: { id: payload.sub } });
    if (!user) throw new UnauthorizedException('User not found');

    if (challenge.purpose === 'change_email' && challenge.pendingValue) {
      user.email = challenge.pendingValue;
      user.emailVerifiedAt = new Date();
    } else if (challenge.purpose === 'change_phone' && challenge.pendingValue) {
      user.phone = challenge.pendingValue;
      user.phoneVerifiedAt = new Date();
    } else if (challenge.channel === 'email') {
      user.emailVerifiedAt = new Date();
    } else {
      user.phoneVerifiedAt = new Date();
    }
    await this.users.save(user);
    await this.challenges.delete({ id: challenge.id });

    return { userId: user.id, purpose: challenge.purpose };
  }

  private async parseSession(token: string): Promise<{
    sub: string;
    cid: string;
    ch: VerificationChannel;
    purpose: VerificationPurpose;
  }> {
    try {
      const payload = await this.jwt.verifyAsync<{
        sub?: string;
        typ?: string;
        cid?: string;
        ch?: VerificationChannel;
        purpose?: VerificationPurpose;
      }>(token);
      if (
        payload.typ !== 'verify_otp' ||
        !payload.sub ||
        !payload.cid ||
        !payload.ch ||
        !payload.purpose
      ) {
        throw new Error('bad');
      }
      return {
        sub: payload.sub,
        cid: payload.cid,
        ch: payload.ch,
        purpose: payload.purpose,
      };
    } catch {
      throw new UnauthorizedException('Verification session expired');
    }
  }

  private hashCode(code: string): string {
    const pepper =
      this.config.get<string>('JWT_SECRET') ?? 'obic-verify-pepper';
    return createHash('sha256').update(`${pepper}:${code}`).digest('hex');
  }

  private mask(dest: string, channel: VerificationChannel): string {
    if (channel === 'email') {
      const [u, d] = dest.split('@');
      if (!d) return '***';
      const head = u.slice(0, Math.min(2, u.length));
      return `${head}***@${d}`;
    }
    if (dest.length <= 4) return '****';
    return `${dest.slice(0, 3)}****${dest.slice(-2)}`;
  }
}
