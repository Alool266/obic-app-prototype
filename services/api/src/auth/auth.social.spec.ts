// Made by Dr Ali
import { ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { AuthService } from './auth.service';
import { RefreshSession } from './refresh-session.entity';
import {
  PROVIDER_EMAIL_NOT_VERIFIED,
  SOCIAL_LOGIN_ROLE_NOT_ALLOWED,
  VerifiedSocialIdentity,
} from './social-identity';
import { SocialTokenVerifier } from './social-token.verifier';
import { TotpCryptoService } from './totp/totp-crypto.service';
import { TotpService } from './totp/totp.service';
import { VerificationService } from './verification.service';

jest.mock('bcrypt', () => ({
  compare: jest.fn(),
  hash: jest.fn(async () => 'social-password-hash'),
}));

describe('AuthService.socialSignIn', () => {
  let service: AuthService;
  const usersRepo = {
    findOne: jest.fn(),
    create: jest.fn((row: Partial<User>) => row),
    save: jest.fn(async (row: unknown) => row),
  };
  const sessionsRepo = {
    create: jest.fn((row: unknown) => row),
    save: jest.fn(async (row: unknown) => row),
  };
  const jwt = {
    sign: jest.fn(() => 'test-access-token'),
    signAsync: jest.fn(async () => 'test-access-token'),
  };
  const verification = {
    primaryChannel: jest.fn(() => null),
    startChallenge: jest.fn(),
    verifyCode: jest.fn(),
    resend: jest.fn(),
  };
  const socialTokens = {
    verify: jest.fn<Promise<VerifiedSocialIdentity>, [string, string]>(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    usersRepo.findOne.mockReset();
    usersRepo.findOne.mockResolvedValue(null);
    usersRepo.create.mockReset();
    usersRepo.create.mockImplementation((row: Partial<User>) => row);
    usersRepo.save.mockReset();
    usersRepo.save.mockImplementation(async (row: unknown) => row);
    socialTokens.verify.mockReset();
    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: JwtService, useValue: jwt },
        {
          provide: ConfigService,
          useValue: {
            get: (k: string) => (k === 'JWT_EXPIRES_IN' ? '15m' : undefined),
          },
        },
        { provide: getRepositoryToken(User), useValue: usersRepo },
        { provide: getRepositoryToken(RefreshSession), useValue: sessionsRepo },
        { provide: TotpCryptoService, useValue: { decrypt: jest.fn() } },
        { provide: TotpService, useValue: { verify: jest.fn() } },
        { provide: VerificationService, useValue: verification },
        { provide: SocialTokenVerifier, useValue: socialTokens },
      ],
    }).compile();
    service = module.get(AuthService);
  });

  function customer(over: Partial<User> = {}): User {
    return {
      id: '11111111-1111-1111-1111-111111111111',
      email: 'customer@example.com',
      phone: null,
      passwordHash: 'keep-me',
      name: 'Test Customer',
      role: UserRole.Customer,
      staffTitle: null,
      branchLabel: null,
      departmentId: null,
      avatarUrl: null,
      city: null,
      country: null,
      gender: null,
      whatsUp: null,
      obicId: null,
      obicIdChangedAt: null,
      momentsCoverUrl: null,
      momentsCoverFocusY: 0,
      deletedAt: null,
      emailVerifiedAt: null,
      phoneVerifiedAt: null,
      opsAccess: false,
      offersAccess: false,
      totpSecretEnc: null,
      totpPendingSecretEnc: null,
      totpEnabled: false,
      addresses: [],
      googleSub: null,
      appleSub: null,
      createdAt: new Date(),
      updatedAt: new Date(),
      ...over,
    };
  }

  it('creates a Google user with emailVerifiedAt and tokens, without email OTP', async () => {
    usersRepo.findOne.mockResolvedValue(null);
    usersRepo.create.mockImplementation((row: Partial<User>) =>
      customer({
        id: '22222222-2222-2222-2222-222222222222',
        ...row,
      }),
    );
    socialTokens.verify.mockResolvedValue({
      provider: 'google',
      subject: 'google-sub-1',
      email: 'new.person@example.com',
      emailVerified: true,
      name: 'New Person',
    });

    const result = await service.socialSignIn({
      provider: 'google',
      idToken: 'verified-google-token-value',
      regionCountry: 'US',
    });

    expect(result.accessToken).toBe('test-access-token');
    expect(result.tokenType).toBe('Bearer');
    expect(result.user.email).toBe('new.person@example.com');
    expect(result.user.role).toBe(UserRole.Customer);
    expect(result.user.emailVerified).toBe(true);
    expect(result.user.phoneVerified).toBe(false);
    expect(result.user.needsPhoneVerification).toBe(false);
    expect(result.user.needsEmailVerification).toBe(false);
    expect(verification.startChallenge).not.toHaveBeenCalled();
    const created = usersRepo.create.mock.results[0]?.value as User;
    expect(created.emailVerifiedAt).toBeInstanceOf(Date);
    expect(created.phoneVerifiedAt).toBeNull();
    expect(created.googleSub).toBe('google-sub-1');
    expect(created.role).toBe(UserRole.Customer);
    expect(created.country).toBeNull();
  });

  it('still requires China phone verification after social sign-up', async () => {
    usersRepo.findOne.mockResolvedValue(null);
    usersRepo.create.mockImplementation((row: Partial<User>) =>
      customer({
        id: '33333333-3333-3333-3333-333333333333',
        email: 'ali@obic.local',
        ...row,
      }),
    );
    socialTokens.verify.mockResolvedValue({
      provider: 'google',
      subject: 'google-sub-cn',
      email: 'ali@obic.local',
      emailVerified: true,
      name: 'Ali',
    });

    const result = await service.socialSignIn({
      provider: 'google',
      idToken: 'verified-google-token-value',
      regionCountry: 'CN',
    });

    expect(result.user.email).toBe('ali@obic.local');
    expect(result.user.role).toBe(UserRole.Customer);
    expect(result.user.emailVerified).toBe(true);
    expect(result.user.phoneVerified).toBe(false);
    expect(result.user.needsPhoneVerification).toBe(true);
    expect(result.user.country).toBe('CN');
    expect(verification.startChallenge).not.toHaveBeenCalled();
    const created = usersRepo.create.mock.results[0]?.value as User;
    expect(created.phoneVerifiedAt).toBeNull();
    expect(created.phone).toBeNull();
  });

  it('rejects an unverified provider email instead of skipping the email check', async () => {
    const existing = customer({
      email: 'new.person@example.com',
      emailVerifiedAt: null,
    });
    usersRepo.findOne.mockImplementation(
      async (opts: { where: { googleSub?: string; email?: string } }) => {
        if (opts.where.email === 'new.person@example.com') return existing;
        return null;
      },
    );
    socialTokens.verify.mockResolvedValue({
      provider: 'google',
      subject: 'google-sub-unverified',
      email: 'new.person@example.com',
      emailVerified: false,
      name: null,
    });

    await expect(
      service.socialSignIn({
        provider: 'google',
        idToken: 'unverified-google-token-value',
      }),
    ).rejects.toThrow(PROVIDER_EMAIL_NOT_VERIFIED);

    expect(existing.emailVerifiedAt).toBeNull();
    expect(existing.googleSub).toBeNull();
    expect(usersRepo.create).not.toHaveBeenCalled();
    expect(usersRepo.save).not.toHaveBeenCalled();
    expect(verification.startChallenge).not.toHaveBeenCalled();
    expect(sessionsRepo.save).not.toHaveBeenCalled();
  });

  it('signs in an existing email account instead of creating a duplicate', async () => {
    const existing = customer({
      emailVerifiedAt: null,
      passwordHash: 'keep-me',
      googleSub: null,
    });
    usersRepo.findOne.mockImplementation(
      async (opts: { where: { googleSub?: string; email?: string } }) => {
        if (opts.where.googleSub) return null;
        if (opts.where.email === 'customer@example.com') return existing;
        return null;
      },
    );
    socialTokens.verify.mockResolvedValue({
      provider: 'google',
      subject: 'google-sub-linked',
      email: 'customer@example.com',
      emailVerified: true,
      name: 'Test Customer',
    });

    const result = await service.socialSignIn({
      provider: 'google',
      idToken: 'verified-google-token-value',
    });

    expect(usersRepo.create).not.toHaveBeenCalled();
    expect(existing.googleSub).toBe('google-sub-linked');
    expect(existing.passwordHash).toBe('keep-me');
    expect(existing.role).toBe(UserRole.Customer);
    expect(existing.emailVerifiedAt).toBeInstanceOf(Date);
    expect(existing.phoneVerifiedAt).toBeNull();
    expect(result.user.id).toBe(existing.id);
    expect(result.user.emailVerified).toBe(true);
    expect(result.accessToken).toBe('test-access-token');
    expect(verification.startChallenge).not.toHaveBeenCalled();
    expect(bcrypt.hash).not.toHaveBeenCalled();
  });

  it('does not create or role-escalate SuperAdmin via social login', async () => {
    const admin = customer({
      id: '44444444-4444-4444-4444-444444444444',
      email: 'boss@example.com',
      role: UserRole.SuperAdmin,
      googleSub: null,
      totpEnabled: true,
    });
    usersRepo.findOne.mockImplementation(
      async (opts: { where: { googleSub?: string; email?: string } }) => {
        if (opts.where.googleSub) return null;
        if (opts.where.email === 'boss@example.com') return admin;
        return null;
      },
    );
    socialTokens.verify.mockResolvedValue({
      provider: 'google',
      subject: 'google-sub-admin',
      email: 'boss@example.com',
      emailVerified: true,
      name: 'SuperAdmin',
    });

    await expect(
      service.socialSignIn({
        provider: 'google',
        idToken: 'verified-google-token-value',
        name: 'SuperAdmin',
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    await expect(
      service.socialSignIn({
        provider: 'google',
        idToken: 'verified-google-token-value',
        name: 'SuperAdmin',
      }),
    ).rejects.toThrow(SOCIAL_LOGIN_ROLE_NOT_ALLOWED);

    expect(admin.role).toBe(UserRole.SuperAdmin);
    expect(admin.googleSub).toBeNull();
    expect(usersRepo.create).not.toHaveBeenCalled();
    expect(usersRepo.save).not.toHaveBeenCalled();
    expect(sessionsRepo.save).not.toHaveBeenCalled();
  });

  it('accepts Apple Hide My Email and signs in a returning Apple user with no email claim', async () => {
    usersRepo.findOne.mockResolvedValue(null);
    usersRepo.create.mockImplementation((row: Partial<User>) =>
      customer({
        id: '55555555-5555-5555-5555-555555555555',
        ...row,
      }),
    );
    socialTokens.verify.mockResolvedValue({
      provider: 'apple',
      subject: 'apple-sub-1',
      email: 'xyz@privaterelay.appleid.com',
      emailVerified: true,
      name: null,
    });

    const created = await service.socialSignIn({
      provider: 'apple',
      idToken: 'verified-apple-token-value',
      name: 'Relay User',
    });
    expect(created.user.email).toBe('xyz@privaterelay.appleid.com');
    expect(created.user.emailVerified).toBe(true);
    expect(verification.startChallenge).not.toHaveBeenCalled();

    const returning = customer({
      id: '55555555-5555-5555-5555-555555555555',
      email: 'xyz@privaterelay.appleid.com',
      emailVerifiedAt: new Date('2026-01-01T00:00:00.000Z'),
      appleSub: 'apple-sub-1',
      phoneVerifiedAt: null,
    });
    usersRepo.findOne.mockImplementation(
      async (opts: { where: { appleSub?: string } }) => {
        if (opts.where.appleSub === 'apple-sub-1') return returning;
        return null;
      },
    );
    socialTokens.verify.mockResolvedValue({
      provider: 'apple',
      subject: 'apple-sub-1',
      email: null,
      emailVerified: false,
      name: null,
    });

    const again = await service.socialSignIn({
      provider: 'apple',
      idToken: 'verified-apple-token-again',
    });
    expect(again.user.email).toBe('xyz@privaterelay.appleid.com');
    expect(again.user.emailVerified).toBe(true);
    expect(returning.emailVerifiedAt?.toISOString()).toBe(
      '2026-01-01T00:00:00.000Z',
    );
    expect(returning.phoneVerifiedAt).toBeNull();
    expect(verification.startChallenge).not.toHaveBeenCalled();
  });
});
