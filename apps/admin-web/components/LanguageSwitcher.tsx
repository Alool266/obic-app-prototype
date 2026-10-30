'use client';
// Made by Dr Ali — professional language menu (replaces the cycle-on-click chip).

import { useEffect, useRef, useState } from 'react';
import { LANG_OPTIONS, type Lang, t } from '@/lib/i18n';

type Props = {
  lang: Lang;
  onChange: (lang: Lang) => void;
  /** `side` = dark sidebar (AdminShell), `light` = white card (login). */
  variant?: 'side' | 'light';
};

function GlobeIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" aria-hidden focusable="false">
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.8" />
      <path
        d="M3 12h18M12 3c2.5 2.6 3.9 5.7 3.9 9S14.5 18.4 12 21c-2.5-2.6-3.9-5.7-3.9-9S9.5 5.6 12 3Z"
        stroke="currentColor"
        strokeWidth="1.8"
      />
    </svg>
  );
}

function ChevronIcon({ open }: { open: boolean }) {
  return (
    <svg
      width="12"
      height="12"
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden
      focusable="false"
      className={open ? 'lang-chev open' : 'lang-chev'}
    >
      <path
        d="m6 9 6 6 6-6"
        stroke="currentColor"
        strokeWidth="2.2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" aria-hidden focusable="false">
      <path
        d="m5 12.5 4.5 4.5L19 7.5"
        stroke="currentColor"
        strokeWidth="2.4"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function LanguageSwitcher({ lang, onChange, variant = 'light' }: Props) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const current = LANG_OPTIONS.find((o) => o.code === lang) ?? LANG_OPTIONS[0];

  useEffect(() => {
    if (!open) return;
    function onPointerDown(event: PointerEvent) {
      if (rootRef.current && !rootRef.current.contains(event.target as Node)) {
        setOpen(false);
      }
    }
    function onKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setOpen(false);
        buttonRef.current?.focus();
      }
    }
    document.addEventListener('pointerdown', onPointerDown);
    document.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('pointerdown', onPointerDown);
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [open ]);

  function pick(next: Lang) {
    setOpen(false);
    if (next !== lang) onChange(next);
    buttonRef.current?.focus();
  }

  return (
    <div className={`lang-switch ${variant}`} ref={rootRef}>
      <button
        type="button"
        ref={buttonRef}
        className="lang-switch-btn"
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-label={t(lang, 'language')}
        onClick={() => setOpen((v) => !v)}
      >
        <GlobeIcon />
        <span className="lang-switch-name">{current.native}</span>
        <ChevronIcon open={open} />
      </button>
      {open ? (
        <ul className="lang-menu" role="listbox" aria-label={t(lang, 'language')}>
          {LANG_OPTIONS.map((option) => {
            const selected = option.code === lang;
            return (
              <li key={option.code} role="presentation">
                <button
                  type="button"
                  role="option"
                  aria-selected={selected}
                  className={selected ? 'lang-item selected' : 'lang-item'}
                  onClick={() => pick(option.code)}
                >
                  <span className="lang-item-names">
                    <strong>{option.native}</strong>
                    <small>{option.english}</small>
                  </span>
                  {selected ? (
                    <span className="lang-item-check">
                      <CheckIcon />
                    </span>
                  ) : null}
                </button>
              </li>
            );
          })}
        </ul>
      ) : null}
    </div>
  );
}
