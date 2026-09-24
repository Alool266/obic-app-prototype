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
});
