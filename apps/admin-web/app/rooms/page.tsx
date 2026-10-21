'use client';
// Made by Dr Ali — Meeting rooms. Staff book a time that no one else has taken.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Room = {
  id: string;
  nameEn: string;
  nameAr: string;
  nameZh: string;
  branchLabel: string | null;
  capacity: number;
  active: boolean;
};

type Booking = {
  id: string;
  roomId: string;
  title: string;
  startsAt: string;
  endsAt: string;
  bookerName: string;
  canCancel: boolean;
};

type Board = { rooms: Room[]; bookings: Booking[] };

function roomName(row: Room, lang: Lang): string {
  if (lang === 'ar') return row.nameAr;
  if (lang === 'zh') return row.nameZh;
  return row.nameEn;
}

function when(iso: string): string {
  const date = new Date(iso);
  const pad = (value: number) => String(value).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function RoomsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [nameEn, setNameEn] = useState('');
  const [nameAr, setNameAr] = useState('');
  const [nameZh, setNameZh] = useState('');
  const [branch, setBranch] = useState('');
  const [capacity, setCapacity] = useState('8');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/meeting-rooms', token)) as Board);
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

  async function saveRoom() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    const seats = Number(capacity);
    if (!token || !nameEn.trim() || !nameAr.trim() || !nameZh.trim() || !Number.isInteger(seats)) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/meeting-rooms', token, {
        method: 'POST',
        body: JSON.stringify({
          nameEn: nameEn.trim(),
          nameAr: nameAr.trim(),
          nameZh: nameZh.trim(),
          branchLabel: branch.trim(),
          capacity: seats,
          active: true,
        }),
        totpCode: code,
      });
      setNameEn('');
      setNameAr('');
      setNameZh('');
      setBranch('');
      setCapacity('8');
      setNotice(t(lang, 'roomsSaved'));
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function setActive(room: Room, active: boolean) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    const code = totpCode();
    if (code === null) return;
    setError(null);
    try {
      await adminFetch(`/v1/admin/meeting-rooms/${room.id}`, token, {
        method: 'PATCH',
        body: JSON.stringify({
          nameEn: room.nameEn,
          nameAr: room.nameAr,
          nameZh: room.nameZh,
          branchLabel: room.branchLabel ?? '',
          capacity: room.capacity,
          active,
        }),
        totpCode: code,
      });
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    }
  }

  async function cancel(id: string) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setError(null);
    try {
      await adminFetch(`/v1/meeting-rooms/bookings/${id}/cancel`, token, {
        method: 'POST',
        body: '{}',
      });
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

  const rooms = board?.rooms ?? [];
  const bookings = board?.bookings ?? [];

  return (
    <AdminShell active="rooms" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'roomsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'roomsHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'roomsDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{t(lang, 'roomsNew')}</h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'directoryNameEn')}
              <input value={nameEn} onChange={(e) => setNameEn(e.target.value)} />
            </label>
            <label className="staff-filter grow">
              {t(lang, 'directoryNameAr')}
              <input value={nameAr} onChange={(e) => setNameAr(e.target.value)} />
            </label>
            <label className="staff-filter grow">
              {t(lang, 'directoryNameZh')}
              <input value={nameZh} onChange={(e) => setNameZh(e.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'roomsBranch')}
              <input value={branch} onChange={(e) => setBranch(e.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'roomsCapacity')}
              <input type="number" min={1} max={200} value={capacity} onChange={(e) => setCapacity(e.target.value)} />
            </label>
          </div>
          <button type="button" className="btn-primary sm" disabled={saving} onClick={saveRoom} style={{ marginTop: 12 }}>
            {saving ? t(lang, 'saving') : t(lang, 'roomsSave')}
          </button>
        </div>
      ) : null}

      {canReview(me) ? (
        <>
          <div className="web-card" style={{ marginBottom: 16 }}>
            {rooms.length === 0 ? <p className="muted">{t(lang, 'roomsNone')}</p> : null}
            {rooms.map((room) => (
              <div key={room.id} style={{ marginBottom: 8 }}>
                <strong>{roomName(room, lang)}</strong>{' '}
                <span className="muted">
                  {room.capacity} · {room.branchLabel || t(lang, 'none')} ·{' '}
                  {room.active ? t(lang, 'roomsActive') : t(lang, 'roomsPaused')}
                </span>
                {isSuper ? (
                  <button type="button" style={{ marginInlineStart: 8 }} onClick={() => setActive(room, !room.active)}>
                    {room.active ? t(lang, 'roomsPaused') : t(lang, 'roomsActive')}
                  </button>
                ) : null}
              </div>
            ))}
          </div>
          <div className="web-card">
            <h2 style={{ marginBottom: 12 }}>{t(lang, 'roomsWhen')}</h2>
            {bookings.length === 0 ? <p className="muted">{t(lang, 'roomsNone')}</p> : null}
            <table className="web-table">
              <thead>
                <tr>
                  <th>{t(lang, 'roomsTitle')}</th>
                  <th>{t(lang, 'roomsWhen')}</th>
                  <th>{t(lang, 'roomsBooker')}</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {bookings.map((row) => {
                  const room = rooms.find((item) => item.id === row.roomId);
                  return (
                    <tr key={row.id}>
                      <td>
                        {row.title}
                        <div className="muted">{room ? roomName(room, lang) : ''}</div>
                      </td>
                      <td>
                        {when(row.startsAt)} – {when(row.endsAt)}
                      </td>
                      <td>{row.bookerName}</td>
                      <td>
                        {row.canCancel ? (
                          <button type="button" onClick={() => cancel(row.id)}>
                            {t(lang, 'roomsCancel')}
                          </button>
                        ) : null}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </>
      ) : null}
    </AdminShell>
  );
}
