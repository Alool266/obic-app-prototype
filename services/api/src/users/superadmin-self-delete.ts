// Made by Dr Ali
// Last SuperAdmin cannot self-delete; allow when another active SA remains.

export function canSuperAdminSelfDelete(
  otherActiveSuperAdminCount: number,
): boolean {
  return otherActiveSuperAdminCount > 0;
}

export const LAST_SUPERADMIN_SELF_DELETE_MSG =
  'Cannot delete the last SuperAdmin account. Promote or keep another SuperAdmin first.';
