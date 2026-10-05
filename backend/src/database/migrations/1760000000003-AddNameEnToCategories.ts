import { MigrationInterface, QueryRunner } from 'typeorm';

// ชื่อภาษาอังกฤษของหมวดที่มีอยู่แล้ว (จับคู่ด้วย slug ไม่สนตัวพิมพ์เล็ก/ใหญ่)
export const CATEGORY_ENGLISH_NAMES: Record<string, string> = {
  'thai-food': 'Thai food',
  'single-dish': 'One-dish meals',
  'fire-chiken': 'Fried chicken',
  'good-food': 'Healthy food',
  'spicy-thai-salad': 'Spicy salads',
  noodles: 'Noodles',
  'bubble-tea': 'Milk tea',
  'made-to-order': 'Made to order',
  'dipping-sauce': 'Dipping sauces',
  grill: 'Grilled',
};

export class AddNameEnToCategories1760000000003 implements MigrationInterface {
  name = 'AddNameEnToCategories1760000000003';

  async up(queryRunner: QueryRunner): Promise<void> {
    // ตอน dev synchronize อาจเพิ่มคอลัมน์ไปก่อนแล้ว
    await queryRunner.query(`
      ALTER TABLE "categories"
      ADD COLUMN IF NOT EXISTS "name_en" varchar(100)
    `);
    for (const [slug, nameEn] of Object.entries(CATEGORY_ENGLISH_NAMES)) {
      await queryRunner.query(
        `UPDATE "categories" SET "name_en" = $1
         WHERE lower("slug") = $2 AND "name_en" IS NULL`,
        [nameEn, slug],
      );
    }
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "categories"
      DROP COLUMN IF EXISTS "name_en"
    `);
  }
}
