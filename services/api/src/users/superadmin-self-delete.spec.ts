// Made by Dr Ali
import {
  canSuperAdminSelfDelete,
  LAST_SUPERADMIN_SELF_DELETE_MSG,
} from './superadmin-self-delete';

describe('SuperAdmin self-delete rule', () => {
  it('blocks when no other active SuperAdmin', () => {
    expect(canSuperAdminSelfDelete(0)).toBe(false);
  });

  it('allows when another SuperAdmin remains', () => {
    expect(canSuperAdminSelfDelete(1)).toBe(true);
    expect(canSuperAdminSelfDelete(3)).toBe(true);
  });

  it('exports a clear message for clients', () => {
    expect(LAST_SUPERADMIN_SELF_DELETE_MSG).toMatch(/last SuperAdmin/i);
  });
});
