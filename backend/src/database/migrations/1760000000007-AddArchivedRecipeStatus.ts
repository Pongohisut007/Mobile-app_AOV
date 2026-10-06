import { MigrationInterface, QueryRunner } from 'typeorm';

// สถานะ archived: สูตรที่เจ้าของลบแต่มีคนซื้อไปแล้ว เก็บไว้ให้ผู้ซื้อ (ลบจริงไม่ได้เพราะ order_items)
export class AddArchivedRecipeStatus1760000000007 implements MigrationInterface {
  name = 'AddArchivedRecipeStatus1760000000007';

  async up(queryRunner: QueryRunner): Promise<void> {
    // ตอน dev synchronize อาจเพิ่มค่าไปก่อนแล้ว
    await queryRunner.query(`
      ALTER TYPE "recipes_status_enum" ADD VALUE IF NOT EXISTS 'archived'
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    // Postgres ลบค่าออกจาก enum ไม่ได้ ย้ายสูตรที่เก็บไว้ไปเป็น hidden แทน (ผู้ซื้อยังเปิดได้เหมือนเดิม)
    await queryRunner.query(`
      UPDATE "recipes" SET "status" = 'hidden' WHERE "status" = 'archived'
    `);
  }
}
