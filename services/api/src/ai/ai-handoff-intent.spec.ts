// Made by Dr Ali — visa/order status + ref → auto Talk-to-staff.
import { shouldAutoRequestStaff } from './ai-handoff-intent';

describe('shouldAutoRequestStaff', () => {
  it('matches Arabic visa status with long ref', () => {
    expect(
      shouldAutoRequestStaff(
        'ما حالة التأشيرة رقم 1790244575128؟',
      ),
    ).toBe(true);
  });

  it('matches English visa track + number', () => {
    expect(
      shouldAutoRequestStaff('Please check visa status for 1790244575128'),
    ).toBe(true);
  });

  it('rejects short chat without status intent', () => {
    expect(shouldAutoRequestStaff('hello')).toBe(false);
  });

  it('rejects status without a reference number', () => {
    expect(shouldAutoRequestStaff('ما حالة التأشيرة؟')).toBe(false);
  });

  it('rejects a lone number without status/visa words', () => {
    expect(shouldAutoRequestStaff('1790244575128')).toBe(false);
  });
});
