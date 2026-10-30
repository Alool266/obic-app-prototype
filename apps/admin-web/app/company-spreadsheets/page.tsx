'use client';
// Made by Dr Ali — Shared spreadsheets. Cells are text. The latest save stays.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

const COLS = ['A', 'B', 'C', 'D', 'E', 'F'] as const;

type SheetRow = { id: string; title: string; active: boolean; editorName: string | null; updatedAt: string };
type SheetDetail = SheetRow & { rows: unknown };
type Board = { rows: SheetRow[] };

function blankGrid(): string[][] {
  return Array.from({ length: 12 }, () => Array.from({ length: COLS.length }, () => ''));
}

function asGrid(value: unknown): string[][] {
  const blank = blankGrid();
  if (!Array.isArray(value)) return blank;
  return blank.map((row, r) =>
    row.map((_, c) => {
      const source = value[r];
      if (!Array.isArray(source)) return '';
      const cell = source[c];
      return typeof cell === 'string' ? cell : '';
    }),
  );
}

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanySpreadsheetsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [active, setActive] = useState(true);
  const [grid, setGrid] = useState<string[][]>(blankGrid);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/company-spreadsheets', token)) as Board);
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

  function clearForm() {
    setEditingId(null);
    setTitle('');
    setActive(true);
    setGrid(blankGrid());
  }

  function setCell(r: number, c: number, value: string) {
    setGrid((current) => current.map((row, ri) => (ri === r ? row.map((cell, ci) => (ci === c ? value : cell)) : row)));
  }

  async function openSheet(id: string) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setError(null);
    try {
      const row = (await adminFetch(`/v1/admin/company-spreadsheets/${id}`, token)) as SheetDetail;
      setEditingId(row.id);
      setTitle(row.title);
      setActive(row.active);
      setGrid(asGrid(row.rows));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    }
  }

  async function save() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !title.trim()) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(
        editingId ? `/v1/admin/company-spreadsheets/${editingId}` : '/v1/admin/company-spreadsheets',
        token,
        {
          method: editingId ? 'PATCH' : 'POST',
          body: JSON.stringify({ title: title.trim(), active, rows: grid }),
          totpCode: code,
        },
      );
      setNotice(t(lang, 'companySpreadsheetsSaved'));
      clearForm();
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
  const showForm = canReview(me) && (isSuper || editingId);

  return (
    <AdminShell active="companySpreadsheets" me={me} onLangChange={onLang}>
      <div className="web-head">
        <div>
          <h1>{t(lang, 'companySpreadsheetsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companySpreadsheetsHint')}</p>
        </div>
      </div>
      {error ? <p className="err">{error}</p> : null}
      {notice ? <p className="muted staff-note">{notice}</p> : null}
      {!canReview(me) ? <p className="muted">{t(lang, 'companySpreadsheetsDenied')}</p> : null}

      {showForm ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>
            {editingId ? t(lang, 'companySpreadsheetsSave') : t(lang, 'companySpreadsheetsNew')}
          </h2>
          <label className="staff-filter grow">
            {t(lang, 'companySpreadsheetsName')}
            <input
              value={title}
              maxLength={40}
              disabled={!isSuper}
              onChange={(event) => setTitle(event.target.value)}
            />
          </label>
          <label style={{ display: 'block', marginTop: 12 }}>
            <input
              type="checkbox"
              checked={active}
              disabled={!isSuper}
              onChange={(event) => setActive(event.target.checked)}
            />{' '}
            {t(lang, 'companySpreadsheetsActive')}
          </label>
          <div style={{ overflowX: 'auto', marginTop: 12 }}>
            <table className="web-table">
              <thead>
                <tr>
                  <th />
                  {COLS.map((col) => (
                    <th key={col}>{col}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {grid.map((row, r) => (
                  <tr key={r}>
                    <th>{r + 1}</th>
                    {row.map((cell, c) => (
                      <td key={c}>
                        <input
                          value={cell}
                          maxLength={80}
                          disabled={!isSuper}
                          onChange={(event) => setCell(r, c, event.target.value)}
                          style={{ width: 96 }}
                        />
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {isSuper ? (
            <div style={{ marginTop: 12 }}>
              <button type="button" className="btn-primary sm" disabled={saving} onClick={save}>
                {saving ? t(lang, 'saving') : t(lang, 'companySpreadsheetsSave')}
              </button>{' '}
              {editingId ? (
                <button type="button" onClick={clearForm}>
                  {t(lang, 'companySpreadsheetsNew')}
                </button>
              ) : null}
            </div>
          ) : null}
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {rows.length === 0 ? <p className="muted">{t(lang, 'companySpreadsheetsNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companySpreadsheetsName')}</th>
                <th />
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>
                    {row.title}
                    {row.editorName ? ` · ${row.editorName}` : ''}
                  </td>
                  <td>{row.active ? t(lang, 'companySpreadsheetsActive') : t(lang, 'companySpreadsheetsPaused')}</td>
                  <td>
                    <button type="button" onClick={() => openSheet(row.id)}>
                      {t(lang, 'companySpreadsheetsSave')}
                    </button>
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
