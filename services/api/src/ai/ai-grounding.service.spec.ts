// Made by Dr Ali
import { AiGroundingService } from './ai-grounding.service';

describe('AiGroundingService', () => {
  const svc = new AiGroundingService();

  it('documents static corpus sources only (no user data)', () => {
    const meta = svc.corpusSources();
    expect(meta.faqCount).toBeGreaterThan(0);
    expect(meta.catalogParents).toBeGreaterThan(0);
    expect(meta.sources).toEqual([
      'services/api/src/ai/ai-grounding.faq.ts',
      'services/api/src/services/mega-catalog.seed.ts',
    ]);
  });

  it('does not embed other-user identifiers in grounding text', () => {
    const block = svc.retrieve('villa price housing', 'en');
    expect(block.toLowerCase()).toMatch(/catalog|price|from/i);
    expect(block).not.toMatch(/user[-_]?id/i);
    expect(block).not.toMatch(/@/);
    expect(block).not.toMatch(/\+?\d{8,}/);
  });

  it('returns catalog price when villa matches', () => {
    const block = svc.retrieve('How much for a villa rental?', 'en');
    expect(block).toMatch(/Villa/i);
    expect(block).toMatch(/800|From/i);
    expect(block).toMatch(/do not invent|listed prices/i);
  });

  it('FAQ talk-to-staff matches', () => {
    const block = svc.retrieve('أريد موظف بشري', 'ar');
    expect(block).toMatch(/موظف|تحدث|دعم/);
  });

  it('includes the full catalog for food, visa, healthcare, and logistics', () => {
    const block = svc.retrieve(
      'Comment demander un visa, de la nourriture, des soins et la logistique ?',
      'en',
    );
    expect(block).toContain('Food Delivery');
    expect(block).toContain('Visa');
    expect(block).toContain('Hospitals');
    expect(block).toContain('International Shipping');
    expect(block).toContain('Quality Inspection');
    expect(block).toContain('Demande :');
    expect(block).toContain('Yiwu');
    expect(block).toContain('Shanghai');
    expect(block).toContain('open-bank banner opens Business');
    expect(block).not.toContain('Bank Account');
    expect(block).not.toMatch(/SuperAdmin|Secretary \(GM\)|Visa Department Manager/);
  });

  it('uses the live active catalog when the API returns one', async () => {
    const live = new AiGroundingService({
      listActiveCatalogForAi: async () => [
        {
          slug: 'food',
          nameAr: 'طعام',
          nameEn: 'Food',
          nameZh: '餐饮',
          descAr: 'مطاعم',
          descEn: 'Dining',
          descZh: '餐饮',
          priceAr: 'من 10$',
          priceEn: 'From $10',
          priceZh: '$10起',
          subs: [
            {
              id: 'food-delivery',
              nameAr: 'توصيل طلبات',
              nameEn: 'Food Delivery',
              nameZh: '外卖配送',
              descAr: 'توصيل وجبات',
              descEn: 'Meal delivery',
              descZh: '送餐',
              priceAr: 'حسب الطلب',
              priceEn: 'On request',
              priceZh: '按需报价',
            },
          ],
        },
      ],
    } as unknown as ConstructorParameters<typeof AiGroundingService>[0]);
    const block = await live.retrieveForMessage('I want food delivery', 'en');
    expect(block).toContain('Food Delivery');
    expect(block).toContain('On request');
    expect(block).not.toContain('Quality Inspection');
  });

  it('falls back to the seed catalog when live services are unavailable', async () => {
    const fallback = new AiGroundingService({
      listActiveCatalogForAi: async () => {
        throw new Error('db down');
      },
    } as unknown as ConstructorParameters<typeof AiGroundingService>[0]);
    const block = await fallback.retrieveForMessage('healthcare visa logistics', 'zh');
    expect(block).toContain('医院');
    expect(block).toContain('签证');
    expect(block).toContain('国际');
  });
});
