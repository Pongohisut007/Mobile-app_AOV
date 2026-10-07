import { MigrationInterface, QueryRunner } from 'typeorm';

// กล่องแจ้งเตือนในแอป + เครื่องที่รับ push (FCM) + สวิตช์ push ของแต่ละบัญชี
export class AddNotifications1760000000008 implements MigrationInterface {
  name = 'AddNotifications1760000000008';

  async up(queryRunner: QueryRunner): Promise<void> {
    // ตอน dev synchronize อาจสร้าง enum ไว้ก่อนแล้ว
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "notifications_type_enum" AS ENUM (
          'recipe_purchased', 'recipe_moderated', 'recipe_reviewed', 'recipe_commented'
        );
      EXCEPTION WHEN duplicate_object THEN NULL;
      END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "device_tokens_platform_enum" AS ENUM ('android', 'ios');
      EXCEPTION WHEN duplicate_object THEN NULL;
      END $$
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "notifications" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "user_id" uuid NOT NULL,
        "actor_id" uuid,
        "type" "notifications_type_enum" NOT NULL,
        "recipe_id" uuid,
        "data" jsonb NOT NULL DEFAULT '{}',
        "read_at" TIMESTAMPTZ,
        CONSTRAINT "PK_notifications_id" PRIMARY KEY ("id"),
        CONSTRAINT "FK_notifications_user" FOREIGN KEY ("user_id")
          REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_notifications_actor" FOREIGN KEY ("actor_id")
          REFERENCES "users"("id") ON DELETE SET NULL,
        CONSTRAINT "FK_notifications_recipe" FOREIGN KEY ("recipe_id")
          REFERENCES "recipes"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_notifications_user_created_at"
      ON "notifications" ("user_id", "created_at")
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "device_tokens" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "user_id" uuid NOT NULL,
        "token" varchar(512) NOT NULL,
        "platform" "device_tokens_platform_enum" NOT NULL,
        "locale" varchar(8) NOT NULL DEFAULT 'th',
        "last_seen_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "PK_device_tokens_id" PRIMARY KEY ("id"),
        CONSTRAINT "FK_device_tokens_user" FOREIGN KEY ("user_id")
          REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "IDX_device_tokens_token"
      ON "device_tokens" ("token")
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_device_tokens_user_id"
      ON "device_tokens" ("user_id")
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "notification_settings" (
        "user_id" uuid NOT NULL,
        "push_enabled" boolean NOT NULL DEFAULT true,
        "sales" boolean NOT NULL DEFAULT true,
        "moderation" boolean NOT NULL DEFAULT true,
        "reviews" boolean NOT NULL DEFAULT true,
        "comments" boolean NOT NULL DEFAULT true,
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_notification_settings_user_id" PRIMARY KEY ("user_id"),
        CONSTRAINT "FK_notification_settings_user" FOREIGN KEY ("user_id")
          REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE IF EXISTS "notification_settings"');
    await queryRunner.query('DROP TABLE IF EXISTS "device_tokens"');
    await queryRunner.query('DROP TABLE IF EXISTS "notifications"');
    await queryRunner.query(
      'DROP TYPE IF EXISTS "device_tokens_platform_enum"',
    );
    await queryRunner.query('DROP TYPE IF EXISTS "notifications_type_enum"');
  }
}
