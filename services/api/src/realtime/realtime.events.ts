// Made by Dr Ali
// Socket.IO event names — keep Flutter client in sync.

/** Server → client: new chat message (open thread + list preview). */
export const RT_CHAT_MESSAGE = 'chat:message';

/** Server → client: soft hint to refresh shell badges / unread. */
export const RT_BADGE_HINT = 'badge:hint';

/** Server → client: new in-app notification row. */
export const RT_NOTIFICATION = 'notification:new';

/** Server → client: connection ack after JWT auth. */
export const RT_READY = 'realtime:ready';

/** Server → client: incoming voice/video call (Phase 5 Agora). */
export const RT_CALL_INCOMING = 'call:incoming';

/** Server → client: call ended / cancelled. */
export const RT_CALL_ENDED = 'call:ended';
