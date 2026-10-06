import { MigrationInterface, QueryRunner } from 'typeorm';

// เข้าสู่ระบบด้วย Google: ตารางบัญชีภายนอก + ผู้ใช้ที่สมัครผ่าน Google ไม่มีรหัสผ่าน
export class AddUserIdentities1760000000005 implements MigrationInterface {
  name = 'AddUserIdentities1760000000005';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "user_identities_provider_enum" AS ENUM ('google');
      EXCEPTION WHEN duplicate_object THEN NULL;
      END $$
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "user_identities" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        "user_id" uuid NOT NULL,
        "provider" "user_identities_provider_enum" NOT NULL,
        "provider_user_id" varchar(255) NOT NULL,
        "email" varchar(255),
        CONSTRAINT "PK_user_identities" PRIMARY KEY ("id"),
        CONSTRAINT "FK_user_identities_user" FOREIGN KEY ("user_id")
          REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "IDX_user_identities_provider_user"
      ON "user_identities" ("provider", "provider_user_id")
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "IDX_user_identities_user_provider"
      ON "user_identities" ("user_id", "provider")
    `);
    // คนที่สมัครผ่าน Google ยังไม่มีรหัสผ่าน (ตั้งทีหลังได้)
    await queryRunner.query(`
      ALTER TABLE "users" ALTER COLUMN "password_hash" DROP NOT NULL
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "user_identities"`);
    await queryRunner.query(
      `DROP TYPE IF EXISTS "user_identities_provider_enum"`,
    );
    // ผู้ใช้ที่ไม่มีรหัสผ่านต้องมีค่าก่อนตั้ง NOT NULL กลับ (ใส่ค่าที่ใช้เข้าสู่ระบบไม่ได้)
    await queryRunner.query(`
      UPDATE "users" SET "password_hash" = '!' WHERE "password_hash" IS NULL
    `);
    await queryRunner.query(`
      ALTER TABLE "users" ALTER COLUMN "password_hash" SET NOT NULL
    `);
  }
}
