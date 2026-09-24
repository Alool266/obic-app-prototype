// Made by Dr Ali
import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { User } from '../../users/user.entity';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { UserRole } from '../enums/user-role.enum';
import { AuthUser } from '../interfaces/auth-user.interface';
import { RolesGuard } from './roles.guard';

describe('RolesGuard', () => {
  let guard: RolesGuard;
  const users = { findOne: jest.fn() };
  const reflector = { getAllAndOverride: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        RolesGuard,
        { provide: Reflector, useValue: reflector },
        { provide: getRepositoryToken(User), useValue: users },
      ],
    }).compile();
    guard = module.get(RolesGuard);
  });

  function ctx(user?: AuthUser): ExecutionContext {
    const request = { user };
    return {
      getHandler: () => ({}),
      getClass: () => ({}),
      switchToHttp: () => ({ getRequest: () => request }),
    } as unknown as ExecutionContext;
  }

  it('denies Customer JWT on Employee/SuperAdmin routes (admin/me)', async () => {
    reflector.getAllAndOverride.mockReturnValue([
      UserRole.Employee,
      UserRole.SuperAdmin,
    ]);
    users.findOne.mockResolvedValue({
      id: 'cust-1',
      role: UserRole.Customer,
    });

    await expect(
      guard.canActivate(
        ctx(new AuthUser('cust-1', 'sid-1', UserRole.Customer)),
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(reflector.getAllAndOverride).toHaveBeenCalledWith(ROLES_KEY, [
      expect.anything(),
      expect.anything(),
    ]);
  });

  it('allows SuperAdmin when DB role matches', async () => {
    reflector.getAllAndOverride.mockReturnValue([
      UserRole.Employee,
      UserRole.SuperAdmin,
    ]);
    users.findOne.mockResolvedValue({
      id: 'sa-1',
      role: UserRole.SuperAdmin,
    });

    await expect(
      guard.canActivate(
        ctx(new AuthUser('sa-1', 'sid-2', UserRole.SuperAdmin)),
      ),
    ).resolves.toBe(true);
  });
});
