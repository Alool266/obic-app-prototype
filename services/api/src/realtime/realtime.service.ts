// Made by Dr Ali
// Fan-out helpers — callers pass userIds; gateway owns Socket.IO rooms.

import { Injectable } from '@nestjs/common';
import {
  RT_BADGE_HINT,
  RT_CALL_ENDED,
  RT_CALL_INCOMING,
  RT_CHAT_MESSAGE,
  RT_NOTIFICATION,
} from './realtime.events';

export type RealtimeEmitter = {
  emitToUsers: (userIds: string[], event: string, payload: unknown) => void;
};

@Injectable()
export class RealtimeService {
  private emitter: RealtimeEmitter | null = null;

  /** Bound by RealtimeGateway on module init. */
  bind(emitter: RealtimeEmitter) {
    this.emitter = emitter;
  }

  publishChatMessage(options: {
    userIds: string[];
    conversationId: string;
    message: Record<string, unknown>;
  }) {
    const unique = [...new Set(options.userIds)].filter(Boolean);
    if (!unique.length || !this.emitter) return;
    this.emitter.emitToUsers(unique, RT_CHAT_MESSAGE, {
      conversationId: options.conversationId,
      message: options.message,
    });
    this.emitter.emitToUsers(unique, RT_BADGE_HINT, {
      reason: 'chat',
      conversationId: options.conversationId,
    });
  }

  publishNotification(options: {
    userIds: string[];
    notification: Record<string, unknown>;
  }) {
    const unique = [...new Set(options.userIds)].filter(Boolean);
    if (!unique.length || !this.emitter) return;
    this.emitter.emitToUsers(unique, RT_NOTIFICATION, {
      notification: options.notification,
    });
    this.emitter.emitToUsers(unique, RT_BADGE_HINT, {
      reason: 'notification',
    });
  }

  publishBadgeHint(userIds: string[], reason: string) {
    const unique = [...new Set(userIds)].filter(Boolean);
    if (!unique.length || !this.emitter) return;
    this.emitter.emitToUsers(unique, RT_BADGE_HINT, { reason });
  }

  publishCallIncoming(options: {
    userIds: string[];
    payload: Record<string, unknown>;
  }) {
    const unique = [...new Set(options.userIds)].filter(Boolean);
    if (!unique.length || !this.emitter) return;
    this.emitter.emitToUsers(unique, RT_CALL_INCOMING, options.payload);
  }

  publishCallEnded(options: {
    userIds: string[];
    payload: Record<string, unknown>;
  }) {
    const unique = [...new Set(options.userIds)].filter(Boolean);
    if (!unique.length || !this.emitter) return;
    this.emitter.emitToUsers(unique, RT_CALL_ENDED, options.payload);
  }
}
