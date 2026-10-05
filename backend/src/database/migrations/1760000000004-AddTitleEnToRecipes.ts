import { MigrationInterface, QueryRunner } from 'typeorm';

// ชื่อสูตรภาษาอังกฤษ ไม่บังคับ: สูตรเดิมยังไม่มี แอปจะแสดงชื่อไทยแทน
export class AddTitleEnToRecipes1760000000004 implements MigrationInterface {
  name = 'AddTitleEnToRecipes1760000000004';

  async up(queryRunner: QueryRunner): Promise<void> {
    // ตอน dev synchronize อาจเพิ่มคอลัมน์ไปก่อนแล้ว
    await queryRunner.query(`
      ALTER TABLE "recipes"
      ADD COLUMN IF NOT EXISTS "title_en" varchar(255)
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "recipes"
      DROP COLUMN IF EXISTS "title_en"
    `);
  }
}
