'use client';
// Made by Dr Ali — Company directory: departments and who can see whom.

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { OBIC_BRANCHES } from '@/lib/branches';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Department = {
  id: string;
  nameEn: string;
  nameAr: string;
  nameZh: string;
  branchLabel: string | null;
  visibility: 'company' | 'branch' | 'department';
  sortOrder: number;
};

type Person = {
  id: string;
  name: string;
  staffTitle?: string | null;
  branchLabel?: string | null;
  departmentId?: string | null;
  phone?: string | null;
  email?: string | null;
};

function deptLabel(dept: Department, lang: Lang): string {
  if (lang === 'ar') return dept.nameAr;
  if (lang === 'zh') return dept.nameZh;
  return dept.nameEn;
}

export default function DirectoryPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [people, setPeople] = useState<Person[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [nameEn, setNameEn] = useState('');
  const [nameAr, setNameAr] = useState('');
  const [nameZh, setNameZh] = useState('');
  const [branch, setBranch] = useState('');
  const [visibility, setVisibility] = useState<Department['visibility']>('branch');
  const [sortOrder, setSortOrder] = useState('100');
  const onLang = useCallback((next: Lang) => setLang(next), []);

  const isSuper =
    me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    const [deptRows, staffRows] = await Promise.all([
      adminFetch('/v1/admin/departments', token),
      adminFetch('/v1/directory', token),
    ]);
    setDepartments(deptRows as Department[]);
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

  const grouped = useMemo(() => {
    const buckets = new Map<string, Person[]>();
    for (const person of people) {
      const key = person.departmentId || 'none';
      const list = buckets.get(key) ?? [];
      list.push(person);
      buckets.set(key, list);
    }
    return buckets;
  }, [people]);

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

  async function createDepartment() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    if (!nameEn.trim() || !nameAr.trim() || !nameZh.trim()) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/departments', token, {
        method: 'POST',
        body: JSON.stringify({
          nameEn: nameEn.trim(),
          nameAr: nameAr.trim(),
          nameZh: nameZh.trim(),
          branchLabel: branch || null,
          visibility,
          sortOrder: Number(sortOrder) || 0,
        }),
        totpCode: code,
      });
      setNameEn('');
      setNameAr('');
      setNameZh('');
      setNotice(t(lang, 'directorySaved'));
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function changeVisibility(dept: Department, next: Department['visibility']) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || next === dept.visibility) return;
    const code = totpCode();
    if (code === null) return;
    setError(null);
    try {
      await adminFetch(`/v1/admin/departments/${dept.id}`, token, {
        method: 'PATCH',
        body: JSON.stringify({ visibility: next }),
        totpCode: code,
      });
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    }
  }

  async function assign(person: Person, departmentId: string) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    const code = totpCode();
    if (code === null) return;
    setError(null);
    try {
      await adminFetch(`/v1/admin/staff/${person.id}`, token, {
        method: 'PATCH',
        body: JSON.stringify({
          departmentId: departmentId || null,
        }),
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

  const orderedDepartments = [...departments].sort(
    (a, b) => a.sortOrder - b.sortOrder || a.nameEn.localeCompare(b.nameEn),
  );

  return (
    <AdminShell active="directory" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'directoryTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'directoryHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}

      {isSuper ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{t(lang, 'directoryNew')}</h2>
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
              {t(lang, 'directoryBranch')}
              <select value={branch} onChange={(e) => setBranch(e.target.value)}>
                <option value="">{t(lang, 'directoryAllBranches')}</option>
                {OBIC_BRANCHES.map((item) => (
                  <option key={item} value={item}>
                    {item}
                  </option>
                ))}
              </select>
            </label>
            <label className="staff-filter">
              {t(lang, 'directoryVisibility')}
              <select
                value={visibility}
                onChange={(e) => setVisibility(e.target.value as Department['visibility'])}
              >
                <option value="company">{t(lang, 'directoryVisCompany')}</option>
                <option value="branch">{t(lang, 'directoryVisBranch')}</option>
                <option value="department">{t(lang, 'directoryVisDepartment')}</option>
              </select>
            </label>
            <label className="staff-filter">
              {t(lang, 'directorySort')}
              <input
                value={sortOrder}
                inputMode="numeric"
                onChange={(e) => setSortOrder(e.target.value)}
              />
            </label>
            <button
              type="button"
              className="btn-primary sm"
              disabled={saving}
              onClick={() => void createDepartment()}
            >
              {t(lang, 'directorySave')}
            </button>
          </div>
        </div>
      ) : null}

      <div className="web-card staff-card" style={{ marginBottom: 16 }}>
        <h2 style={{ marginBottom: 12 }}>{t(lang, 'directoryPeople')}</h2>
        {people.length === 0 ? <p className="muted">{t(lang, 'directoryEmpty')}</p> : null}
        {orderedDepartments.map((dept) => {
          const members = grouped.get(dept.id) ?? [];
          return (
            <section key={dept.id} style={{ marginBottom: 18 }}>
              <div className="staff-toolbar" style={{ alignItems: 'center' }}>
                <strong>
                  {deptLabel(dept, lang)}
                  {dept.branchLabel ? ` · ${dept.branchLabel}` : ''}
                </strong>
                {isSuper ? (
                  <label className="staff-filter">
                    {t(lang, 'directoryVisibility')}
                    <select
                      value={dept.visibility}
                      onChange={(e) =>
                        void changeVisibility(dept, e.target.value as Department['visibility'])
                      }
                    >
                      <option value="company">{t(lang, 'directoryVisCompany')}</option>
                      <option value="branch">{t(lang, 'directoryVisBranch')}</option>
                      <option value="department">{t(lang, 'directoryVisDepartment')}</option>
                    </select>
                  </label>
                ) : (
                  <span className="muted">
                    {dept.visibility === 'company'
                      ? t(lang, 'directoryVisCompany')
                      : dept.visibility === 'department'
                        ? t(lang, 'directoryVisDepartment')
                        : t(lang, 'directoryVisBranch')}
                  </span>
                )}
              </div>
              {members.map((person) => (
                <PersonRow
                  key={person.id}
                  person={person}
                  departments={orderedDepartments}
                  lang={lang}
                  canAssign={isSuper}
                  onAssign={assign}
                />
              ))}
            </section>
          );
        })}
        <section>
          <strong>{t(lang, 'directoryUnassigned')}</strong>
          {(grouped.get('none') ?? []).map((person) => (
            <PersonRow
              key={person.id}
              person={person}
              departments={orderedDepartments}
              lang={lang}
              canAssign={isSuper}
              onAssign={assign}
            />
          ))}
        </section>
      </div>
    </AdminShell>
  );
}

function PersonRow({
  person,
  departments,
  lang,
  canAssign,
  onAssign,
}: {
  person: Person;
  departments: Department[];
  lang: Lang;
  canAssign: boolean;
  onAssign: (person: Person, departmentId: string) => Promise<void>;
}) {
  return (
    <div className="staff-toolbar" style={{ alignItems: 'center', marginTop: 8 }}>
      <div style={{ minWidth: 220 }}>
        <div>{person.name}</div>
        <div className="muted">
          {[person.staffTitle, person.branchLabel, person.phone, person.email]
            .filter(Boolean)
            .join(' · ')}
        </div>
      </div>
      {canAssign ? (
        <label className="staff-filter">
          {t(lang, 'directoryAssign')}
          <select
            value={person.departmentId || ''}
            onChange={(e) => void onAssign(person, e.target.value)}
          >
            <option value="">{t(lang, 'directoryUnassigned')}</option>
            {departments.map((dept) => (
              <option key={dept.id} value={dept.id}>
                {deptLabel(dept, lang)}
              </option>
            ))}
          </select>
        </label>
      ) : null}
    </div>
  );
}
