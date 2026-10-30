// Made by Dr Ali

import { pickWelcome, type WelcomeText } from './company-welcome';

const assigned: WelcomeText = { title: 'Mine', body: 'Hello from me', active: true };
const company: WelcomeText = { title: 'Company', body: 'Hello from OBIC', active: true };

describe('company welcome', () => {
  it('uses the assigned greeting when it is active', () => {
    expect(pickWelcome(assigned, company)?.source).toBe('assigned');
  });

  it('falls back to the company greeting when the assigned one is paused', () => {
    expect(pickWelcome({ ...assigned, active: false }, company)).toEqual({
      title: 'Company',
      body: 'Hello from OBIC',
      source: 'company',
    });
  });

  it('returns nothing when neither greeting is active', () => {
    expect(pickWelcome({ ...assigned, active: false }, { ...company, active: false })).toBeNull();
    expect(pickWelcome(null, null)).toBeNull();
  });
});
