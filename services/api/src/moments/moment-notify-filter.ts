// Made by Dr Ali
// Pure Moments notify recipient filter (unit-tested; used by prefs service).

export type MomentNotifyPrefsSnapshot = {
  userId: string;
  notifyEnabled: boolean;
  muteUpdates: boolean;
};

export type MomentFriendMuteSnapshot = {
  userId: string;
  mutedFriendId: string;
};

/**
 * Recipients who should get Moments badge/notify from [authorId].
 * Defaults: no prefs row ⇒ notify on; muted friend ⇒ excluded.
 */
export function filterMomentNotifyRecipients(
  candidateIds: string[],
  authorId: string,
  prefs: MomentNotifyPrefsSnapshot[],
  mutes: MomentFriendMuteSnapshot[],
): string[] {
  const unique = [...new Set(candidateIds)].filter(
    (id) => id && id !== authorId,
  );
  if (!unique.length) return [];

  const prefsByUser = new Map(prefs.map((p) => [p.userId, p]));
  const mutedSet = new Set(
    mutes
      .filter((m) => m.mutedFriendId === authorId)
      .map((m) => m.userId),
  );

  return unique.filter((id) => {
    if (mutedSet.has(id)) return false;
    const row = prefsByUser.get(id);
    if (!row) return true;
    if (!row.notifyEnabled || row.muteUpdates) return false;
    return true;
  });
}

/** Whether a single recipient wants Moments updates from author. */
export function shouldReceiveMomentNotify(
  recipientId: string,
  authorId: string,
  prefs: MomentNotifyPrefsSnapshot | null,
  mutedAuthor: boolean,
): boolean {
  if (recipientId === authorId) return false;
  if (mutedAuthor) return false;
  if (prefs && (!prefs.notifyEnabled || prefs.muteUpdates)) return false;
  return true;
}
