// Made by Dr Ali
// System line written into an order thread when status changes.

export const ORDER_STATUS_NOTE = '[[status]]';

export function statusNoteBody(status: string): string {
  return `${ORDER_STATUS_NOTE}${status}`;
}

export function parseStatusNote(body: string | null | undefined): string | null {
  if (!body || !body.startsWith(ORDER_STATUS_NOTE)) return null;
  const status = body.slice(ORDER_STATUS_NOTE.length).trim();
  return status || null;
}
