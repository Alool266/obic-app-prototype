// Made by Dr Ali
import { formatHandoffTitle, requestTopicLabel } from './handoff-title';

describe('handoff-title', () => {
  it('formats customer — request', () => {
    expect(formatHandoffTitle('DR aloosh', 'Visa inquiry')).toBe(
      'DR aloosh — Visa inquiry',
    );
  });

  it('prefers free note over service map', () => {
    expect(
      requestTopicLabel({ serviceKey: 'travel', note: 'Need hotel near market' }),
    ).toBe('Need hotel near market');
  });

  it('maps known service keys', () => {
    expect(requestTopicLabel({ serviceKey: 'visa' })).toBe('Visa inquiry');
    expect(requestTopicLabel({ serviceKey: 'travel' })).toBe('Travel inquiry');
  });
});
