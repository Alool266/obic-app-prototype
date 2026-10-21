'use client';
// Made by Dr Ali — real Admin Web desk (no fake Mac/browser chrome).

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { ReactNode, useCallback, useEffect, useMemo, useState } from 'react';
import { LANG_KEY, TOKEN_KEY } from '@/lib/session';
import { DeskAlerts } from '@/components/DeskAlerts';
import { LanguageSwitcher } from '@/components/LanguageSwitcher';
import { type CopyKey, Lang, pageDir, t } from '@/lib/i18n';

type Me = {
  name?: string;
  role?: string;
  isSuperAdmin?: boolean;
  opsAccess?: boolean;
  canOpenOps?: boolean;
  offersAccess?: boolean;
  canManageOffers?: boolean;
  totpEnabled?: boolean;
  totpEnrollRequired?: boolean;
  totpStepUpRequired?: boolean;
};

type Props = {
  active:
    | 'dashboard'
    | 'orders'
    | 'staff'
    | 'org'
    | 'directory'
    | 'approvals'
    | 'attendance'
    | 'reports'
    | 'forms'
    | 'collections'
    | 'rooms'
    | 'roster'
    | 'payslips'
    | 'companyContacts'
    | 'companyTags'
    | 'companyGroups'
    | 'companyWelcomes'
    | 'quickReplies'
    | 'companyHandovers'
    | 'companyDrive'
    | 'companyDocuments'
    | 'companySpreadsheets'
    | 'companyCalendar'
    | 'companyMail'
    | 'companyMeetings'
    | 'companyFileAnswers'
    | 'companyApps'
    | 'oversight'
    | 'ops'
    | 'notifications'
    | 'moderation'
    | 'bug-reports'
    | 'mini-apps'
    | 'prices'
    | 'registration'
    | 'vip'
    | 'accounts'
    | 'offers'
    | 'services'
    | 'settings';
  me: Me;
  children: ReactNode;
  onLangChange?: (lang: Lang) => void;
};

type Gate = 'all' | 'ops' | 'ops-dim' | 'sa' | 'sa-only' | 'offers' | 'accounts';

type NavLink = {
  id: Props['active'];
  href: string;
  label: CopyKey;
  lockedLabel?: CopyKey;
  gate: Gate;
};

type NavGroup = {
  id: string;
  label: CopyKey;
  links: NavLink[];
};

