import { MigrationInterface, QueryRunner } from 'typeorm';

// ลืมรหัสผ่าน: รหัส 6 หลักที่ส่งทางอีเมล (คนละแถวต่อผู้ใช้)
export class AddPasswordResetCodes1760000000006 implements MigrationInterface {
  name = 'AddPasswordResetCodes1760000000006';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "password_reset_codes" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        "user_id" uuid NOT NULL,
        "code_hash" varchar(100) NOT NULL,
        "expires_at" timestamptz NOT NULL,
        "attempts" integer NOT NULL DEFAULT 0,
        "sent_at" timestamptz NOT NULL,
        CONSTRAINT "PK_password_reset_codes" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_password_reset_codes_user" UNIQUE ("user_id"),
        CONSTRAINT "FK_password_reset_codes_user" FOREIGN KEY ("user_id")
          REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "password_reset_codes"`);
  }
}
