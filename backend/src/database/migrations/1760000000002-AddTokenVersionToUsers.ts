import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddTokenVersionToUsers1760000000002 implements MigrationInterface {
  name = 'AddTokenVersionToUsers1760000000002';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
      ADD COLUMN IF NOT EXISTS "token_version" integer NOT NULL DEFAULT 0
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
      DROP COLUMN "token_version"
    `);
  }
}
