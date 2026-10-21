// Made by Dr Ali
// A collection stays editable until the first answer. After that, fields and people stay put.

import type { OfficeFieldDef } from '../office-forms/office-form';

export function sameCollectionFields(
  left: OfficeFieldDef[],
  right: OfficeFieldDef[],
): boolean {
  return JSON.stringify(left) === JSON.stringify(right);
}

export function sameCollectionAudience(left: string[], right: string[]): boolean {
  if (left.length !== right.length) return false;
  const a = [...left].sort();
  const b = [...right].sort();
  return a.every((id, index) => id === b[index]);
}

/** Once someone has answered, the field list and the audience cannot change. */
export function assertCollectionEdit(input: {
  responseCount: number;
  previousFields: OfficeFieldDef[];
  nextFields: OfficeFieldDef[];
  previousAudience: string[];
  nextAudience: string[];
}): void {
  if (input.responseCount === 0) return;
  const fieldsSame = sameCollectionFields(input.previousFields, input.nextFields);
  const audienceSame = sameCollectionAudience(
    input.previousAudience,
    input.nextAudience,
  );
  if (!fieldsSame || !audienceSame) {
    throw new Error('COLLECTION_LOCKED');
  }
}
