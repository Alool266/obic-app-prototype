// Made by Dr Ali
// WeChat Moments visibility — pure helpers (unit-tested).

/** Official / staff posts — visible to everyone (incl. guests). */
export const MOMENT_VISIBILITY_PUBLIC = 'public' as const;
/** Customer posts — all mutual friends + author. */
export const MOMENT_VISIBILITY_FRIENDS = 'friends' as const;
/** Only the author. */
export const MOMENT_VISIBILITY_PRIVATE = 'private' as const;
/** Author + selected friends only (`allowedUserIds`). */
export const MOMENT_VISIBILITY_PARTIAL = 'partial' as const;
/** All friends except those in `deniedUserIds`. */
export const MOMENT_VISIBILITY_EXCLUDE = 'exclude' as const;

export type MomentVisibility =
  | typeof MOMENT_VISIBILITY_PUBLIC
  | typeof MOMENT_VISIBILITY_FRIENDS
  | typeof MOMENT_VISIBILITY_PRIVATE
  | typeof MOMENT_VISIBILITY_PARTIAL
  | typeof MOMENT_VISIBILITY_EXCLUDE;

export const MOMENT_VISIBILITY_VALUES: readonly MomentVisibility[] = [
  MOMENT_VISIBILITY_PUBLIC,
  MOMENT_VISIBILITY_FRIENDS,
  MOMENT_VISIBILITY_PRIVATE,
  MOMENT_VISIBILITY_PARTIAL,
  MOMENT_VISIBILITY_EXCLUDE,
] as const;

export function momentVisibilityForRole(isStaff: boolean): MomentVisibility {
  return isStaff ? MOMENT_VISIBILITY_PUBLIC : MOMENT_VISIBILITY_FRIENDS;
}

export function isMomentPublic(m: {
  visibility?: string | null;
  notifyAll?: boolean | null;
}): boolean {
  if (m.visibility === MOMENT_VISIBILITY_PUBLIC) return true;
  // Legacy rows before visibility column / notifyAll staff posts.
  if (m.notifyAll === true && m.visibility !== MOMENT_VISIBILITY_PRIVATE) {
    return true;
  }
  return false;
}

export type MomentAclRow = {
  authorId: string;
  visibility?: string | null;
  notifyAll?: boolean | null;
  deletedAt?: Date | null;
  allowedUserIds?: string[] | null;
  deniedUserIds?: string[] | null;
};

export type MomentAclOpts = {
  /** Viewer muted these authors (不看他) — hide non-public Moments from feed. */
  mutedAuthorIds?: ReadonlySet<string>;
  /** Authors who hid this viewer (不让他看). */
  authorsHidingViewer?: ReadonlySet<string>;
};

/**
 * WeChat 朋友圈 ACL:
 * - public/official → everyone
 * - private → author only
 * - friends → author + mutual friends
 * - partial → author + allowedUserIds (must be friends)
 * - exclude → friends except deniedUserIds
 * - mute / hide-from apply to non-public Moments
 * - guests (no viewer) → public only
 */
export function canViewerSeeMoment(
  m: MomentAclRow,
  viewerId: string | null | undefined,
  friendAuthorIds: ReadonlySet<string>,
  opts: MomentAclOpts = {},
): boolean {
  if (m.deletedAt) return false;
  if (viewerId && m.authorId === viewerId) return true;
  if (isMomentPublic(m)) return true;
  if (!viewerId) return false;

  if (opts.mutedAuthorIds?.has(m.authorId)) return false;
  if (opts.authorsHidingViewer?.has(m.authorId)) return false;

  const visibility = (m.visibility ?? MOMENT_VISIBILITY_FRIENDS) as string;

  if (visibility === MOMENT_VISIBILITY_PRIVATE) return false;

  if (!friendAuthorIds.has(m.authorId)) return false;

  if (visibility === MOMENT_VISIBILITY_PARTIAL) {
    const allowed = m.allowedUserIds ?? [];
    return allowed.includes(viewerId);
  }

  if (visibility === MOMENT_VISIBILITY_EXCLUDE) {
    const denied = m.deniedUserIds ?? [];
    return !denied.includes(viewerId);
  }

  // friends (default) + unknown legacy → mutual friends
  return true;
}

/** Who should be considered for Moments fan-out (before mute prefs). */
export function momentNotifyAudienceIds(
  visibility: MomentVisibility,
  friendIds: readonly string[],
  allowedUserIds: readonly string[],
  deniedUserIds: readonly string[],
): string[] | 'all' {
  switch (visibility) {
    case MOMENT_VISIBILITY_PUBLIC:
      return 'all';
    case MOMENT_VISIBILITY_PRIVATE:
      return [];
    case MOMENT_VISIBILITY_PARTIAL: {
      const allowed = new Set(allowedUserIds);
      return friendIds.filter((id) => allowed.has(id));
    }
    case MOMENT_VISIBILITY_EXCLUDE: {
      const denied = new Set(deniedUserIds);
      return friendIds.filter((id) => !denied.has(id));
    }
    case MOMENT_VISIBILITY_FRIENDS:
      return [...friendIds];
    default: {
      const _exhaustive: never = visibility;
      return _exhaustive;
    }
  }
}
