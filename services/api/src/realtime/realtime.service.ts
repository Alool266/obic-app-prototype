// Made by Dr Ali
// Fan-out helpers — callers pass userIds; gateway owns Socket.IO rooms.
// Tracks which conversation each user is currently viewing (WeChat: no inbox).

import { Injectable } from '@nestjs/common';
import {
  RT_BADGE_HINT,
  RT_CALL_ENDED,
  RT_CALL_INCOMING,
  RT_CHAT_MESSAGE,
  RT_LIVE_LOCATION,
  RT_NOTIFICATION,
} from './realtime.events';

export type RealtimeEmitter = {
  emitToUsers: (userIds: string[], event: string, payload: unknown) => void;
};

@Injectable()
export class RealtimeService {
  private emitter: RealtimeEmitter | null = null;

  /** userId → conversationId currently open in ChatScreen. */
  private readonly viewingByUser = new Map<string, string>();

  /** Bound by RealtimeGateway on module init. */
  bind(emitter: RealtimeEmitter) {
    this.emitter = emitter;
  }

  /** Client reports open chat — suppress inbox/badge for that thread. */
  setViewing(userId: string, conversationId: string | null) {
    if (!userId) return;
    if (!conversationId) {
      this.viewingByUser.delete(userId);
      return;
    }
    this.viewingByUser.set(userId, conversationId);
  }

  clearViewing(userId: string) {
    this.viewingByUser.delete(userId);
  }

  isViewing(userId: string, conversationId: string | null | undefined): boolean {
    if (!userId || !conversationId) return false;
    return this.viewingByUser.get(userId) === conversationId;
  }

  /** Drop recipients who have that conversation open (WeChat parity). */
  filterNotViewing(
    userIds: string[],
    conversationId: string | null | undefined,
  ): string[] {
    if (!conversationId) return [...new Set(userIds.filter(Boolean))];
    return [...new Set(userIds.filter(Boolean))].filter(
      (id) => !this.isViewing(id, conversationId),
    );
  }

  publishChatMessage(options: {
    userIds: string[];
    conversationId: string;
    message: Record<string, unknown>;
    /** If set, badge:hint only goes to these users (muted chat = skip). */
    badgeUserIds?: string[];
  }) {
    const unique = [...new Set(options.userIds)].filter(Boolean);
    if (!unique.length || !this.emitter) return;
    // Always deliver the message to open chat UI — viewer still needs the row.
    this.emitter.emitToUsers(unique, RT_CHAT_MESSAGE, {
      conversationId: options.conversationId,
      message: options.message,
    });
    const badgeIds = this.filterNotViewing(
      options.badgeUserIds ?? options.userIds,
      options.conversationId,
    );
    if (badgeIds.length) {
      this.emitter.emitToUsers(badgeIds, RT_BADGE_HINT, {
        reason: 'chat',
        conversationId: options.conversationId,
      });
    }
  }

  publishNotification(options: {
    userIds: string[];
    notification: Record<string, unknown>;
  }) {
    const data = options.notification['data'];
    let convId: string | undefined;
    if (data && typeof data === 'object' && !Array.isArray(data)) {
      const raw = (data as Record<string, unknown>)['conversationId'];
      if (typeof raw === 'string' && raw.trim()) convId = raw.trim();
    }
    const unique = this.filterNotViewing(options.userIds, convId);
    if (!unique.length || !this.emitter) return;
    this.emitter.emitToUsers(unique, RT_NOTIFICATION, {
      notification: options.notification,
    });
    this.emitter.emitToUsers(unique, RT_BADGE_HINT, {
      reason: 'notification',
    });
  }

  publishBadgeHint(userIds: string[], reason: string) {
    const unique = [...new Set(userIds.filter(Boolean))];
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

  publishLiveLocation(userIds: string[], payload: Record<string, unknown>) {
    const unique = [...new Set(userIds)].filter(Boolean);
    if (!unique.length || !this.emitter) return;
    this.emitter.emitToUsers(unique, RT_LIVE_LOCATION, payload);
  }
}
