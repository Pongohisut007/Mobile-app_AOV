import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateRecipeComments1760000000000 implements MigrationInterface {
  name = 'CreateRecipeComments1760000000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "recipe_comments" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "recipe_id" uuid NOT NULL,
        "user_id" uuid NOT NULL,
        "comment" text NOT NULL,
        CONSTRAINT "PK_recipe_comments_id" PRIMARY KEY ("id"),
        CONSTRAINT "FK_recipe_comments_recipe" FOREIGN KEY ("recipe_id")
          REFERENCES "recipes"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_recipe_comments_user" FOREIGN KEY ("user_id")
          REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_recipe_comments_recipe_created_at"
      ON "recipe_comments" ("recipe_id", "created_at" DESC)
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE "recipe_comments"');
  }
}
