// Made by Dr Ali
import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { AuthService } from './auth.service';
import { RefreshSession } from './refresh-session.entity';
import { TotpCryptoService } from './totp/totp-crypto.service';
import { TotpService } from './totp/totp.service';
import { VerificationService } from './verification.service';

jest.mock('bcrypt', () => ({
  compare: jest.fn(),
  hash: jest.fn(),
}));

describe('AuthService.login', () => {
  let service: AuthService;
  const usersRepo = {
    findOne: jest.fn(),
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

  beforeEach(async () => {
    jest.clearAllMocks();
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
      ],
    }).compile();
    service = module.get(AuthService);
  });

  it('returns tokens and public user on valid credentials', async () => {
    usersRepo.findOne.mockResolvedValue({
      id: '11111111-1111-1111-1111-111111111111',
      email: 'customer@example.com',
      phone: null,
      name: 'Test Customer',
      role: UserRole.Customer,
      passwordHash: 'hashed',
      staffTitle: null,
      branchLabel: null,
      avatarUrl: null,
      opsAccess: false,
      offersAccess: false,
      emailVerifiedAt: new Date(),
      phoneVerifiedAt: null,
      deletedAt: null,
      createdAt: new Date(),
    });
    (bcrypt.compare as jest.Mock).mockResolvedValue(true);

    const result = await service.login({
      email: 'customer@example.com',
      password: 'password12',
    });

    expect('accessToken' in result && result.accessToken).toBe(
      'test-access-token',
    );
    if (!('user' in result)) throw new Error('expected AuthResult');
    expect(result.tokenType).toBe('Bearer');
    expect(result.user.email).toBe('customer@example.com');
    expect(result.user.role).toBe(UserRole.Customer);
    expect(
      (result.user as { passwordHash?: string }).passwordHash,
    ).toBeUndefined();
    expect(sessionsRepo.save).toHaveBeenCalled();
  });

  it('rejects bad password without leaking whether the account exists', async () => {
    usersRepo.findOne.mockResolvedValue({
      id: '11111111-1111-1111-1111-111111111111',
      email: 'customer@example.com',
      passwordHash: 'hashed',
      role: UserRole.Customer,
      deletedAt: null,
    });
    (bcrypt.compare as jest.Mock).mockResolvedValue(false);

    await expect(
      service.login({ email: 'customer@example.com', password: 'wrongpass' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
