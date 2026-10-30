// Made by Dr Ali
// The greeting an employee should use. An assigned greeting wins. Otherwise the company greeting.

export const WELCOME_LIMIT = 20;

export type WelcomeSource = 'assigned' | 'company';

export type WelcomeText = {
  title: string;
  body: string;
  active: boolean;
};

export type WelcomeChoice = {
  title: string;
  body: string;
  source: WelcomeSource;
};

export function assertWelcomeTitle(value: string): string {
  const title = value.trim().replace(/\s+/g, ' ');
  if (!title || title.length > 40) throw new Error('WELCOME_TITLE');
  return title;
}

export function assertWelcomeBody(value: string): string {
  const body = value.trim();
  if (!body || body.length > 500) throw new Error('WELCOME_BODY');
  return body;
}

export function pickWelcome(assigned: WelcomeText | null, company: WelcomeText | null): WelcomeChoice | null {
  if (assigned?.active) {
    return { title: assigned.title, body: assigned.body, source: 'assigned' };
  }
  if (company?.active) {
    return { title: company.title, body: company.body, source: 'company' };
  }
  return null;
}
