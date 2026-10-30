// Made by Dr Ali
// WeChat-style phone sign-in — startPhoneLogin behavior.

import { ForbiddenException, BadRequestException } from '@nestjs/common';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthService } from './auth.service';

function makeService(users: Array<Record<string, unknown>>) {
  const saved: Array<Record<string, unknown>> = [];
  const usersRepo = {
    findOne: jest.fn(async ({ where }: { where: { phone?: string } }) =>
      users.find((u) => u.phone === where.phone) ?? null,
    ),
    create: jest.fn((row: Record<string, unknown>) => ({ ...row })),
    save: jest.fn(async (row: Record<string, unknown>) => {
      saved.push(row);
      return row;
    }),
  };
  const verification = {
    startChallenge: jest.fn(async (opts: Record<string, unknown>) => ({
      requiresVerification: true as const,
      verifySession: 'sess',
      channel: 'phone' as const,
      destinationMasked: '***',
      expiresIn: '15m',
      delivery: 'sms',
      _opts: opts,
    })),
  };
  const service = new AuthService(
    {} as never,
    {} as never,
    usersRepo as never,
    {} as never,
    {} as never,
    {} as never,
    verification as never,
    {} as never,
  );
  return { service, usersRepo, verification, saved };
}

describe('startPhoneLogin', () => {
  it('creates a Customer for a new +86 number and starts a register challenge', async () => {
    const { service, verification, saved } = makeService([]);
    const res = await service.startPhoneLogin({ phone: '13800138000' });
    expect(res.requiresVerification).toBe(true);
    expect(saved).toHaveLength(1);
    expect(saved[0].role).toBe(UserRole.Customer);
    expect(saved[0].phone).toBe('+8613800138000');
    expect(saved[0].country).toBe('CN');
    expect(saved[0].phoneVerifiedAt).toBeNull();
    const opts = verification.startChallenge.mock.calls[0][0];
    expect(opts.purpose).toBe('register');
    expect(opts.channel).toBe('phone');
  });

  it('starts a login challenge for an existing customer', async () => {
    const existing = {
      id: 'u1',
      phone: '+966512345678',
      email: 'a@b.co',
      role: UserRole.Customer,
      deletedAt: null,
    };
    const { service, verification, saved } = makeService([existing]);
    await service.startPhoneLogin({ phone: '+966512345678' });
    expect(saved).toHaveLength(0);
    const opts = verification.startChallenge.mock.calls[0][0];
    expect(opts.purpose).toBe('login');
    expect(opts.backupEmail).toBe('a@b.co');
  });

  it('refuses staff accounts (password + TOTP policy cannot be bypassed)', async () => {
    const staff = {
      id: 'u2',
      phone: '+8613800138000',
      role: UserRole.SuperAdmin,
      deletedAt: null,
    };
    const { service } = makeService([staff]);
    await expect(
      service.startPhoneLogin({ phone: '13800138000' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('rejects numbers outside the SMS countries', async () => {
    const { service } = makeService([]);
    await expect(
      service.startPhoneLogin({ phone: '+14155552671' }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
