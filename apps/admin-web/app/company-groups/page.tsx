'use client';
// Made by Dr Ali — Customer groups. A named set of company contacts, not a chat.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Member = { contactId: string; name: string };
type Group = {
  id: string;
  name: string;
  note: string | null;
  active: boolean;
  ownerUserId: string;
  ownerName: string | null;
  members: Member[];
};
type Person = { userId: string; name: string };
type Contact = { id: string; name: string; ownerUserId: string };
type Board = { people: Person[]; contacts: Contact[]; groups: Group[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanyGroupsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [ownerUserId, setOwnerUserId] = useState('');
  const [name, setName] = useState('');
  const [note, setNote] = useState('');
  const [active, setActive] = useState(true);
  const [contactIds, setContactIds] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/company-contact-groups', token)) as Board);
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
    setOwnerUserId('');
    setName('');
    setNote('');
    setActive(true);
    setContactIds([]);
  }

  function chooseOwner(id: string) {
    setOwnerUserId(id);
    const allowed = new Set((board?.contacts ?? []).filter((contact) => contact.ownerUserId === id).map((contact) => contact.id));
    setContactIds((current) => current.filter((contactId) => allowed.has(contactId)));
  }

  async function saveGroup() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !name.trim() || !ownerUserId) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(
        editingId ? `/v1/admin/company-contact-groups/${editingId}` : '/v1/admin/company-contact-groups',
        token,
        {
          method: editingId ? 'PATCH' : 'POST',
          body: JSON.stringify({
            ownerUserId,
            name: name.trim(),
            note: note.trim(),
            active,
            contactIds,
          }),
          totpCode: code,
        },
      );
      setNotice(t(lang, 'companyGroupsSaved'));
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
        <p className="muted">{error || '…'}</p>
      </div>
    );
  }

  const groups = board?.groups ?? [];
  const ownedContacts = (board?.contacts ?? []).filter((contact) => contact.ownerUserId === ownerUserId);

  return (
    <AdminShell active="companyGroups" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'companyGroupsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyGroupsHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyGroupsDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>
            {editingId ? t(lang, 'companyGroupsSave') : t(lang, 'companyGroupsNew')}
          </h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'companyGroupsOwner')}
              <select value={ownerUserId} onChange={(event) => chooseOwner(event.target.value)}>
                <option value="">—</option>
                {(board?.people ?? []).map((person) => (
                  <option key={person.userId} value={person.userId}>
                    {person.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="staff-filter grow">
              {t(lang, 'companyGroupsName')}
              <input value={name} maxLength={40} onChange={(event) => setName(event.target.value)} />
            </label>
            <label className="staff-filter grow">
              {t(lang, 'companyGroupsNote')}
              <input value={note} maxLength={200} onChange={(event) => setNote(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyGroupsActive')}
              <input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} />
            </label>
          </div>
          <div style={{ marginTop: 12 }}>
            {ownedContacts.map((contact) => (
              <label key={contact.id} style={{ marginInlineEnd: 12 }}>
                <input
                  type="checkbox"
                  checked={contactIds.includes(contact.id)}
                  onChange={(event) =>
                    setContactIds((current) => {
                      if (event.target.checked) {
                        return current.includes(contact.id) || current.length >= 80 ? current : [...current, contact.id];
                      }
                      return current.filter((id) => id !== contact.id);
                    })
                  }
                />{' '}
                {contact.name}
              </label>
            ))}
          </div>
          <div style={{ marginTop: 12 }}>
            <button type="button" className="btn-primary sm" disabled={saving} onClick={saveGroup}>
              {saving ? t(lang, 'saving') : t(lang, 'companyGroupsSave')}
            </button>{' '}
            {editingId ? (
              <button type="button" onClick={clearForm}>
                {t(lang, 'companyGroupsNew')}
              </button>
            ) : null}
          </div>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {groups.length === 0 ? <p className="muted">{t(lang, 'companyGroupsNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyGroupsName')}</th>
                <th>{t(lang, 'companyGroupsOwner')}</th>
                <th>{t(lang, 'companyGroupsMembers')}</th>
                <th />
                <th />
              </tr>
            </thead>
            <tbody>
              {groups.map((group) => (
                <tr key={group.id}>
                  <td>
                    {group.name}
                    {group.note ? <div className="muted">{group.note}</div> : null}
                  </td>
                  <td>{group.ownerName ?? '—'}</td>
                  <td>{group.members.map((member) => member.name).join(', ') || '—'}</td>
                  <td>{group.active ? t(lang, 'companyGroupsActive') : t(lang, 'companyGroupsPaused')}</td>
                  <td>
                    {isSuper ? (
                      <button
                        type="button"
                        onClick={() => {
                          setEditingId(group.id);
                          setOwnerUserId(group.ownerUserId);
                          setName(group.name);
                          setNote(group.note ?? '');
                          setActive(group.active);
                          setContactIds(group.members.map((member) => member.contactId));
                        }}
                      >
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
