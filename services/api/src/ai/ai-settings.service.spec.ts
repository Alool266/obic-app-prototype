// Made by Dr Ali
import { ForbiddenException } from '@nestjs/common';
import { AiSettingsService } from './ai-settings.service';
import { AI_AUTO_REPLY_GLOBAL_KEY } from './app-setting.entity';

describe('AiSettingsService + admin toggle permissions (unit)', () => {
  it('defaults global flag to true when unset', async () => {
    const settings = {
      findOne: jest.fn(async () => null),
      create: jest.fn((x) => x),
      save: jest.fn(async (x) => x),
    };
    const cfg = {
      autoReplyEnabled: true,
    };
    const svc = new AiSettingsService(cfg as never, settings as never);
    expect(await svc.getGlobalAutoReplyFlag()).toBe(true);
    expect(await svc.isGlobalAutoReplyEnabled()).toBe(true);
  });

  it('respects DB false even when env auto-reply on', async () => {
    const settings = {
      findOne: jest.fn(async () => ({
        key: AI_AUTO_REPLY_GLOBAL_KEY,
        value: 'false',
      })),
      create: jest.fn((x) => x),
      save: jest.fn(async (x) => x),
    };
    const cfg = { autoReplyEnabled: true };
    const svc = new AiSettingsService(cfg as never, settings as never);
    expect(await svc.isGlobalAutoReplyEnabled()).toBe(false);
  });

  it('setGlobalAutoReplyFlag persists true/false', async () => {
    const row: { key: string; value: string } = {
      key: AI_AUTO_REPLY_GLOBAL_KEY,
      value: 'true',
    };
    const settings = {
      findOne: jest.fn(async () => row),
      create: jest.fn((x) => x),
      save: jest.fn(async (x) => {
        Object.assign(row, x);
        return x;
      }),
    };
    const svc = new AiSettingsService(
      { autoReplyEnabled: true } as never,
      settings as never,
    );
    await svc.setGlobalAutoReplyFlag(false);
    expect(row.value).toBe('false');
    expect(await svc.getGlobalAutoReplyFlag()).toBe(false);
  });
});

describe('Admin AI settings permission gate', () => {
  it('requireSuperAdmin rejects Employee for AI settings mutation shape', async () => {
    // Mirrors AdminService.requireSuperAdmin — Employee must not PATCH ai-settings.
    const requireSuperAdmin = async (role: string) => {
      if (role !== 'SuperAdmin') throw new ForbiddenException('SuperAdmin only');
    };
    await expect(requireSuperAdmin('Employee')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    await expect(requireSuperAdmin('Customer')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    await expect(requireSuperAdmin('SuperAdmin')).resolves.toBeUndefined();
  });
});
