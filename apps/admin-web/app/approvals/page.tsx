'use client';
// Made by Dr Ali — Approval templates and the requests staff can see.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Person = { id: string; name: string; staffTitle?: string | null };
type TemplateStep = { approverUserId: string; approverName: string };
type Template = {
  id: string;
  nameEn: string;
  nameAr: string;
  nameZh: string;
  active: boolean;
  steps: TemplateStep[];
};
type RequestStep = { approverName: string; status: string };
type ApprovalCard = {
  id: string;
  title: string;
  status: string;
  requesterName: string;
  templateNameEn: string;
  templateNameAr: string;
  templateNameZh: string;
  steps: RequestStep[];
};

function templateLabel(row: Template | ApprovalCard, lang: Lang): string {
  if ('nameAr' in row) {
    if (lang === 'ar') return row.nameAr;
    if (lang === 'zh') return row.nameZh;
    return row.nameEn;
  }
  if (lang === 'ar') return row.templateNameAr;
  if (lang === 'zh') return row.templateNameZh;
  return row.templateNameEn;
}

export default function ApprovalsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [people, setPeople] = useState<Person[]>([]);
  const [templates, setTemplates] = useState<Template[]>([]);
  const [requests, setRequests] = useState<ApprovalCard[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [nameEn, setNameEn] = useState('');
  const [nameAr, setNameAr] = useState('');
  const [nameZh, setNameZh] = useState('');
  const [approverIds, setApproverIds] = useState<string[]>([]);
  const [pick, setPick] = useState('');
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    const [templateRows, requestRows, staffRows] = await Promise.all([
      adminFetch('/v1/approvals/templates', token),
      adminFetch('/v1/approvals', token),
      adminFetch('/v1/directory', token),
    ]);
    setTemplates(templateRows as Template[]);
    setRequests(requestRows as ApprovalCard[]);
    setPeople(staffRows as Person[]);
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

  async function saveTemplate() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !nameEn.trim() || !nameAr.trim() || !nameZh.trim() || approverIds.length === 0) {
      return;
    }
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    try {
      await adminFetch('/v1/admin/approval-templates', token, {
        method: 'POST',
        body: JSON.stringify({
          nameEn: nameEn.trim(),
          nameAr: nameAr.trim(),
          nameZh: nameZh.trim(),
          approverIds,
        }),
        totpCode: code,
      });
      setNameEn('');
      setNameAr('');
      setNameZh('');
      setApproverIds([]);
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function setActive(row: Template, active: boolean) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    const code = totpCode();
    if (code === null) return;
    setError(null);
    try {
      await adminFetch(`/v1/admin/approval-templates/${row.id}`, token, {
        method: 'PATCH',
        body: JSON.stringify({ active }),
        totpCode: code,
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

  return (
    <AdminShell active="approvals" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'approvalsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'approvalsHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {isSuper ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{t(lang, 'approvalsNew')}</h2>
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
          <div className="staff-toolbar" style={{ marginTop: 12, alignItems: 'center' }}>
            <label className="staff-filter grow">
              {t(lang, 'approvalsApprovers')}
              <select value={pick} onChange={(e) => setPick(e.target.value)}>
                <option value="">{t(lang, 'approvalsAdd')}</option>
                {people
                  .filter((person) => !approverIds.includes(person.id))
                  .map((person) => (
                    <option key={person.id} value={person.id}>
                      {person.name}
                      {person.staffTitle ? ` · ${person.staffTitle}` : ''}
                    </option>
                  ))}
              </select>
            </label>
            <button
              type="button"
              className="btn-ghost sm"
              onClick={() => {
                if (!pick) return;
                setApproverIds((ids) => [...ids, pick]);
                setPick('');
              }}
            >
              {t(lang, 'approvalsAdd')}
            </button>
          </div>
          <ol style={{ margin: '12px 0' }}>
            {approverIds.map((id, index) => (
              <li key={id}>
                {index + 1}. {people.find((person) => person.id === id)?.name ?? id}{' '}
                <button
                  type="button"
                  className="btn-ghost sm"
                  onClick={() => setApproverIds((ids) => ids.filter((item) => item !== id))}
                >
                  ×
                </button>
              </li>
            ))}
          </ol>
          <button
            type="button"
            className="btn-primary sm"
            disabled={saving}
            onClick={() => void saveTemplate()}
          >
            {t(lang, 'approvalsSave')}
          </button>
        </div>
      ) : null}
      <div className="web-card" style={{ marginBottom: 16 }}>
        {templates.map((row) => (
          <div key={row.id} className="staff-toolbar" style={{ alignItems: 'center' }}>
            <div>
              <strong>{templateLabel(row, lang)}</strong>
              <div className="muted">
                {row.steps.map((step) => step.approverName).join(' → ')}
              </div>
            </div>
            {isSuper ? (
              <button
                type="button"
                className="btn-ghost sm"
                onClick={() => void setActive(row, !row.active)}
              >
                {row.active ? t(lang, 'approvalsActive') : t(lang, 'approvalsInactive')}
              </button>
            ) : (
              <span className="muted">
                {row.active ? t(lang, 'approvalsActive') : t(lang, 'approvalsInactive')}
              </span>
            )}
          </div>
        ))}
      </div>
      <div className="web-card staff-card">
        <h2 style={{ marginBottom: 12 }}>{t(lang, 'approvalsRequests')}</h2>
        {requests.length === 0 ? <p className="muted">{t(lang, 'approvalsNone')}</p> : null}
        {requests.map((row) => (
          <div key={row.id} style={{ marginBottom: 12 }}>
            <strong>{row.title}</strong>
            <div className="muted">
              {row.requesterName} · {templateLabel(row, lang)} · {row.status}
            </div>
            <div className="muted">
              {row.steps.map((step) => `${step.approverName} (${step.status})`).join(' → ')}
            </div>
          </div>
        ))}
      </div>
    </AdminShell>
  );
}