const NAV_GROUPS: NavGroup[] = [
  {
    id: 'desk',
    label: 'navGroupDesk',
    links: [
      { id: 'dashboard', href: '/dashboard', label: 'opsDash', gate: 'all' },
      { id: 'orders', href: '/orders', label: 'ordersNav', gate: 'all' },
      { id: 'ops', href: '/ops', label: 'internalOps', gate: 'ops-dim' },
      { id: 'notifications', href: '/notifications', label: 'inboxTitle', gate: 'all' },
      { id: 'bug-reports', href: '/bug-reports', label: 'bugReportsNav', gate: 'all' },
    ],
  },
  {
    id: 'hr',
    label: 'navGroupHr',
    links: [
      { id: 'directory', href: '/directory', label: 'directoryNav', gate: 'all' },
      { id: 'approvals', href: '/approvals', label: 'approvalsNav', gate: 'all' },
      { id: 'attendance', href: '/attendance', label: 'attendanceNav', gate: 'ops' },
      { id: 'reports', href: '/reports', label: 'reportsNav', gate: 'ops' },
      { id: 'roster', href: '/roster', label: 'rosterNav', gate: 'ops' },
      { id: 'payslips', href: '/payslips', label: 'payslipsNav', gate: 'ops' },
    ],
  },
  {
    id: 'forms',
    label: 'navGroupForms',
    links: [
      { id: 'forms', href: '/forms', label: 'formsNav', gate: 'ops' },
      { id: 'collections', href: '/collections', label: 'collectionNav', gate: 'ops' },
    ],
  },
  {
    id: 'meet',
    label: 'navGroupMeet',
    links: [
      { id: 'rooms', href: '/rooms', label: 'roomsNav', gate: 'ops' },
      { id: 'companyCalendar', href: '/company-calendar', label: 'companyCalendarNav', gate: 'ops' },
      { id: 'companyMail', href: '/company-mail', label: 'companyMailNav', gate: 'ops' },
      { id: 'companyMeetings', href: '/company-meetings', label: 'companyMeetingsNav', gate: 'ops' },
      { id: 'companyHandovers', href: '/company-handovers', label: 'companyHandoverNav', gate: 'ops' },
    ],
  },
  {
    id: 'files',
    label: 'navGroupFiles',
    links: [
      { id: 'companyDrive', href: '/company-drive', label: 'companyDriveNav', gate: 'ops' },
      { id: 'companyDocuments', href: '/company-documents', label: 'companyDocumentsNav', gate: 'ops' },
      { id: 'companySpreadsheets', href: '/company-spreadsheets', label: 'companySpreadsheetsNav', gate: 'ops' },
      { id: 'companyFileAnswers', href: '/company-file-answers', label: 'companyFileAnswersNav', gate: 'ops' },
    ],
  },
  {
    id: 'contacts',
    label: 'navGroupContacts',
    links: [
      { id: 'companyContacts', href: '/company-contacts', label: 'companyContactsNav', gate: 'ops' },
      { id: 'companyTags', href: '/company-tags', label: 'companyTagsNav', gate: 'ops' },
      { id: 'companyGroups', href: '/company-groups', label: 'companyGroupsNav', gate: 'ops' },
      { id: 'companyWelcomes', href: '/company-welcomes', label: 'companyWelcomesNav', gate: 'ops' },
      { id: 'quickReplies', href: '/quick-replies', label: 'quickRepliesNav', gate: 'ops' },
    ],
  },
  {
    id: 'apps',
    label: 'navGroupApps',
    links: [{ id: 'companyApps', href: '/company-apps', label: 'companyAppsNav', gate: 'ops' }],
  },
  {
    id: 'people',
    label: 'navGroupPeople',
    links: [
      { id: 'staff', href: '/staff', label: 'staffPriv', gate: 'all' },
      { id: 'org', href: '/org', label: 'orgNav', gate: 'all' },
      { id: 'accounts', href: '/accounts', label: 'accountsNav', gate: 'accounts' },
    ],
  },
  {
    id: 'catalog',
    label: 'navGroupCatalog',
    links: [
      { id: 'offers', href: '/offers', label: 'offersNav', gate: 'offers' },
      { id: 'services', href: '/services', label: 'servicesNav', gate: 'sa' },
      { id: 'mini-apps', href: '/mini-apps', label: 'miniAppsNav', gate: 'sa' },
      { id: 'prices', href: '/prices', label: 'pricesNav', gate: 'sa' },
      { id: 'registration', href: '/registration', label: 'registrationNav', gate: 'ops' },
      { id: 'vip', href: '/vip', label: 'vipNav', gate: 'ops' },
    ],
  },
  {
    id: 'safety',
    label: 'navGroupSafety',
    links: [
      {
        id: 'settings',
        href: '/settings/ai',
        label: 'systemSettingsAi',
        lockedLabel: 'systemSettings',
        gate: 'sa',
      },
      { id: 'settings', href: '/settings/totp', label: 'totpSettingsNav', gate: 'sa-only' },
      { id: 'moderation', href: '/moderation', label: 'moderationNav', gate: 'sa' },
      { id: 'oversight', href: '/oversight', label: 'chatOversight', gate: 'sa' },
    ],
  },
];

function canOpenOps(me: Me): boolean {
  if (me.canOpenOps === true) return true;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.role === 'Employee' && me.opsAccess === true) return true;
  return false;
}

function canManageOffers(me: Me): boolean {
  if (me.canManageOffers === true) return true;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  return me.role === 'Employee' && me.offersAccess === true;
}

function linkMode(
  gate: Gate,
  flags: { showOps: boolean; isSa: boolean; showOffers: boolean },
): 'link' | 'dim' | 'hide' {
  switch (gate) {
    case 'all':
      return 'link';
    case 'ops':
      return flags.showOps ? 'link' : 'hide';
    case 'ops-dim':
      return flags.showOps ? 'link' : 'dim';
    case 'sa':
      return flags.isSa ? 'link' : 'dim';
    case 'sa-only':
      return flags.isSa ? 'link' : 'hide';
    case 'offers':
      return flags.showOffers ? 'link' : 'dim';
    case 'accounts':
      return flags.showOps || flags.isSa ? 'link' : 'dim';
    default: {
      const neverGate: never = gate;
      return neverGate;
    }
  }
}

function isCurrent(link: NavLink, active: Props['active'], path: string): boolean {
  if (link.href === '/settings/ai') return path.startsWith('/settings/ai');
  if (link.href === '/settings/totp') return path.startsWith('/settings/totp');
  return link.id === active;
}

