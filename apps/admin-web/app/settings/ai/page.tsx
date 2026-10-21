'use client';
// Made by Dr Ali — SuperAdmin global AI auto-reply toggle (audited).

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';

type AiSettings = {
  aiEnabled?: boolean;
  envAutoReplyEnabled?: boolean;
  globalAutoReplyEnabled?: boolean;
  effectiveAutoReplyEnabled?: boolean;
  provider?: string | null;
  model?: string | null;
};

export default function AiSettingsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [settings, setSettings] = useState<AiSettings | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const onLang = useCallback((l: Lang) => setLang(l), []);

  const load = useCallback(async (token: string) => {
    const m = await adminFetch('/v1/admin/me', token);
    setMe(m);
    if (m.isSuperAdmin !== true) {
      setSettings(null);
      return;
    }
    const st = await adminFetch('/v1/admin/ai-settings', token);
    setSettings(st);
  }, []);

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    load(token).catch((e) => {
      setError(e instanceof Error ? e.message : t(lang, 'requestFailed'));
    });
  }, [router, load, lang]);

  async function toggleGlobal() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !settings) return;
    setBusy(true);
    setError(null);
    try {
      const next = !(settings.globalAutoReplyEnabled === true);
      const st = await adminFetch('/v1/admin/ai-settings', token, {
        method: 'PATCH',
        body: JSON.stringify({ globalAutoReplyEnabled: next }),
      });
      setSettings(st);
    } catch (e) {
      setError(e instanceof Error ? e.message : t(lang, 'requestFailed'));
    } finally {
      setBusy(false);
    }
  }

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted" style={{ color: '#e2e8f0' }}>
          {t(lang, 'loading')}
        </p>
      </div>
    );
  }

  const isSa = me.isSuperAdmin === true;

  return (
    <AdminShell active="settings" me={me} onLangChange={onLang}>
      <header className="web-head">
        <div>
          <h2>{t(lang, 'aiSettingsTitle')}</h2>
          <p>{t(lang, 'aiSettingsHint')}</p>
        </div>
      </header>

      {!isSa ? (
        <p className="err">{t(lang, 'totpDenied')}</p>
      ) : (
        <div className="web-card">
          {error && <p className="err">{error}</p>}
          {!settings ? (
            <p className="muted">{t(lang, 'loading')}</p>
          ) : (
            <>
              {settings.aiEnabled !== true && (
                <p className="web-note">{t(lang, 'aiDisabledEnv')}</p>
              )}
              <div
                style={{
                  display: 'flex',
                  flexWrap: 'wrap',
                  gap: 16,
                  alignItems: 'center',
                  justifyContent: 'space-between',
                }}
              >
                <div>
                  <div style={{ fontWeight: 700 }}>{t(lang, 'aiGlobalToggle')}</div>
                  <p className="muted" style={{ margin: '4px 0 0', fontSize: 13 }}>
                    {t(lang, 'aiEffective')}:{' '}
                    {settings.effectiveAutoReplyEnabled
                      ? t(lang, 'aiGlobalOn')
                      : t(lang, 'aiGlobalOff')}
                    {settings.provider
                      ? ` · ${t(lang, 'aiProvider')}: ${settings.provider}${
                          settings.model ? ` / ${settings.model}` : ''
                        }`
                      : ''}
                  </p>
                </div>
                <button
                  type="button"
                  className={`mini-btn ${
                    settings.globalAutoReplyEnabled ? 'primary' : ''
                  }`}
                  disabled={busy}
                  onClick={() => void toggleGlobal()}
                >
                  {settings.globalAutoReplyEnabled
                    ? t(lang, 'aiGlobalOn')
                    : t(lang, 'aiGlobalOff')}
                </button>
              </div>
              <p className="web-note" style={{ marginTop: 16 }}>
                {t(lang, 'aiSettingsHint')}
              </p>
            </>
          )}
        </div>
      )}
    </AdminShell>
  );
}
