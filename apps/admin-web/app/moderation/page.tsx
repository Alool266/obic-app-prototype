'use client';
// Made by Dr Ali — SuperAdmin content queue (reports + banned phrases).

import { FormEvent, useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { LANG_KEY, TOKEN_KEY } from '@/lib/session';

type Report = {
  id: string;
  source?: string;
  targetType?: string;
  snippet?: string;
  reason?: string;
  status?: string;
  createdAt?: string;
};

type Word = { id: string; phrase: string; category?: string; isActive?: boolean };

export default function ModerationPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [reports, setReports] = useState<Report[]>([]);
  const [words, setWords] = useState<Word[]>([]);
  const [phrase, setPhrase] = useState('');
  const [error, setError] = useState<string | null>(null);
  const onLang = useCallback((l: Lang) => setLang(l), []);

  const load = useCallback(async (token: string) => {
    const m = await adminFetch('/v1/admin/me', token);
    if (m.role !== 'SuperAdmin' && m.isSuperAdmin !== true) {
      throw new Error('Insufficient role');
    }
    const [r, w] = await Promise.all([
      adminFetch('/v1/admin/moderation/reports', token),
      adminFetch('/v1/admin/moderation/words', token),
    ]);
    setMe(m);
    setReports(Array.isArray(r) ? r : []);
    setWords(Array.isArray(w) ? w : []);
  }, []);

  useEffect(() => {
    const saved = sessionStorage.getItem(LANG_KEY) as Lang | null;
    if (saved === 'ar' || saved === 'en') setLang(saved);
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

  async function review(id: string, status: 'reviewed' | 'dismissed') {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    try {
      await adminFetch(`/v1/admin/moderation/reports/${id}`, token, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      });
      await load(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  async function addWord(e: FormEvent) {
    e.preventDefault();
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || phrase.trim().length < 3) return;
    try {
      await adminFetch('/v1/admin/moderation/words', token, {
        method: 'POST',
        body: JSON.stringify({ phrase: phrase.trim(), category: 'general' }),
      });
      setPhrase('');
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
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
    <AdminShell active="moderation" me={me} onLangChange={onLang}>
      <header className="web-head">
        <div>
          <h2>{t(lang, 'moderationTitle')}</h2>
          <p>{t(lang, 'moderationHint')}</p>
        </div>
      </header>
      <div className="web-card">
        {reports.length === 0 ? (
          <p className="web-note">{t(lang, 'moderationEmpty')}</p>
        ) : (
          <ul className="inbox-list">
            {reports.map((r) => (
              <li key={r.id} className={r.status === 'open' ? 'unread' : undefined}>
                <div>
                  <strong>
                    {r.source === 'auto' ? t(lang, 'sourceAuto') : t(lang, 'sourceUser')}
                    {' · '}
                    {r.targetType} · {r.status}
                  </strong>
                  <span>{r.snippet || r.reason || t(lang, 'none')}</span>
                  {r.status === 'open' ? (
                    <p className="mod-actions">
                      <button type="button" onClick={() => review(r.id, 'reviewed')}>
                        {t(lang, 'markReviewed')}
                      </button>
                      <button type="button" onClick={() => review(r.id, 'dismissed')}>
                        {t(lang, 'markDismissed')}
                      </button>
                    </p>
                  ) : null}
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
      <div className="web-card" style={{ marginTop: 16 }}>
        <h3>{t(lang, 'moderationWords')}</h3>
        <form onSubmit={addWord} className="mod-word-form">
          <input
            value={phrase}
            onChange={(ev) => setPhrase(ev.target.value)}
            minLength={3}
            placeholder={t(lang, 'addWord')}
          />
          <button type="submit" className="btn-primary">
            {t(lang, 'addWord')}
          </button>
        </form>
        <ul className="mod-words">
          {words.map((w) => (
            <li key={w.id}>
              <code>{w.phrase}</code>
              <small>{w.category}</small>
            </li>
          ))}
        </ul>
      </div>
    </AdminShell>
  );
}
