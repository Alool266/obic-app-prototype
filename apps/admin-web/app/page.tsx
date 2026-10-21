'use client';
// Made by Dr Ali — Admin Web login + SuperAdmin TOTP step.

import { FormEvent, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { adminFetch, login, verifyTotp, type Tokens } from '@/lib/api';
import { LANG_KEY, TOKEN_KEY } from '@/lib/session';
import { LanguageSwitcher } from '@/components/LanguageSwitcher';
import { Lang, pageDir, t } from '@/lib/i18n';

export default function LoginPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [totpSession, setTotpSession] = useState<string | null>(null);
  const [totpCode, setTotpCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const saved = sessionStorage.getItem(LANG_KEY) as Lang | null;
    if (saved === 'ar' || saved === 'en' || saved === 'zh' || saved === 'fr') {
      setLang(saved);
    }
  }, []);

  function applyLang(next: Lang) {
    setLang(next);
    sessionStorage.setItem(LANG_KEY, next);
  }

  async function finishLogin(accessToken: string) {
    await adminFetch('/v1/admin/me', accessToken);
    sessionStorage.setItem(TOKEN_KEY, accessToken);
    router.push('/dashboard');
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      if (totpSession) {
        const res = await verifyTotp(totpSession, totpCode.trim());
        await finishLogin(res.accessToken);
        return;
      }
      const res = await login(email.trim(), password);
      if ('requiresTotp' in res && res.requiresTotp) {
        setTotpSession(res.totpSession);
        setTotpCode('');
        return;
      }
      const tokens = res as Tokens & { user: { role: string; name: string } };
      await finishLogin(tokens.accessToken);
    } catch (err) {
      setError(err instanceof Error ? err.message : t(lang, 'loginFailed'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="login-stage" dir={pageDir(lang)} lang={lang}>
      <div className="login-layout">
        <aside className="login-aside">
          <h2>{t(lang, 'brand')}</h2>
          <p>{t(lang, 'loginAside')}</p>
        </aside>
      <form className="login-card" onSubmit={onSubmit}>
        <div className="login-brand">
          <div>
            <h1>{t(lang, 'loginTitle')}</h1>
            <p className="muted">
              {totpSession ? t(lang, 'totpHint') : t(lang, 'loginHint')}
            </p>
          </div>
          <div style={{ marginInlineStart: 'auto' }}>
            <LanguageSwitcher lang={lang} onChange={applyLang} variant="light" />
          </div>
        </div>

        {!totpSession ? (
          <>
            <label htmlFor="email">{t(lang, 'email')}</label>
            <input
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="username"
            />

            <label htmlFor="password">{t(lang, 'password')}</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
            />
          </>
        ) : (
          <>
            <label htmlFor="totp">{t(lang, 'totpCode')}</label>
            <input
              id="totp"
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={6}
              value={totpCode}
              onChange={(e) => setTotpCode(e.target.value.replace(/\D/g, ''))}
              placeholder="000000"
            />
            <button
              type="button"
              className="btn"
              style={{ marginTop: 8 }}
              onClick={() => {
                setTotpSession(null);
                setTotpCode('');
              }}
            >
              {t(lang, 'backLogin')}
            </button>
          </>
        )}

        {error && <p className="err">{error}</p>}

        <div className="login-actions">
          <button type="submit" className="btn-primary" disabled={busy}>
            {busy
              ? t(lang, 'signingIn')
              : totpSession
                ? t(lang, 'totpVerify')
                : t(lang, 'signIn')}
          </button>
        </div>
        <p className="muted" style={{ marginTop: 14 }}>
          {t(lang, 'designedBy')}
        </p>
      </form>
      </div>
    </div>
  );
}
