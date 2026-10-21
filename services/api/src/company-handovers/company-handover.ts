// Made by Dr Ali
// A handover moves company contacts from one staff member to another.

export const HANDOVER_LIMIT = 200;

const UUID_V4 =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export type HandoverContactSnap = { id: string; name: string };

export function assertHandoverParties(fromUserId: string, toUserId: string): void {
  if (fromUserId === toUserId) throw new Error('HANDOVER_SAME');
}

export function assertHandoverIds(ids: readonly string[]): string[] {
  const unique: string[] = [];
  const seen = new Set<string>();
  for (const id of ids) {
    if (seen.has(id)) continue;
    seen.add(id);
    unique.push(id);
  }
  if (unique.length === 0) throw new Error('HANDOVER_EMPTY');
  if (unique.length > HANDOVER_LIMIT) throw new Error('HANDOVER_COUNT');
  return unique;
}

export function assertOptionalStaffId(value: string | undefined): string | null {
  const trimmed = (value ?? '').trim();
  if (!trimmed) return null;
  if (!UUID_V4.test(trimmed)) throw new Error('HANDOVER_STAFF');
  return trimmed;
}
