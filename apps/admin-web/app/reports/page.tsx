'use client';
// Made by Dr Ali — Daily, weekly, and monthly reports. Staff write them in the app.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Person = { id: string; name: string };
type Reviewer = { id: string; name: string };
type ReportRow = {
  id: string;
  kind: string;
  periodKey: string;
  done: string;
  plan: string;
  blockers: string;
  authorName: string;
};
type Board = {
  timezone: string;
  reviewers: Reviewer[];
  rows: ReportRow[];
};

function kindLabel(lang: Lang, kind: string): string {
  switch (kind) {
    case 'daily':
      return t(lang, 'reportsDaily');
    case 'weekly':
      return t(lang, 'reportsWeekly');
    case 'monthly':
      return t(lang, 'reportsMonthly');
    default:
      return kind;
  }
}

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function ReportsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [people, setPeople] = useState<Person[]>([]);
  const [kind, setKind] = useState('');
  const [timezone, setTimezone] = useState('Asia/Shanghai');
  const [reviewerIds, setReviewerIds] = useState<string[]>([]);
  const [pick, setPick] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string, nextKind?: string) => {
    const query = nextKind ? `?kind=${encodeURIComponent(nextKind)}` : '';
    const [next, staff] = await Promise.all([
      adminFetch(`/v1/admin/reports${query}`, token) as Promise<Board>,
      adminFetch('/v1/directory', token) as Promise<Person[]>,
    ]);
    setBoard(next);
    setPeople(staff);
    setTimezone(next.timezone);
    setReviewerIds(next.reviewers.map((row) => row.id));
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

  function totpCode(): string | undefined | null {
    if (me?.totpStepUpRequired !== true) return undefined;
    const code = promptTotpStepUp(t(lang, 'totpStepUpHint'));
    if (code == null) return null;
    if (!code) {
      setError(t(lang, 'totpStepUpInvalid'));
      return null;
    }
    return code;
  }

  async function saveReviewers() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/reports/reviewers', token, {
        method: 'PATCH',
        body: JSON.stringify({ timezone: timezone.trim(), reviewerIds }),
        totpCode: code,
      });
      setNotice(t(lang, 'reportsSaved'));
      await load(token, kind || undefined);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted">{error || '…'}</p>
      </div>
    );
  }

  const nameOf = (id: string) =>
    people.find((person) => person.id === id)?.name ||
    board?.reviewers.find((person) => person.id === id)?.name ||
    id;

  return (
    <AdminShell active="reports" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'reportsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'reportsHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'reportsDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{t(lang, 'reportsReviewers')}</h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'reportsTimezone')}
              <input value={timezone} onChange={(e) => setTimezone(e.target.value)} />
            </label>
            <label className="staff-filter grow">
              {t(lang, 'reportsReviewers')}
              <select value={pick} onChange={(e) => setPick(e.target.value)}>
                <option value="">{t(lang, 'reportsAdd')}</option>
                {people
                  .filter((person) => !reviewerIds.includes(person.id))
                  .map((person) => (
                    <option key={person.id} value={person.id}>
                      {person.name}
                    </option>
                  ))}
              </select>
            </label>
            <button
              type="button"
              className="btn-primary sm"
              onClick={() => {
                if (!pick || reviewerIds.includes(pick) || reviewerIds.length >= 12) return;
                setReviewerIds((current) => [...current, pick]);
                setPick('');
              }}
            >
              {t(lang, 'reportsAdd')}
            </button>
          </div>
          <ul>
            {reviewerIds.map((id) => (
              <li key={id}>
                {nameOf(id)}{' '}
                <button
                  type="button"
                  onClick={() => setReviewerIds((current) => current.filter((item) => item !== id))}
                >
                  {t(lang, 'cancel')}
                </button>
              </li>
            ))}
          </ul>
          <button type="button" className="btn-primary sm" disabled={saving} onClick={saveReviewers}>
            {saving ? t(lang, 'saving') : t(lang, 'reportsSave')}
          </button>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          <label className="staff-filter">
            {t(lang, 'reportsPeriod')}
            <select
              value={kind}
              onChange={(e) => {
                const next = e.target.value;
                setKind(next);
                const token = sessionStorage.getItem(TOKEN_KEY);
                if (token) {
                  load(token, next || undefined).catch((err) =>
                    setError(err instanceof Error ? err.message : 'Failed'),
                  );
                }
              }}
            >
              <option value="">{t(lang, 'reportsAll')}</option>
              <option value="daily">{t(lang, 'reportsDaily')}</option>
              <option value="weekly">{t(lang, 'reportsWeekly')}</option>
              <option value="monthly">{t(lang, 'reportsMonthly')}</option>
            </select>
          </label>
          {(board?.rows.length ?? 0) === 0 ? (
            <p className="muted">{t(lang, 'reportsNone')}</p>
          ) : (
            <table className="web-table" style={{ marginTop: 12 }}>
              <thead>
                <tr>
                  <th>{t(lang, 'reportsAuthor')}</th>
                  <th>{t(lang, 'reportsPeriod')}</th>
                  <th>{t(lang, 'reportsDone')}</th>
                  <th>{t(lang, 'reportsPlan')}</th>
                  <th>{t(lang, 'reportsBlockers')}</th>
                </tr>
              </thead>
              <tbody>
                {(board?.rows ?? []).map((row) => (
                  <tr key={row.id}>
                    <td>{row.authorName}</td>
                    <td>
                      {kindLabel(lang, row.kind)}
                      <div className="muted">{row.periodKey}</div>
                    </td>
                    <td>{row.done}</td>
                    <td>{row.plan}</td>
                    <td>{row.blockers || t(lang, 'none')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      ) : null}
    </AdminShell>
  );
}
