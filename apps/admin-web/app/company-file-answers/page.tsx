'use client';
// Made by Dr Ali — Answers from shared company documents. The customer catalog is not searched.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';

type AnswerRow = {
  id: string;
  question: string;
  answer: string;
  sources: string[];
  answeredBy: 'documents' | 'ai';
  createdAt: string;
  askerName: string | null;
};
type Board = { aiEnabled: boolean; rows: AnswerRow[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanyFileAnswersPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [question, setQuestion] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/company-file-answers', token)) as Board);
  }, []);

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    adminFetch('/v1/admin/me', token)
      .then((row) => {
        setMe(row);
        if (row.role !== 'Employee' && row.role !== 'SuperAdmin' && row.isSuperAdmin !== true) {
          router.replace('/dashboard');
          return;
        }
        if (!canReview(row)) return;
        return load(token);
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed'));
  }, [load, router]);

  async function ask() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !question.trim()) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/company-file-answers', token, {
        method: 'POST',
        body: JSON.stringify({ question: question.trim() }),
      });
      setNotice(t(lang, 'companyFileAnswersAsked'));
      setQuestion('');
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted">{t(lang, 'loading')}</p>
      </div>
    );
  }

  const rows = board?.rows ?? [];

  return (
    <AdminShell active="companyFileAnswers" me={me} onLangChange={onLang}>
      <div className="web-head">
        <div>
          <h1>{t(lang, 'companyFileAnswersTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyFileAnswersHint')}</p>
        </div>
      </div>
      {error ? <p className="err">{error}</p> : null}
      {notice ? <p className="muted staff-note">{notice}</p> : null}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyFileAnswersDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <label className="staff-filter grow" style={{ display: 'block' }}>
            {t(lang, 'companyFileAnswersQuestion')}
            <textarea
              value={question}
              maxLength={300}
              rows={3}
              onChange={(event) => setQuestion(event.target.value)}
              style={{ width: '100%', marginTop: 6 }}
            />
          </label>
          <button
            type="button"
            className="btn-primary sm"
            disabled={saving || !question.trim()}
            onClick={ask}
            style={{ marginTop: 12 }}
          >
            {saving ? t(lang, 'saving') : t(lang, 'companyFileAnswersAsk')}
          </button>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {rows.length === 0 ? <p className="muted">{t(lang, 'companyFileAnswersNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyFileAnswersQuestion')}</th>
                <th>{t(lang, 'companyFileAnswersAnswer')}</th>
                <th>{t(lang, 'companyFileAnswersSources')}</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>
                    {row.question}
                    {row.askerName ? ` · ${row.askerName}` : ''}
                  </td>
                  <td>
                    {row.answer}
                    <div className="muted">
                      {row.answeredBy === 'ai'
                        ? t(lang, 'companyFileAnswersFromAi')
                        : t(lang, 'companyFileAnswersFromDocuments')}
                    </div>
                  </td>
                  <td>{row.sources.join(', ')}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </AdminShell>
  );
}
