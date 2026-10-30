// Made by Dr Ali
// Claims taken from a verified Google or Apple identity token.
// The client email is never accepted on its own.

export type SocialProvider = 'google' | 'apple';

export interface VerifiedSocialIdentity {
  provider: SocialProvider;
  subject: string;
  email: string | null;
  /** True only when the provider asserts the email is verified. */
  emailVerified: boolean;
  name: string | null;
}

export const PROVIDER_EMAIL_NOT_VERIFIED = 'PROVIDER_EMAIL_NOT_VERIFIED';
export const SOCIAL_LOGIN_ROLE_NOT_ALLOWED = 'SOCIAL_LOGIN_ROLE_NOT_ALLOWED';
export const GOOGLE_SIGN_IN_NOT_CONFIGURED = 'GOOGLE_SIGN_IN_NOT_CONFIGURED';
export const APPLE_SIGN_IN_NOT_CONFIGURED = 'APPLE_SIGN_IN_NOT_CONFIGURED';
export const INVALID_SOCIAL_TOKEN = 'INVALID_SOCIAL_TOKEN';

/** Comma-separated env audiences (web client, iOS client, Services ID, bundle ID). */
export function configuredAudiences(raw?: string | null): string[] {
  if (!raw?.trim()) return [];
  const seen = new Set<string>();
  for (const part of raw.split(',')) {
    const id = part.trim();
    if (id) seen.add(id);
  }
  return [...seen];
}

/**
 * Google sends a boolean. Apple sends boolean or the strings "true" / "false".
 * Anything else is not verified.
 */
export function isProviderEmailVerified(value: unknown): boolean {
  if (value === true) return true;
  if (typeof value === 'string') return value.trim().toLowerCase() === 'true';
  return false;
}

export function identityFromClaims(
  provider: SocialProvider,
  claims: {
    sub?: unknown;
    email?: unknown;
    email_verified?: unknown;
    name?: unknown;
  },
): VerifiedSocialIdentity {
  const subject = typeof claims.sub === 'string' ? claims.sub.trim() : '';
  if (!subject) {
    throw new Error(INVALID_SOCIAL_TOKEN);
  }

  let email: string | null = null;
  if (typeof claims.email === 'string') {
    const normalized = claims.email.trim().toLowerCase();
    if (normalized.includes('@')) email = normalized;
  }

  const emailVerified = Boolean(email) && isProviderEmailVerified(claims.email_verified);
  const name =
    typeof claims.name === 'string' && claims.name.trim().length >= 2
      ? claims.name.trim().slice(0, 120)
      : null;

  return {
    provider,
    subject,
    email,
    emailVerified,
    name,
  };
}
