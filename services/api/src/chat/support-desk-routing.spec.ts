// Made by Dr Ali
import {
  DEFAULT_SUPPORT_BRANCH,
  resolveSupportBranch,
  resolveSupportDeskKey,
  supportDeskEmail,
  SUPPORT_DESK_KEY,
} from './support-desk-routing';

describe('support-desk-routing', () => {
  it('defaults branch to Yiwu', () => {
    expect(resolveSupportBranch(null)).toBe(DEFAULT_SUPPORT_BRANCH);
    expect(resolveSupportBranch('')).toBe('Yiwu');
    expect(resolveSupportBranch('  Guangzhou ')).toBe('Guangzhou');
  });

  it('builds secretary desk email for branch (seed pattern)', () => {
    expect(SUPPORT_DESK_KEY).toBe('secretary');
    expect(supportDeskEmail('Yiwu')).toBe('temp.yiwu.secretary@obic.local');
    expect(supportDeskEmail('Guangzhou')).toBe(
      'temp.guangzhou.secretary@obic.local',
    );
  });

  it('routes by branch + desk key', () => {
    expect(supportDeskEmail('Guangzhou', 'branchmgr')).toBe(
      'temp.guangzhou.branchmgr@obic.local',
    );
    expect(supportDeskEmail('Yiwu', 'scholarships')).toBe(
      'temp.yiwu.scholarships@obic.local',
    );
  });

  it('maps Form1 service slug to desk key then email', () => {
    expect(resolveSupportDeskKey('visa')).toBe('secretary');
    expect(resolveSupportDeskKey('business')).toBe('branchmgr');
    expect(resolveSupportDeskKey('travel')).toBe('marketing');
    expect(resolveSupportDeskKey('education')).toBe('scholarships');
    expect(resolveSupportDeskKey('logistics')).toBe('dataentry');
    expect(supportDeskEmail('Foshan', 'visa')).toBe(
      'temp.foshan.secretary@obic.local',
    );
    expect(supportDeskEmail('Hangzhou', 'business')).toBe(
      'temp.hangzhou.branchmgr@obic.local',
    );
  });

  it('accepts raw desk keys and falls back unknown to secretary', () => {
    expect(resolveSupportDeskKey('finance')).toBe('finance');
    expect(resolveSupportDeskKey('unknown-service')).toBe('secretary');
    expect(resolveSupportDeskKey(null)).toBe('secretary');
  });
});
