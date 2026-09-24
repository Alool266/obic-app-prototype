// Made by Dr Ali
// Widen the starter banned-word list (categories the customer named). SuperAdmin can still add more in Admin Web without a deploy.

import { MigrationInterface, QueryRunner } from 'typeorm';

const EXTRA: Array<{ phrase: string; category: string }> = [
  { phrase: 'ethnic cleansing', category: 'hate' },
  { phrase: 'hate crime', category: 'hate' },
  { phrase: 'تمييز عنصري', category: 'hate' },
  { phrase: 'خطاب كراهية', category: 'hate' },
  { phrase: 'explicit porn', category: 'sexual' },
  { phrase: 'nude leak', category: 'sexual' },
  { phrase: 'فيديو إباحي', category: 'sexual' },
  { phrase: 'محتوى جنسي', category: 'sexual' },
  { phrase: 'i will kill you', category: 'violence' },
  { phrase: 'go shoot them', category: 'violence' },
  { phrase: 'قتل جماعي', category: 'violence' },
  { phrase: 'تحريض على العنف', category: 'violence' },
  { phrase: 'join isis', category: 'terrorism' },
  { phrase: 'القاعدة', category: 'terrorism' },
  { phrase: 'fentanyl for sale', category: 'drugs' },
  { phrase: 'حشيش للبيع', category: 'drugs' },
  { phrase: 'unlicensed firearm', category: 'weapons' },
  { phrase: 'ذخيرة غير قانونية', category: 'weapons' },
  { phrase: 'ponzi scheme', category: 'fraud' },
  { phrase: 'غسيل أموال', category: 'fraud' },
  { phrase: 'ransomware kit', category: 'hacking' },
  { phrase: 'سرقة بيانات', category: 'hacking' },
];

export class BannedWordsWiden1765310000000 implements MigrationInterface {
  name = 'BannedWordsWiden1765310000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    for (const row of EXTRA) {
      await queryRunner.query(
        `INSERT INTO "banned_words" ("phrase", "category") VALUES ($1, $2)
         ON CONFLICT ("phrase") DO NOTHING`,
        [row.phrase, row.category],
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    for (const row of EXTRA) {
      await queryRunner.query(`DELETE FROM "banned_words" WHERE "phrase" = $1`, [
        row.phrase,
      ]);
    }
  }
}
