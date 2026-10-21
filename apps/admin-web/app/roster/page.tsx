'use client';
// Made by Dr Ali — Staff joining and leaving. Confirming a leave does not close the login.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type RosterStatus = 'unrecorded' | 'active' | 'leaving' | 'left';

type RosterRow = {
  userId: string;
  name: string;
  staffTitle: string | null;
  branchLabel: string | null;
  status: RosterStatus;
  joinedOn: string | null;
  lastDay: string | null;
  leaveNote: string | null;
};

type Board = { today: string; rows: RosterRow[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

function statusLabel(lang: Lang, status: RosterStatus): string {
  switch (status) {
    case 'unrecorded':
      return t(lang, 'rosterUnrecorded');
    case 'active':
      return t(lang, 'rosterActive');
    case 'leaving':
      return t(lang, 'rosterLeaving');
    case 'left':
      return t(lang, 'rosterLeft');
    default: {
      const neverStatus: never = status;
      return neverStatus;
    }
  }
}

export default function RosterPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [userId, setUserId] = useState('');
  const [joinedOn, setJoinedOn] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/roster', token)) as Board);
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

  const joinable = (board?.rows ?? []).filter(
    (row) => row.status === 'unrecorded' || row.status === 'left',
  );

  async function recordJoin() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !userId || !joinedOn) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/roster/join', token, {
        method: 'POST',
        body: JSON.stringify({ userId, joinedOn }),
        totpCode: code,
      });
      setNotice(t(lang, 'rosterSaved'));
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function decide(id: string, action: 'confirm' | 'cancel') {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    const code = totpCode();
    if (code === null) return;
    setError(null);
    setNotice(null);
    try {
      const path =
        action === 'confirm'
          ? `/v1/admin/roster/${id}/confirm-leave`
          : `/v1/admin/roster/${id}/cancel-leave`;
      await adminFetch(path, token, {
        method: 'POST',
        body: '{}',
        totpCode: code,
      });
      setNotice(t(lang, 'rosterSaved'));
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    }
  }

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted">{error || '…'}</p>
      </div>
    );
  }

  const rows = board?.rows ?? [];

  return (
    <AdminShell active="roster" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'rosterTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'rosterHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'rosterDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{t(lang, 'rosterRecord')}</h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'name')}
              <select value={userId} onChange={(event) => setUserId(event.target.value)}>
                <option value="">—</option>
                {joinable.map((row) => (
                  <option key={row.userId} value={row.userId}>
                    {row.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="staff-filter">
              {t(lang, 'rosterJoined')}
              <input
                type="date"
                value={joinedOn}
                onChange={(event) => setJoinedOn(event.target.value)}
              />
            </label>
          </div>
          <button
            type="button"
            className="btn-primary sm"
            disabled={saving}
            onClick={recordJoin}
            style={{ marginTop: 12 }}
          >
            {saving ? t(lang, 'saving') : t(lang, 'rosterRecord')}
          </button>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {rows.length === 0 ? <p className="muted">{t(lang, 'rosterNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'name')}</th>
                <th>{t(lang, 'rosterStatus')}</th>
                <th>{t(lang, 'rosterJoined')}</th>
                <th>{t(lang, 'rosterLastDay')}</th>
                <th>{t(lang, 'rosterNote')}</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.userId}>
                  <td>
                    {row.name}
                    {row.staffTitle ? <div className="muted">{row.staffTitle}</div> : null}
                  </td>
                  <td>{statusLabel(lang, row.status)}</td>
                  <td>{row.joinedOn ?? '—'}</td>
                  <td>{row.lastDay ?? '—'}</td>
                  <td>{row.leaveNote ?? '—'}</td>
                  <td>
                    {isSuper && row.status === 'leaving' ? (
                      <>
                        <button
                          className="btn-primary sm"
                          type="button"
                          onClick={() => decide(row.userId, 'confirm')}
                        >
                          {t(lang, 'rosterConfirm')}
                        </button>{' '}
                        <button
                          className="btn-primary sm"
                          type="button"
                          onClick={() => decide(row.userId, 'cancel')}
                        >
                          {t(lang, 'rosterCancel')}
                        </button>
                      </>
                    ) : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </AdminShell>
  );
}
