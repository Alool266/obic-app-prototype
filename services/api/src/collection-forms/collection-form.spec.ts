// Made by Dr Ali

import type { OfficeFieldDef } from '../office-forms/office-form';
import { assertCollectionEdit } from './collection-form';

const field: OfficeFieldDef = {
  key: 'item_name',
  labelEn: 'Item',
  labelAr: 'البند',
  labelZh: '项目',
  type: 'short_text',
  required: true,
  options: [],
};

describe('collection edit', () => {
  it('allows a change before anyone has answered', () => {
    expect(() =>
      assertCollectionEdit({
        responseCount: 0,
        previousFields: [field],
        nextFields: [{ ...field, labelEn: 'Name' }],
        previousAudience: ['a'],
        nextAudience: ['b'],
      }),
    ).not.toThrow();
  });

  it('allows a rename of an open collection that already has answers', () => {
    expect(() =>
      assertCollectionEdit({
        responseCount: 2,
        previousFields: [field],
        nextFields: [{ ...field }],
        previousAudience: ['b', 'a'],
        nextAudience: ['a', 'b'],
      }),
    ).not.toThrow();
  });

  it('locks the fields and the people after the first answer', () => {
    expect(() =>
      assertCollectionEdit({
        responseCount: 1,
        previousFields: [field],
        nextFields: [field],
        previousAudience: ['a'],
        nextAudience: ['a', 'b'],
      }),
    ).toThrow('COLLECTION_LOCKED');
  });
});
