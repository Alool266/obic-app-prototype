// Made by Dr Ali — prompt for Authenticator step-up code (privileged Admin actions).

export function promptTotpStepUp(message: string): string | null {
  if (typeof window === 'undefined') return null;
  const code = window.prompt(message);
  if (code == null) return null;
  const trimmed = code.trim();
  if (!/^\d{6}$/.test(trimmed)) return '';
  return trimmed;
}
