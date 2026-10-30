'use client';
// Made by Dr Ali — Staff forms. Customers keep using the service request forms.

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

type OfficeForm = {
  id: string;
  nameEn: string;
  nameAr: string;
  nameZh: string;
  active: boolean;
  fields: Field[];
};

type Submission = {
  id: string;
  formNameEn: string;
  formNameAr: string;
  formNameZh: string;
  authorName: string;
  answers: Record<string, string>;
  fields: { key: string; labelEn: string; labelAr: string; labelZh: string }[];
  createdAt: string;
};

type Board = { forms: OfficeForm[]; submissions: Submission[] };

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

function formName(row: OfficeForm | Submission, lang: Lang): string {
  if ('nameEn' in row) {
    if (lang === 'ar') return row.nameAr;
    if (lang === 'zh') return row.nameZh;
    return row.nameEn;
  }
  if (lang === 'ar') return row.formNameAr;
  if (lang === 'zh') return row.formNameZh;
  return row.formNameEn;
}

function fieldLabel(field: Submission['fields'][number], lang: Lang): string {
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

export default function FormsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [nameEn, setNameEn] = useState('');
  const [nameAr, setNameAr] = useState('');
  const [nameZh, setNameZh] = useState('');
  const [fields, setFields] = useState<DraftField[]>([blankField()]);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    const next = (await adminFetch('/v1/admin/office-forms', token)) as Board;
    setBoard(next);
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

  function payload(active: boolean, source: DraftField[]) {
    return {
      nameEn: nameEn.trim(),
      nameAr: nameAr.trim(),
      nameZh: nameZh.trim(),
      active,
      fields: source.map((field) => ({
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
    };
  }

  async function saveNew() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !nameEn.trim() || !nameAr.trim() || !nameZh.trim()) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/office-forms', token, {
        method: 'POST',
        body: JSON.stringify(payload(true, fields)),
        totpCode: code,
      });
      setNameEn('');
      setNameAr('');
      setNameZh('');
      setFields([blankField()]);
      setNotice(t(lang, 'formsSaved'));
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function setActive(form: OfficeForm, active: boolean) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    const code = totpCode();
    if (code === null) return;
    setError(null);
    try {
      await adminFetch(`/v1/admin/office-forms/${form.id}`, token, {
        method: 'PATCH',
        body: JSON.stringify({
          nameEn: form.nameEn,
          nameAr: form.nameAr,
          nameZh: form.nameZh,
          active,
          fields: form.fields,
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

  return (
    <AdminShell active="forms" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'formsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'formsHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'formsDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{t(lang, 'formsNew')}</h2>
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
          <h3 style={{ marginTop: 16 }}>{t(lang, 'formsFields')}</h3>
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
                <select
                  value={field.type}
                  onChange={(e) => patchField(index, { type: e.target.value as FieldType })}
                >
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
              {saving ? t(lang, 'saving') : t(lang, 'formsSave')}
            </button>
          </div>
        </div>
      ) : null}

      {canReview(me) ? (
        <>
          <div className="web-card" style={{ marginBottom: 16 }}>
            {(board?.forms.length ?? 0) === 0 ? <p className="muted">{t(lang, 'formsNone')}</p> : null}
            {(board?.forms ?? []).map((form) => (
              <div key={form.id} style={{ marginBottom: 12 }}>
                <strong>{formName(form, lang)}</strong>{' '}
                <span className="muted">{form.active ? t(lang, 'formsActive') : t(lang, 'formsInactive')}</span>
                {isSuper ? (
                  <button type="button" style={{ marginInlineStart: 8 }} onClick={() => setActive(form, !form.active)}>
                    {form.active ? t(lang, 'formsInactive') : t(lang, 'formsActive')}
                  </button>
                ) : null}
                <div className="muted">
                  {form.fields.map((field) => fieldLabel(field, lang)).join(' · ')}
                </div>
              </div>
            ))}
          </div>
          <div className="web-card">
            <h2 style={{ marginBottom: 12 }}>{t(lang, 'formsSubmissions')}</h2>
            {(board?.submissions.length ?? 0) === 0 ? <p className="muted">{t(lang, 'formsNone')}</p> : null}
            <table className="web-table">
              <thead>
                <tr>
                  <th>{t(lang, 'formsAuthor')}</th>
                  <th>{t(lang, 'formsTitle')}</th>
                  <th>{t(lang, 'formsSubmissions')}</th>
                </tr>
              </thead>
              <tbody>
                {(board?.submissions ?? []).map((row) => (
                  <tr key={row.id}>
                    <td>{row.authorName}</td>
                    <td>
                      {formName(row, lang)}
                      <div className="muted">{row.createdAt.slice(0, 16).replace('T', ' ')}</div>
                    </td>
                    <td>
                      {row.fields
                        .map((field) => `${fieldLabel(field, lang)}: ${row.answers[field.key] || t(lang, 'none')}`)
                        .join(' · ')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      ) : null}
    </AdminShell>
  );
}
