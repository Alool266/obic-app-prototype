'use client';
// Made by Dr Ali
// Browser alerts for the open desk tab.
// Personal chats and calls follow the signed-in person.
// Customer requests follow the Yiwu Secretary (see customer-alert-routing.ts).

import { useEffect } from 'react';
import { adminFetch } from '@/lib/api';
import { isYiwuSecretary } from '@/lib/org';
import { TOKEN_KEY } from '@/lib/session';

type Row = Record<string, unknown>;

function text(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function preview(body: string): string {
  if (body.includes('[[obic:call:')) {
    const human = body
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('[[') && !line.includes('='));
    if (human.length) return human[human.length - 1].slice(0, 80);
    return 'Missed voice call';
  }
  if (!body) return 'New message';
  return body.length > 80 ? `${body.slice(0, 77)}…` : body;
}

function notify(title: string, body: string, href: string, tag: string) {
  if (typeof Notification === 'undefined' || Notification.permission !== 'granted') {
    return;
  }
  const note = new Notification(title || 'OBIC', { body, tag });
  note.onclick = () => {
    window.focus();
    if (href) window.location.assign(href);
    note.close();
  };
}

export function DeskAlerts() {
  useEffect(() => {
    const stored = sessionStorage.getItem(TOKEN_KEY);
    if (!stored) return;
    const token = stored;
    let stop = false;
    let myId = '';
    let secretary = false;
    let ready = false;
    const seenMessages = new Map<string, string>();
    const seenCalls = new Set<string>();
    const seenOrders = new Set<string>();
    const seenBugs = new Set<string>();

    async function tick() {
      if (stop) return;
      try {
        if (!myId) {
          const me = (await adminFetch('/v1/users/me', token)) as Row;
          myId = text(me.id);
          secretary = isYiwuSecretary({
            role: text(me.role),
            staffTitle: text(me.staffTitle) || null,
            branchLabel: text(me.branchLabel) || null,
            email: text(me.email) || null,
          });
          if (typeof Notification !== 'undefined' && Notification.permission === 'default') {
            void Notification.requestPermission();
          }
        }

        const threads = (await adminFetch('/v1/chat/threads', token)) as Row[];
        if (Array.isArray(threads)) {
          for (const thread of threads) {
            if (thread.muted === true) continue;
            const last = thread.lastMessage as Row | null | undefined;
            const messageId = text(last?.id);
            const threadId = text(thread.id);
            if (!messageId || !threadId) continue;
            const prev = seenMessages.get(threadId);
            seenMessages.set(threadId, messageId);
            if (!ready || prev === messageId) continue;
            if (text(last?.senderId) === myId) continue;
            const title = text(thread.title) || 'OBIC';
            notify(title, preview(text(last?.body)), '/oversight', `msg-${messageId}`);
          }
        }

        const calls = (await adminFetch('/v1/calls/incoming', token)) as Row[];
        const live = new Set<string>();
        if (Array.isArray(calls)) {
          for (const call of calls) {
            const id = text(call.callId);
            if (!id) continue;
            live.add(id);
            if (!ready || seenCalls.has(id)) continue;
            seenCalls.add(id);
            const name = text(call.fromName) || 'OBIC';
            const video = call.mode === 'video';
            notify(
              name,
              video ? 'Incoming video call' : 'Incoming voice call',
              '/oversight',
              `call-${id}`,
            );
          }
        }
        for (const id of [...seenCalls]) {
          if (!live.has(id)) seenCalls.delete(id);
        }

        if (secretary) {
          const orders = (await adminFetch('/v1/admin/orders', token)) as Row[];
          if (Array.isArray(orders)) {
            for (const order of orders) {
              const id = text(order.id);
              if (!id || text(order.userId) === myId) continue;
              if (!ready) {
                seenOrders.add(id);
                continue;
              }
              if (seenOrders.has(id)) continue;
              seenOrders.add(id);
              const who = text(order.customerName) || 'Customer';
              const label =
                text(order.subServiceNameEn) || text(order.serviceTitleEn) || 'a request';
              notify('New service request', `${who} submitted: ${label}`, '/orders', `order-${id}`);
            }
          }
          const bugs = (await adminFetch('/v1/admin/bug-reports', token)) as Row[];
          if (Array.isArray(bugs)) {
            for (const bug of bugs) {
              if (text(bug.status) !== 'open') continue;
              const id = text(bug.id);
              if (!id || text(bug.userId) === myId) continue;
              if (!ready) {
                seenBugs.add(id);
                continue;
              }
              if (seenBugs.has(id)) continue;
              seenBugs.add(id);
              const description = text(bug.description);
              notify(
                'New bug report',
                description ? description.slice(0, 80) : 'A customer sent a bug report',
                '/bug-reports',
                `bug-${id}`,
              );
            }
          }
        }
        ready = true;
      } catch {
        // Keep the desk usable if one poll fails.
      }
    }

    void tick();
    const timer = window.setInterval(() => void tick(), 4000);
    return () => {
      stop = true;
      window.clearInterval(timer);
    };
  }, []);

  return null;
}
