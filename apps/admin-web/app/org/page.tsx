'use client';
// Made by Dr Ali — Form2 org chart: branches, roster, service owners, locked workflow.

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import {
  FORM2_WORKFLOW_LOCKED_AT,
  ORG_BRANCHES,
  ORG_SERVICE_OWNERS,
  ORG_STAFF,
  ORG_WORKFLOW_RULES,
  branchLabel,
} from '@/lib/org';
import { TOKEN_KEY } from '@/lib/session';

export default function OrgPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [branchFilter, setBranchFilter] = useState<string>('all');
  const onLang = useCallback((l: Lang) => setLang(l), []);

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    adminFetch('/v1/admin/me', token)
      .then((m) => {
        setMe(m);
        if (m.isSuperAdmin !== true && m.role !== 'Employee') {
          router.replace('/dashboard');
        }
      })
      .catch((e) => setError(String(e)));
  }, [router]);

  const staffRows = useMemo(() => {
    if (branchFilter === 'all') return ORG_STAFF;
    return ORG_STAFF.filter((s) => s.branchId === branchFilter);
  }, [branchFilter]);

  if (!me) {
    return (
      <div className="app-root" style={{ padding: 40 }}>
        {error || t(lang, 'loading')}
      </div>
    );
  }

  const isSa = me.isSuperAdmin === true;

  return (
    <AdminShell active="org" me={me} onLangChange={onLang}>
      <header className="web-head">
        <div>
          <h2>{t(lang, 'orgTitle')}</h2>
          <p>{t(lang, 'orgHint')}</p>
        </div>
      </header>

      {!isSa ? (
        <div className="web-lock">{t(lang, 'orgEmpNote')}</div>
      ) : null}

      <div className="sign-banner">{t(lang, 'orgPendingBanner')}</div>

      <section className="org-section">
        <h3>{t(lang, 'orgBranches')}</h3>
        <div className="org-branch-grid">
          {ORG_BRANCHES.map((b) => (
            <article
              key={b.id}
              className={`org-branch-card${b.isPrimary ? ' primary' : ''}`}
            >
              <strong>
                {lang === 'ar' ? b.nameAr : lang === 'zh' ? b.nameZh : b.nameEn}
                {b.isPrimary ? (
                  <span className="org-pill">{t(lang, 'orgPrimary')}</span>
                ) : null}
              </strong>
              <span className="muted">
                {lang === 'ar' ? b.managerAr : b.managerEn}
              </span>
              <span className="mono">{b.id}</span>
            </article>
          ))}
        </div>
      </section>

      <section className="org-section">
        <h3>{t(lang, 'orgServiceOwners')}</h3>
        <div className="web-card">
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'orgService')}</th>
                <th>{t(lang, 'orgOwner')}</th>
                <th>{t(lang, 'branch')}</th>
                <th>{t(lang, 'notesLabel')}</th>
              </tr>
            </thead>
            <tbody>
              {ORG_SERVICE_OWNERS.map((o) => (
                <tr key={o.serviceKey}>
                  <td>{lang === 'ar' ? o.labelAr : o.labelEn}</td>
                  <td>{o.primaryStaff}</td>
                  <td>
                    <span className="branch-pill">
                      {branchLabel(o.branchId, lang === 'zh' ? 'zh' : lang)}
                    </span>
                  </td>
                  <td className="muted">{o.notesAr || '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="org-section">
        <div className="org-section-head">
          <h3>
            {t(lang, 'orgRoster')} ({staffRows.length})
          </h3>
          <label className="staff-filter">
            <span>{t(lang, 'branch')}</span>
            <select
              value={branchFilter}
              onChange={(e) => setBranchFilter(e.target.value)}
            >
              <option value="all">{t(lang, 'allBranches')}</option>
              {ORG_BRANCHES.map((b) => (
                <option key={b.id} value={b.id}>
                  {lang === 'ar' ? b.nameAr : b.nameEn}
                </option>
              ))}
            </select>
          </label>
        </div>
        <div className="web-card">
          <table className="web-table staff-table">
            <thead>
              <tr>
                <th>#</th>
                <th>{t(lang, 'name')}</th>
                <th>{t(lang, 'deskTitle')}</th>
                <th>{t(lang, 'branch')}</th>
                <th>{t(lang, 'orgSection')}</th>
              </tr>
            </thead>
            <tbody>
              {staffRows.map((s, i) => (
                <tr key={`${s.branchId}-${s.name}-${i}`}>
                  <td className="mono">{i + 1}</td>
                  <td>{s.name}</td>
                  <td>{lang === 'ar' ? s.titleAr : s.titleEn}</td>
                  <td>
                    <span className="branch-pill">
                      {branchLabel(s.branchId, lang === 'zh' ? 'zh' : lang)}
                    </span>
                  </td>
                  <td className="muted">{s.sectionAr || '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="org-section">
        <h3>
          {t(lang, 'orgWorkflow')}{' '}
          <span className="org-pill locked">{FORM2_WORKFLOW_LOCKED_AT}</span>
        </h3>
        <p className="muted">{t(lang, 'orgWorkflowHint')}</p>
        <ol className="org-workflow-list locked">
          {ORG_WORKFLOW_RULES.map((q) => (
            <li key={q.id}>
              <strong>{lang === 'ar' ? q.questionAr : q.questionEn}</strong>
              <p className="org-workflow-answer">
                {lang === 'ar' ? q.answerAr : q.answerEn}
              </p>
            </li>
          ))}
        </ol>
      </section>
    </AdminShell>
  );
}
