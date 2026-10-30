// Made by Dr Ali

import { assertOfficeFields, validateOfficeAnswers } from './office-form';

const name = {
  key: 'item_name',
  labelEn: 'Item',
  labelAr: 'البند',
  labelZh: '项目',
  required: true,
};

describe('office form', () => {
  it('keeps a choice field and drops a blank option', () => {
    const fields = assertOfficeFields([
      {
        ...name,
        type: 'choice',
        options: [' Yes ', '', 'No', 'Yes'],
      },
    ]);
    expect(fields[0].options).toEqual(['Yes', 'No']);
  });

  it('rejects two fields with the same key', () => {
    expect(() =>
      assertOfficeFields([
        { ...name, type: 'short_text', options: [] },
        { ...name, type: 'number', options: [] },
      ]),
    ).toThrow('FIELD_KEY');
  });

  it('rejects options on a text field', () => {
    expect(() =>
      assertOfficeFields([
        { ...name, type: 'short_text', options: ['A', 'B'] },
      ]),
    ).toThrow('FIELD_OPTIONS');
  });

  it('requires a required answer and checks the type', () => {
    const fields = assertOfficeFields([
      { ...name, type: 'number', options: [] },
      {
        key: 'note',
        labelEn: 'Note',
        labelAr: 'ملاحظة',
        labelZh: '备注',
        type: 'long_text',
        required: false,
        options: [],
      },
    ]);
    expect(() => validateOfficeAnswers(fields, {})).toThrow('FIELD_REQUIRED');
    expect(() => validateOfficeAnswers(fields, { item_name: 'abc' })).toThrow(
      'FIELD_NUMBER',
    );
    expect(validateOfficeAnswers(fields, { item_name: '12.5' })).toEqual({
      item_name: '12.5',
      note: '',
    });
  });

  it('accepts only a listed choice', () => {
    const fields = assertOfficeFields([
      { ...name, type: 'choice', options: ['Yes', 'No'] },
    ]);
    expect(() => validateOfficeAnswers(fields, { item_name: 'Maybe' })).toThrow(
      'FIELD_CHOICE',
    );
    expect(validateOfficeAnswers(fields, { item_name: 'Yes' }).item_name).toBe(
      'Yes',
    );
  });
});
