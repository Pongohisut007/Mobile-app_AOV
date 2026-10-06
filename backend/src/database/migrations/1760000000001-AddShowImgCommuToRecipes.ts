import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddShowImgCommuToRecipes1760000000001 implements MigrationInterface {
  name = 'AddShowImgCommuToRecipes1760000000001';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "recipes"
      ADD COLUMN IF NOT EXISTS "show_img_commu" boolean NOT NULL DEFAULT false
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "recipes"
      DROP COLUMN "show_img_commu"
    `);
  }
}