export function AdminShell({ active, me, children, onLangChange }: Props) {
  const router = useRouter();
  const path = usePathname();
  const [lang, setLang] = useState<Lang>('ar');
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState<Record<string, boolean>>({ desk: true });
  const isSa = me.isSuperAdmin === true;
  const showOps = canOpenOps(me);
  const showOffers = canManageOffers(me);
  const flags = useMemo(
    () => ({ showOps, isSa, showOffers }),
    [showOps, isSa, showOffers],
  );

  useEffect(() => {
    const saved = sessionStorage.getItem(LANG_KEY) as Lang | null;
    if (saved === 'ar' || saved === 'en' || saved === 'zh' || saved === 'fr') {
      setLang(saved);
      onLangChange?.(saved);
    } else {
      onLangChange?.('ar');
    }
  }, [onLangChange]);

  useEffect(() => {
    if (me.totpEnrollRequired === true && active !== 'settings') {
      router.replace('/settings/totp');
    }
  }, [me.totpEnrollRequired, active, router]);

  const groups = useMemo(() => {
    const q = query.trim().toLowerCase();
    return NAV_GROUPS.map((group) => ({
      ...group,
      links: group.links.filter((link) => {
        if (linkMode(link.gate, flags) === 'hide') return false;
        if (!q) return true;
        const label = t(lang, link.lockedLabel && linkMode(link.gate, flags) === 'dim' ? link.lockedLabel : link.label);
        return label.toLowerCase().includes(q);
      }),
    })).filter((group) => group.links.length > 0);
  }, [flags, lang, query]);

  useEffect(() => {
    const current = NAV_GROUPS.find((group) =>
      group.links.some((link) => isCurrent(link, active, path)),
    );
    if (!current) return;
    setOpen((prev) => (prev[current.id] ? prev : { ...prev, [current.id]: true }));
  }, [active, path]);

  const applyLang = useCallback(
    (next: Lang) => {
      setLang(next);
      sessionStorage.setItem(LANG_KEY, next);
      onLangChange?.(next);
    },
    [onLangChange],
  );

  function logout() {
    sessionStorage.removeItem(TOKEN_KEY);
    router.replace('/');
  }

  function toggleGroup(id: string) {
    setOpen((prev) => ({ ...prev, [id]: !prev[id] }));
  }

  const dir = pageDir(lang);
  const searching = query.trim().length > 0;
  const initial = (me.name || 'O').trim().charAt(0);

  return (
    <div className="app-root" dir={dir} lang={lang}>
      <DeskAlerts />
      <div className="web-shell">
        <aside className="web-side">
          <div className="web-logo-row">
            <div className="web-logo">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img className="web-logo-img" src="/obic-logo.png" alt="OBIC" width={34} height={34} />
              <strong>{t(lang, 'brand')}</strong>
            </div>
            <LanguageSwitcher lang={lang} onChange={applyLang} variant="side" />
          </div>
          <input
            className="nav-find"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder={t(lang, 'navFind')}
            aria-label={t(lang, 'navFind')}
          />
          <nav className="nav-scroll">
            {groups.length === 0 ? <p className="nav-empty">{t(lang, 'navNone')}</p> : null}
            {groups.map((group) => {
              const expanded = searching || open[group.id] === true;
              return (
                <section key={group.id} className={expanded ? 'nav-group open' : 'nav-group'}>
                  <button
                    type="button"
                    className="nav-group-btn"
                    aria-expanded={expanded}
                    onClick={() => toggleGroup(group.id)}
                  >
                    <span>{t(lang, group.label)}</span>
                    <span className="nav-chev" aria-hidden>
                      {expanded ? '–' : '+'}
                    </span>
                  </button>
                  {expanded ? (
                    <div className="nav-links">
                      {group.links.map((link) => {
                        const mode = linkMode(link.gate, flags);
                        const label = t(
                          lang,
                          mode === 'dim' && link.lockedLabel ? link.lockedLabel : link.label,
                        );
                        const current = isCurrent(link, active, path);
                        if (mode === 'dim') {
                          return (
                            <span key={link.href} className="dim nav-static">
                              {label}
                            </span>
                          );
                        }
                        return (
                          <Link
                            key={link.href}
                            href={link.href}
                            className={current ? 'on' : undefined}
                            aria-current={current ? 'page' : undefined}
                          >
                            {label}
                          </Link>
                        );
                      })}
                    </div>
                  ) : null}
                </section>
              );
            })}
          </nav>
          <div className="web-side-foot">
            <div className="side-user">
              <span className="side-avatar" aria-hidden>
                {initial}
              </span>
              <div className="side-user-meta">
                <strong>{me.name || t(lang, 'brand')}</strong>
                <span className={`role-chip ${isSa ? 'super' : 'emp'}`}>
                  {isSa ? t(lang, 'superAdmin') : t(lang, 'employee')}
                </span>
              </div>
            </div>
            <button type="button" className="side-logout" onClick={logout}>
              {t(lang, 'logout')}
            </button>
            <p className="credit-mini">{t(lang, 'designedBy')}</p>
          </div>
        </aside>
        <main className="web-main">{children}</main>
      </div>
    </div>
  );
}

export function useAdminLang(): [Lang, (l: Lang) => void] {
  const [lang, setLang] = useState<Lang>('ar');
  useEffect(() => {
    const saved = sessionStorage.getItem(LANG_KEY) as Lang | null;
    if (saved === 'ar' || saved === 'en' || saved === 'zh' || saved === 'fr') {
      setLang(saved);
    }
  }, []);
  const set = useCallback((l: Lang) => {
    setLang(l);
    sessionStorage.setItem(LANG_KEY, l);
  }, []);
  return [lang, set];
}
