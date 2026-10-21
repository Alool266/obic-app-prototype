import {
  briefingMatchesLanguage,
  handoffLabels,
  summaryLanguage,
} from './obic-ai.constants';

describe('summaryLanguage', () => {
  it('follows the selected app language, not an English topic', () => {
    expect(summaryLanguage('ar')).toBe('ar');
    expect(summaryLanguage('zh-CN')).toBe('zh');
    expect(summaryLanguage('fr')).toBe('fr');
    expect(summaryLanguage('en')).toBe('en');
    expect(summaryLanguage(null)).toBe('en');
  });

  it('uses Arabic labels when the app is Arabic', () => {
    const labels = handoffLabels('ar');
    expect(labels.need).toBe('الحاجة');
    expect(labels.facts).toBe('أهم المعلومات');
    expect(labels.urgency).toBe('الاستعجال');
    expect(labels.medium).toBe('متوسط');
    expect(briefingMatchesLanguage('Need: Visa\nKey facts: —\nUrgency: medium', 'ar')).toBe(
      false,
    );
    expect(briefingMatchesLanguage('الحاجة: تأشيرة\nأهم المعلومات: —', 'ar')).toBe(true);
  });
});
