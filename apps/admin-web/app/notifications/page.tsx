'use client';
// Made by Dr Ali — Staff inbox (own notifications only; same JWT as mobile).

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';

type Note = {
  id: string;
  type?: string;
  kind?: string;
  title?: string;
  body?: string;
  readAt?: string | null;
  createdAt?: string;
};

export default function NotificationsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [items, setItems] = useState<Note[]>([]);
  const [error, setError] = useState<string | null>(null);
  const onLang = useCallback((l: Lang) => setLang(l), []);

  const load = useCallback(async (token: string) => {
    const m = await adminFetch('/v1/admin/me', token);
    const n = await adminFetch('/v1/notifications', token);
    setMe(m);
    setItems(Array.isArray(n) ? n : []);
  }, []);

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    (async () => {
      try {
        await load(token);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed');
      }
    })();
  }, [router, load]);

  async function markRead(id: string) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    try {
      await adminFetch(`/v1/notifications/${id}/read`, token, {
        method: 'PATCH',
      });
      await load(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  if (error) {
    return (
      <div className="login-stage">
        <div className="login-card">
          <p className="err">{error}</p>
          <button type="button" className="btn-primary" onClick={() => router.replace('/')}>
            {t(lang, 'backLogin')}
          </button>
        </div>
      </div>
    );
  }

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted" style={{ color: '#e2e8f0' }}>
          {t(lang, 'loading')}
        </p>
      </div>
    );
  }

  return (
    <AdminShell active="notifications" me={me} onLangChange={onLang}>
      <header className="web-head">
        <div>
          <h2>{t(lang, 'inboxTitle')}</h2>
          <p>{t(lang, 'inboxHint')}</p>
        </div>
      </header>
      <div className="web-card">
        {items.length === 0 ? (
          <p className="web-note">{t(lang, 'inboxEmpty')}</p>
        ) : (
          <ul className="inbox-list">
            {items.map((n) => {
              const unread = !n.readAt;
              return (
                <li key={n.id} className={unread ? 'unread' : undefined}>
                  <button type="button" onClick={() => unread && markRead(n.id)}>
                    <strong>{n.title || t(lang, 'none')}</strong>
                    <span>{n.body || ''}</span>
                  </button>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </AdminShell>
  );
}
