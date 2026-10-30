// Made by Dr Ali

import {
  draftFromHits,
  FILE_EXCERPT_MAX,
  normalizeFileQuestion,
  rankCompanyDocuments,
} from './company-file-answer';

const LEAVE = {
  id: '6f0e2a10-0007-4000-8000-000000000001',
  title: 'Leave policy',
  body: 'Annual leave is 12 days. Apply before the trip.',
};
const KITCHEN = {
  id: '6f0e2a10-0007-4000-8000-000000000002',
  title: 'Kitchen',
  body: 'The lunch window is 12:00.',
};

describe('company file answers', () => {
  it('keeps a question and rejects a blank one', () => {
    expect(normalizeFileQuestion('  leave   policy ')).toBe('leave policy');
    expect(() => normalizeFileQuestion('   ')).toThrow('FILE_QUESTION');
  });

  it('ranks the document that contains the question', () => {
    const hits = rankCompanyDocuments('annual leave', [KITCHEN, LEAVE]);
    expect(hits.map((hit) => hit.title)).toEqual(['Leave policy']);
    expect(hits[0]?.excerpt.length).toBeLessThanOrEqual(FILE_EXCERPT_MAX);
    expect(draftFromHits(hits)).toContain('Leave policy');
    expect(rankCompanyDocuments('visa price', [LEAVE, KITCHEN])).toEqual([]);
    expect(draftFromHits([])).toBeNull();
  });

  it('matches Chinese phrases inside a document', () => {
    const hits = rankCompanyDocuments('出差申请', [
      {
        id: '6f0e2a10-0007-4000-8000-000000000003',
        title: '出差',
        body: '员工出差需要提前申请',
      },
    ]);
    expect(hits).toHaveLength(1);
    expect(hits[0]?.title).toBe('出差');
  });
});
