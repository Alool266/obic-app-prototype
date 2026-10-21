'use client';
// Made by Dr Ali — Company-owned customer contacts. Staff see the people assigned to them.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Contact = {
  id: string;
  name: string;
  phone: string | null;
  orgName: string | null;
  note: string | null;
  ownerUserId: string;
  ownerName: string | null;
  active: boolean;
};

type Person = { userId: string; name: string };

type Board = { people: Person[]; rows: Contact[] };

type Tag = { id: string; name: string; active: boolean };

type TagBoard = { tags: Tag[]; assignments: { contactId: string; tagIds: string[] }[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanyContactsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [tags, setTags] = useState<Tag[]>([]);
  const [assignments, setAssignments] = useState<Record<string, string[]>>({});
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>([]);
  const [query, setQuery] = useState('');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [ownerUserId, setOwnerUserId] = useState('');
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [orgName, setOrgName] = useState('');
  const [note, setNote] = useState('');
  const [active, setActive] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string, q: string) => {
    const path = q.trim()
      ? `/v1/admin/company-contacts?q=${encodeURIComponent(q.trim())}`
      : '/v1/admin/company-contacts';
    const [nextBoard, tagBoard] = await Promise.all([
      adminFetch(path, token) as Promise<Board>,
      adminFetch('/v1/admin/company-contact-tags', token) as Promise<TagBoard>,
    ]);
    const byContact: Record<string, string[]> = {};
    for (const row of tagBoard.assignments) byContact[row.contactId] = row.tagIds;
    setBoard(nextBoard);
    setTags(tagBoard.tags);
    setAssignments(byContact);
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
        return load(token, '');
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
    setOwnerUserId('');
    setName('');
    setPhone('');
    setOrgName('');
    setNote('');
    setActive(true);
    setSelectedTagIds([]);
  }

  function edit(row: Contact) {
    setEditingId(row.id);
    setOwnerUserId(row.ownerUserId);
    setName(row.name);
    setPhone(row.phone ?? '');
    setOrgName(row.orgName ?? '');
    setNote(row.note ?? '');
    setActive(row.active);
    setSelectedTagIds(assignments[row.id] ?? []);
  }

  async function saveContact() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !name.trim() || !ownerUserId) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    const body = JSON.stringify({
      ownerUserId,
      name: name.trim(),
      phone: phone.trim(),
      orgName: orgName.trim(),
      note: note.trim(),
      active,
    });
    try {
      const saved = (await adminFetch(
        editingId ? `/v1/admin/company-contacts/${editingId}` : '/v1/admin/company-contacts',
        token,
        { method: editingId ? 'PATCH' : 'POST', body, totpCode: code },
      )) as { id: string };
      await adminFetch(`/v1/admin/company-contact-tags/contacts/${saved.id}`, token, {
        method: 'PUT',
        body: JSON.stringify({ tagIds: selectedTagIds }),
        totpCode: code,
      });
      setNotice(t(lang, 'companyContactsSaved'));
      clearForm();
      await load(token, query);
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

  const rows = board?.rows ?? [];

  return (
    <AdminShell active="companyContacts" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'companyContactsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyContactsHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyContactsDenied')}</p> : null}

      {canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <div className="staff-toolbar" style={{ gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'companyContactsSearch')}
              <input value={query} onChange={(event) => setQuery(event.target.value)} />
            </label>
            <button
              type="button"
              className="btn-primary sm"
              onClick={() => {
                const token = sessionStorage.getItem(TOKEN_KEY);
                if (token) load(token, query).catch((err) => setError(err instanceof Error ? err.message : 'Failed'));
              }}
            >
              {t(lang, 'companyContactsSearch')}
            </button>
          </div>
        </div>
      ) : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>
            {editingId ? t(lang, 'companyContactsSave') : t(lang, 'companyContactsNew')}
          </h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'companyContactsOwner')}
              <select value={ownerUserId} onChange={(event) => setOwnerUserId(event.target.value)}>
                <option value="">—</option>
                {(board?.people ?? []).map((person) => (
                  <option key={person.userId} value={person.userId}>
                    {person.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="staff-filter grow">
              {t(lang, 'name')}
              <input value={name} maxLength={80} onChange={(event) => setName(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyContactsPhone')}
              <input value={phone} maxLength={32} onChange={(event) => setPhone(event.target.value)} />
            </label>
            <label className="staff-filter grow">
              {t(lang, 'companyContactsOrg')}
              <input value={orgName} maxLength={80} onChange={(event) => setOrgName(event.target.value)} />
            </label>
            <label className="staff-filter grow">
              {t(lang, 'companyContactsNote')}
              <input value={note} maxLength={500} onChange={(event) => setNote(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyContactsActive')}
              <input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} />
            </label>
          </div>
          <div style={{ marginTop: 12 }}>
            {tags
              .filter((tag) => tag.active || selectedTagIds.includes(tag.id))
              .map((tag) => (
                <label key={tag.id} style={{ marginInlineEnd: 12 }}>
                  <input
                    type="checkbox"
                    checked={selectedTagIds.includes(tag.id)}
                    onChange={(event) =>
                      setSelectedTagIds((current) => {
                        if (event.target.checked) {
                          return current.includes(tag.id) || current.length >= 8
                            ? current
                            : [...current, tag.id];
                        }
                        return current.filter((id) => id !== tag.id);
                      })
                    }
                  />{' '}
                  {tag.name}
                </label>
              ))}
          </div>
          <div style={{ marginTop: 12 }}>
            <button type="button" className="btn-primary sm" disabled={saving} onClick={saveContact}>
              {saving ? t(lang, 'saving') : t(lang, 'companyContactsSave')}
            </button>{' '}
            {editingId ? (
              <button type="button" onClick={clearForm}>
                {t(lang, 'companyContactsNew')}
              </button>
            ) : null}
          </div>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {rows.length === 0 ? <p className="muted">{t(lang, 'companyContactsNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'name')}</th>
                <th>{t(lang, 'companyContactsPhone')}</th>
                <th>{t(lang, 'companyContactsOrg')}</th>
                <th>{t(lang, 'companyContactsOwner')}</th>
                <th>{t(lang, 'companyTagsTitle')}</th>
                <th />
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>
                    {row.name}
                    {row.note ? <div className="muted">{row.note}</div> : null}
                  </td>
                  <td>{row.phone ?? '—'}</td>
                  <td>{row.orgName ?? '—'}</td>
                  <td>{row.ownerName ?? '—'}</td>
                  <td>
                    {(assignments[row.id] ?? [])
                      .map((id) => tags.find((tag) => tag.id === id)?.name)
                      .filter((label): label is string => Boolean(label))
                      .join(', ') || '—'}
                  </td>
                  <td>{row.active ? t(lang, 'companyContactsActive') : t(lang, 'companyContactsPaused')}</td>
                  <td>
                    {isSuper ? (
                      <button type="button" onClick={() => edit(row)}>
                        {t(lang, 'companyContactsEdit')}
                      </button>
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
