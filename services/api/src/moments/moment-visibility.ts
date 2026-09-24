// Made by Dr Ali
// WeChat Moments visibility — pure helpers (unit-tested).

/** Official / staff posts — visible to everyone (incl. guests). */
export const MOMENT_VISIBILITY_PUBLIC = 'public' as const;
/** Customer posts — mutual friends + author only. */
export const MOMENT_VISIBILITY_FRIENDS = 'friends' as const;

export type MomentVisibility =
  | typeof MOMENT_VISIBILITY_PUBLIC
  | typeof MOMENT_VISIBILITY_FRIENDS;

export function momentVisibilityForRole(isStaff: boolean): MomentVisibility {
  return isStaff ? MOMENT_VISIBILITY_PUBLIC : MOMENT_VISIBILITY_FRIENDS;
}

export function isMomentPublic(m: {
  visibility?: string | null;
  notifyAll?: boolean | null;
}): boolean {
  if (m.visibility === MOMENT_VISIBILITY_PUBLIC) return true;
  // Legacy rows before visibility column / notifyAll staff posts.
  if (m.notifyAll === true) return true;
  return false;
}

/**
 * WeChat 朋友圈 ACL:
 * - public/official → everyone
 * - friends → author + mutual friends only
 * - guests (no viewer) → public only
 */
export function canViewerSeeMoment(
  m: {
    authorId: string;
    visibility?: string | null;
    notifyAll?: boolean | null;
    deletedAt?: Date | null;
  },
  viewerId: string | null | undefined,
  friendAuthorIds: ReadonlySet<string>,
): boolean {
  if (m.deletedAt) return false;
  if (isMomentPublic(m)) return true;
  if (!viewerId) return false;
  if (m.authorId === viewerId) return true;
  return friendAuthorIds.has(m.authorId);
}
