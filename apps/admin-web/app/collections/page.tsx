'use client';
// Made by Dr Ali — One form sent to many staff. The desk reads every answer together.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type FieldType = 'short_text' | 'long_text' | 'number' | 'choice';

type Field = {
  key: string;
  labelEn: string;
  labelAr: string;
  labelZh: string;
  type: FieldType;
  required: boolean;
  options: string[];
};

type AnswerRow = {
  userId: string;
  name: string;
  answers: Record<string, string> | null;
};

type Collection = {
  id: string;
  nameEn: string;
  nameAr: string;
  nameZh: string;
  active: boolean;
  fields: Field[];
  responseCount: number;
  rows: AnswerRow[];
};

type Person = { id: string; name: string };

type DraftField = {
  key: string;
  labelEn: string;
  labelAr: string;
  labelZh: string;
  type: FieldType;
  required: boolean;
  options: string;
};

function blankField(): DraftField {
  return {
    key: '',
    labelEn: '',
    labelAr: '',
    labelZh: '',
    type: 'short_text',
    required: false,
    options: '',
  };
}

function collectionName(row: Collection, lang: Lang): string {
  if (lang === 'ar') return row.nameAr;
  if (lang === 'zh') return row.nameZh;
  return row.nameEn;
}

function fieldLabel(field: Field, lang: Lang): string {
  if (lang === 'ar') return field.labelAr;
  if (lang === 'zh') return field.labelZh;
  return field.labelEn;
}

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CollectionsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [collections, setCollections] = useState<Collection[]>([]);
  const [people, setPeople] = useState<Person[]>([]);
  const [selected, setSelected] = useState('');
  const [nameEn, setNameEn] = useState('');
  const [nameAr, setNameAr] = useState('');
  const [nameZh, setNameZh] = useState('');
  const [fields, setFields] = useState<DraftField[]>([blankField()]);
  const [audienceIds, setAudienceIds] = useState<string[]>([]);
  const [pick, setPick] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    const [board, staff] = await Promise.all([
      adminFetch('/v1/admin/collection-forms', token) as Promise<{ collections: Collection[] }>,
      adminFetch('/v1/directory', token) as Promise<Person[]>,
    ]);
    setCollections(board.collections);
    setPeople(staff);
    setSelected((current) => current || board.collections[0]?.id || '');
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

  async function saveNew() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !nameEn.trim() || !nameAr.trim() || !nameZh.trim() || audienceIds.length === 0) {
      return;
    }
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/collection-forms', token, {
        method: 'POST',
        body: JSON.stringify({
          nameEn: nameEn.trim(),
          nameAr: nameAr.trim(),
          nameZh: nameZh.trim(),
          active: true,
          audienceIds,
          fields: fields.map((field) => ({
            key: field.key.trim(),
            labelEn: field.labelEn.trim(),
            labelAr: field.labelAr.trim(),
            labelZh: field.labelZh.trim(),
            type: field.type,
            required: field.required,
            options:
              field.type === 'choice'
                ? field.options.split(',').map((item) => item.trim()).filter(Boolean)
                : [],
          })),
        }),
        totpCode: code,
      });
      setNameEn('');
      setNameAr('');
      setNameZh('');
      setFields([blankField()]);
      setAudienceIds([]);
      setNotice(t(lang, 'collectionSaved'));
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function setActive(form: Collection, active: boolean) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    const code = totpCode();
    if (code === null) return;
    setError(null);
    try {
      await adminFetch(`/v1/admin/collection-forms/${form.id}`, token, {
        method: 'PATCH',
        body: JSON.stringify({
          nameEn: form.nameEn,
          nameAr: form.nameAr,
          nameZh: form.nameZh,
          active,
          fields: form.fields,
          audienceIds: form.rows.map((row) => row.userId),
        }),
        totpCode: code,
      });
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    }
  }

  function patchField(index: number, patch: Partial<DraftField>) {
    setFields((current) => current.map((field, i) => (i === index ? { ...field, ...patch } : field)));
  }

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted">{error || '…'}</p>
      </div>
    );
  }

  const openCollection = collections.find((row) => row.id === selected) ?? collections[0];

  return (
    <AdminShell active="collections" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'collectionTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'collectionHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'collectionDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{t(lang, 'collectionNew')}</h2>
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
          </div>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12, marginTop: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'collectionPeople')}
              <select value={pick} onChange={(e) => setPick(e.target.value)}>
                <option value="">{t(lang, 'collectionAdd')}</option>
                {people
                  .filter((person) => !audienceIds.includes(person.id))
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
                if (!pick || audienceIds.includes(pick) || audienceIds.length >= 80) return;
                setAudienceIds((current) => [...current, pick]);
                setPick('');
              }}
            >
              {t(lang, 'collectionAdd')}
            </button>
          </div>
          <ul>
            {audienceIds.map((id) => (
              <li key={id}>
                {people.find((person) => person.id === id)?.name || id}{' '}
                <button type="button" onClick={() => setAudienceIds((current) => current.filter((item) => item !== id))}>
                  {t(lang, 'cancel')}
                </button>
              </li>
            ))}
          </ul>
          {fields.map((field, index) => (
            <div key={index} className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12, marginTop: 8 }}>
              <label className="staff-filter">
                {t(lang, 'formsKey')}
                <input value={field.key} onChange={(e) => patchField(index, { key: e.target.value })} />
              </label>
              <label className="staff-filter grow">
                {t(lang, 'directoryNameEn')}
                <input value={field.labelEn} onChange={(e) => patchField(index, { labelEn: e.target.value })} />
              </label>
              <label className="staff-filter grow">
                {t(lang, 'directoryNameAr')}
                <input value={field.labelAr} onChange={(e) => patchField(index, { labelAr: e.target.value })} />
              </label>
              <label className="staff-filter grow">
                {t(lang, 'directoryNameZh')}
                <input value={field.labelZh} onChange={(e) => patchField(index, { labelZh: e.target.value })} />
              </label>
              <label className="staff-filter">
                {t(lang, 'formsType')}
                <select value={field.type} onChange={(e) => patchField(index, { type: e.target.value as FieldType })}>
                  <option value="short_text">{t(lang, 'formsShort')}</option>
                  <option value="long_text">{t(lang, 'formsLong')}</option>
                  <option value="number">{t(lang, 'formsNumber')}</option>
                  <option value="choice">{t(lang, 'formsChoice')}</option>
                </select>
              </label>
              <label className="staff-filter">
                <input
                  type="checkbox"
                  checked={field.required}
                  onChange={(e) => patchField(index, { required: e.target.checked })}
                />{' '}
                {t(lang, 'formsRequired')}
              </label>
              {field.type === 'choice' ? (
                <label className="staff-filter grow">
                  {t(lang, 'formsOptions')}
                  <input value={field.options} onChange={(e) => patchField(index, { options: e.target.value })} />
                </label>
              ) : null}
            </div>
          ))}
          <div style={{ marginTop: 12, display: 'flex', gap: 8 }}>
            <button
              type="button"
              className="btn-primary sm"
              disabled={fields.length >= 12}
              onClick={() => setFields((current) => [...current, blankField()])}
            >
              {t(lang, 'formsAddField')}
            </button>
            <button type="button" className="btn-primary sm" disabled={saving} onClick={saveNew}>
              {saving ? t(lang, 'saving') : t(lang, 'collectionSave')}
            </button>
          </div>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {collections.length === 0 ? <p className="muted">{t(lang, 'collectionNone')}</p> : null}
          {collections.length > 0 ? (
            <label className="staff-filter">
              {t(lang, 'collectionTitle')}
              <select value={openCollection?.id ?? ''} onChange={(e) => setSelected(e.target.value)}>
                {collections.map((row) => (
                  <option key={row.id} value={row.id}>
                    {collectionName(row, lang)} ({row.responseCount}/{row.rows.length})
                  </option>
                ))}
              </select>
            </label>
          ) : null}
          {openCollection ? (
            <>
              <p>
                <span className="muted">
                  {openCollection.active ? t(lang, 'collectionOpen') : t(lang, 'collectionClosed')}
                </span>
                {isSuper ? (
                  <button
                    type="button"
                    style={{ marginInlineStart: 8 }}
                    onClick={() => setActive(openCollection, !openCollection.active)}
                  >
                    {openCollection.active ? t(lang, 'collectionClosed') : t(lang, 'collectionOpen')}
                  </button>
                ) : null}
              </p>
              <table className="web-table">
                <thead>
                  <tr>
                    <th>{t(lang, 'name')}</th>
                    {openCollection.fields.map((field) => (
                      <th key={field.key}>{fieldLabel(field, lang)}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {openCollection.rows.map((row) => (
                    <tr key={row.userId}>
                      <td>
                        {row.name}
                        <div className="muted">
                          {row.answers ? t(lang, 'collectionFilled') : t(lang, 'collectionMissing')}
                        </div>
                      </td>
                      {openCollection.fields.map((field) => (
                        <td key={field.key}>{row.answers?.[field.key] || t(lang, 'none')}</td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </>
          ) : null}
        </div>
      ) : null}
    </AdminShell>
  );
}
