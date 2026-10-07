import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * โครงสร้างตั้งต้น (ก่อน 1760000000000) ให้ฐานข้อมูลว่างสร้างได้ด้วย migration อย่างเดียว
 *
 * - ตารางชุดแรกเดิมสร้างด้วย synchronize ตอน dev; migration ถัดจากนี้แค่ต่อเติม
 * - SQL ด้านล่างคือสิ่งที่ synchronize สร้าง ตัดส่วนที่ migration 0000-0008 สร้างเองออก
 *   (ชื่อ PK/FK/index จึงตรงกับฐานข้อมูลที่มีอยู่แล้ว)
 * - ฐานข้อมูลที่มีตาราง users อยู่แล้ว (staging/dev) ข้ามไปเฉย ๆ
 * - ห้ามแก้ไฟล์นี้หลังใช้งานแล้ว: เปลี่ยนโครงสร้างให้เพิ่ม migration ใหม่
 */
export class Baseline1750000000000 implements MigrationInterface {
  name = 'Baseline1750000000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    if (await queryRunner.hasTable('users')) return;

    for (const query of BASELINE_QUERIES) {
      await queryRunner.query(query);
    }
  }

  async down(): Promise<void> {
    // ไม่ย้อน baseline: เท่ากับลบทั้งฐานข้อมูล
  }
}

const BASELINE_QUERIES = [
  `CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`,

  // enums
  `CREATE TYPE "public"."users_role_enum" AS ENUM('user', 'creator', 'admin')`,
  `CREATE TYPE "public"."users_status_enum" AS ENUM('active', 'suspended', 'disabled')`,
  `CREATE TYPE "public"."recipes_difficulty_enum" AS ENUM('easy', 'medium', 'hard')`,
  `CREATE TYPE "public"."recipes_type_enum" AS ENUM('community', 'official')`,
  `CREATE TYPE "public"."recipes_status_enum" AS ENUM('draft', 'published', 'hidden', 'rejected')`,
  `CREATE TYPE "public"."recipe_contents_content_type_enum" AS ENUM('text', 'image', 'video', 'tip', 'warning')`,
  `CREATE TYPE "public"."recipe_access_access_type_enum" AS ENUM('purchase', 'free', 'promotion', 'admin_grant', 'gift')`,
  `CREATE TYPE "public"."orders_status_enum" AS ENUM('pending', 'paid', 'failed', 'cancelled', 'refunded')`,
  `CREATE TYPE "public"."payments_status_enum" AS ENUM('pending', 'processing', 'successful', 'failed', 'refunded')`,
  `CREATE TYPE "public"."reviews_status_enum" AS ENUM('published', 'hidden')`,

  // users
  `CREATE TABLE "users" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "email" character varying(255) NOT NULL, "password_hash" character varying(255) NOT NULL, "display_name" character varying(150) NOT NULL, "avatar_url" text, "role" "public"."users_role_enum" NOT NULL DEFAULT 'user', "status" "public"."users_status_enum" NOT NULL DEFAULT 'active', CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`,
  `CREATE UNIQUE INDEX "IDX_97672ac88f789774dd47f7c8be" ON "users" ("email")`,

  // categories
  `CREATE TABLE "categories" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "name" character varying(100) NOT NULL, "slug" character varying(120) NOT NULL, "description" text, "image_url" text, "is_active" boolean NOT NULL DEFAULT true, "sort_order" integer NOT NULL DEFAULT '0', CONSTRAINT "PK_24dbc6126a28ff948da33e97d3b" PRIMARY KEY ("id"))`,
  `CREATE UNIQUE INDEX "IDX_8b0be371d28245da6e4f4b6187" ON "categories" ("name")`,
  `CREATE UNIQUE INDEX "IDX_420d9f679d41281f282f5bc7d0" ON "categories" ("slug")`,

  // recipes
  `CREATE TABLE "recipes" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "creator_id" uuid NOT NULL, "title" character varying(255) NOT NULL, "slug" character varying(255) NOT NULL, "short_description" text, "cover_image_url" text, "price" numeric(12,2) NOT NULL DEFAULT '0', "preparation_minutes" integer, "cooking_minutes" integer, "serving_count" integer, "difficulty" "public"."recipes_difficulty_enum", "type" "public"."recipes_type_enum" NOT NULL DEFAULT 'community', "status" "public"."recipes_status_enum" NOT NULL DEFAULT 'draft', "published_at" TIMESTAMP WITH TIME ZONE, CONSTRAINT "chk_recipes_serving_count" CHECK ("serving_count" IS NULL OR "serving_count" > 0), CONSTRAINT "chk_recipes_cooking_minutes" CHECK ("cooking_minutes" IS NULL OR "cooking_minutes" >= 0), CONSTRAINT "chk_recipes_preparation_minutes" CHECK ("preparation_minutes" IS NULL OR "preparation_minutes" >= 0), CONSTRAINT "chk_recipes_price" CHECK ("price" >= 0), CONSTRAINT "PK_8f09680a51bf3669c1598a21682" PRIMARY KEY ("id"))`,
  `CREATE INDEX "IDX_8188b330b79f353885e77b9b14" ON "recipes" ("creator_id")`,
  `CREATE UNIQUE INDEX "IDX_caadb5cf11c752fa55aef594f0" ON "recipes" ("slug")`,
  `CREATE INDEX "IDX_4401a03086061354ecf4746942" ON "recipes" ("status")`,
  `CREATE TABLE "recipe_categories" ("recipe_id" uuid NOT NULL, "category_id" uuid NOT NULL, CONSTRAINT "PK_884e99b8acb3b0cbcdb4c584b92" PRIMARY KEY ("recipe_id", "category_id"))`,
  `CREATE INDEX "IDX_bc02c647e75da3c57a2d22903d" ON "recipe_categories" ("recipe_id")`,
  `CREATE INDEX "IDX_0849dba2a4b41b34c64fbc5df5" ON "recipe_categories" ("category_id")`,
  `CREATE TABLE "recipe_sections" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "recipe_id" uuid NOT NULL, "title" character varying(255) NOT NULL, "description" text, "sort_order" integer NOT NULL DEFAULT '0', "is_preview" boolean NOT NULL DEFAULT false, CONSTRAINT "chk_recipe_sections_sort_order" CHECK ("sort_order" >= 0), CONSTRAINT "PK_e971030cc5e48160eea967c10b6" PRIMARY KEY ("id"))`,
  `CREATE INDEX "IDX_ca22806b9398deaca8ae64bd25" ON "recipe_sections" ("recipe_id", "sort_order")`,
  `CREATE TABLE "recipe_contents" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "section_id" uuid NOT NULL, "content_type" "public"."recipe_contents_content_type_enum" NOT NULL, "title" character varying(255), "text_content" text, "media_url" text, "duration_seconds" integer, "sort_order" integer NOT NULL DEFAULT '0', CONSTRAINT "chk_recipe_contents_duration" CHECK ("duration_seconds" IS NULL OR "duration_seconds" >= 0), CONSTRAINT "chk_recipe_contents_sort_order" CHECK ("sort_order" >= 0), CONSTRAINT "PK_fe2896672fe489c8d1b75f76d89" PRIMARY KEY ("id"))`,
  `CREATE INDEX "IDX_14dcd013484d28e3933a682c79" ON "recipe_contents" ("section_id", "sort_order")`,

  // ingredients
  `CREATE TABLE "ingredients" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "name" character varying(150) NOT NULL, "image_url" text, "is_active" boolean NOT NULL DEFAULT true, CONSTRAINT "PK_9240185c8a5507251c9f15e0649" PRIMARY KEY ("id"))`,
  `CREATE UNIQUE INDEX "IDX_a955029b22ff66ae9fef2e161f" ON "ingredients" ("name")`,
  `CREATE TABLE "recipe_ingredients" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "recipe_id" uuid NOT NULL, "ingredient_id" uuid NOT NULL, "amount" numeric(10,3), "unit" character varying(50), "group_name" character varying(100) NOT NULL DEFAULT 'main', "preparation_note" character varying(255), "is_optional" boolean NOT NULL DEFAULT false, "sort_order" integer NOT NULL DEFAULT '0', CONSTRAINT "chk_recipe_ingredients_sort_order" CHECK ("sort_order" >= 0), CONSTRAINT "chk_recipe_ingredients_amount" CHECK ("amount" IS NULL OR "amount" >= 0), CONSTRAINT "PK_8f15a314e55970414fc92ffb532" PRIMARY KEY ("id"))`,
  `CREATE INDEX "IDX_74203ebcef90db2e97b82f682f" ON "recipe_ingredients" ("recipe_id", "sort_order")`,
  `CREATE UNIQUE INDEX "IDX_56eee47f39814a69f37fe12362" ON "recipe_ingredients" ("recipe_id", "ingredient_id", "group_name")`,

  // cart / favorites / reviews
  `CREATE TABLE "carts" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "user_id" uuid NOT NULL, CONSTRAINT "REL_2ec1c94a977b940d85a4f498ae" UNIQUE ("user_id"), CONSTRAINT "PK_b5f695a59f5ebb50af3c8160816" PRIMARY KEY ("id"))`,
  `CREATE UNIQUE INDEX "IDX_2ec1c94a977b940d85a4f498ae" ON "carts" ("user_id")`,
  `CREATE TABLE "cart_items" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "cart_id" uuid NOT NULL, "recipe_id" uuid NOT NULL, CONSTRAINT "PK_6fccf5ec03c172d27a28a82928b" PRIMARY KEY ("id"))`,
  `CREATE UNIQUE INDEX "IDX_d642d4e088d8a3c85be6edbc60" ON "cart_items" ("cart_id", "recipe_id")`,
  `CREATE TABLE "favorites" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "user_id" uuid NOT NULL, "recipe_id" uuid NOT NULL, CONSTRAINT "PK_890818d27523748dd36a4d1bdc8" PRIMARY KEY ("id"))`,
  `CREATE UNIQUE INDEX "IDX_833a2c29bdd2e66eb4edd8e1b1" ON "favorites" ("user_id", "recipe_id")`,
  `CREATE TABLE "reviews" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "user_id" uuid NOT NULL, "recipe_id" uuid NOT NULL, "rating" smallint NOT NULL, "comment" text, "tags" text array NOT NULL DEFAULT '{}', "status" "public"."reviews_status_enum" NOT NULL DEFAULT 'published', CONSTRAINT "chk_reviews_rating" CHECK ("rating" BETWEEN 1 AND 5), CONSTRAINT "PK_231ae565c273ee700b283f15c1d" PRIMARY KEY ("id"))`,
  `CREATE UNIQUE INDEX "IDX_e244a8c68b87a23365233526f2" ON "reviews" ("user_id", "recipe_id")`,

  // orders / payments / access
  `CREATE TABLE "orders" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "order_number" character varying(50) NOT NULL, "user_id" uuid NOT NULL, "subtotal" numeric(12,2) NOT NULL, "discount_amount" numeric(12,2) NOT NULL DEFAULT '0', "total_amount" numeric(12,2) NOT NULL, "currency" character varying(3) NOT NULL DEFAULT 'THB', "status" "public"."orders_status_enum" NOT NULL DEFAULT 'pending', "paid_at" TIMESTAMP WITH TIME ZONE, "cancelled_at" TIMESTAMP WITH TIME ZONE, CONSTRAINT "chk_orders_total_amount" CHECK ("total_amount" >= 0), CONSTRAINT "chk_orders_discount_amount" CHECK ("discount_amount" >= 0), CONSTRAINT "chk_orders_subtotal" CHECK ("subtotal" >= 0), CONSTRAINT "PK_710e2d4957aa5878dfe94e4ac2f" PRIMARY KEY ("id"))`,
  `CREATE UNIQUE INDEX "IDX_75eba1c6b1a66b09f2a97e6927" ON "orders" ("order_number")`,
  `CREATE INDEX "IDX_a922b820eeef29ac1c6800e826" ON "orders" ("user_id")`,
  `CREATE INDEX "IDX_775c9f06fc27ae3ff8fb26f2c4" ON "orders" ("status")`,
  `CREATE TABLE "order_items" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "order_id" uuid NOT NULL, "recipe_id" uuid NOT NULL, "recipe_title" character varying(255) NOT NULL, "creator_id" uuid NOT NULL, "unit_price" numeric(12,2) NOT NULL, CONSTRAINT "chk_order_items_unit_price" CHECK ("unit_price" >= 0), CONSTRAINT "PK_005269d8574e6fac0493715c308" PRIMARY KEY ("id"))`,
  `CREATE UNIQUE INDEX "IDX_b9bc0c5664839094124615835d" ON "order_items" ("order_id", "recipe_id")`,
  `CREATE TABLE "payments" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "order_id" uuid NOT NULL, "provider" character varying(50) NOT NULL, "provider_transaction_id" character varying(255), "payment_method" character varying(50), "amount" numeric(12,2) NOT NULL, "currency" character varying(3) NOT NULL DEFAULT 'THB', "status" "public"."payments_status_enum" NOT NULL DEFAULT 'pending', "paid_at" TIMESTAMP WITH TIME ZONE, "failure_reason" text, "provider_response" jsonb, CONSTRAINT "chk_payments_amount" CHECK ("amount" >= 0), CONSTRAINT "PK_197ab7af18c93fbb0c9b28b4a59" PRIMARY KEY ("id"))`,
  `CREATE INDEX "IDX_b2f7b823a21562eeca20e72b00" ON "payments" ("order_id")`,
  `CREATE INDEX "IDX_32b41cdb985a296213e9a928b5" ON "payments" ("status")`,
  `CREATE UNIQUE INDEX "IDX_b085a36e96daca8e85d5134844" ON "payments" ("provider", "provider_transaction_id") WHERE "provider_transaction_id" IS NOT NULL`,
  `CREATE TABLE "recipe_access" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "user_id" uuid NOT NULL, "recipe_id" uuid NOT NULL, "order_item_id" uuid, "access_type" "public"."recipe_access_access_type_enum" NOT NULL DEFAULT 'purchase', "granted_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "expires_at" TIMESTAMP WITH TIME ZONE, "revoked_at" TIMESTAMP WITH TIME ZONE, CONSTRAINT "REL_2cc7b22c54315881709849b629" UNIQUE ("order_item_id"), CONSTRAINT "PK_2400a36c5ad32b80bb85aa3ca0c" PRIMARY KEY ("id"))`,
  `CREATE UNIQUE INDEX "IDX_6386749349b82a48d9ec5cafdb" ON "recipe_access" ("user_id", "recipe_id")`,

  // banners
  `CREATE TABLE "banners" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "image_url" text NOT NULL, "title" character varying(255), "description" text, "start_date" TIMESTAMP WITH TIME ZONE, "end_date" TIMESTAMP WITH TIME ZONE, CONSTRAINT "PK_e9b186b959296fcb940790d31c3" PRIMARY KEY ("id"))`,

  // foreign keys
  `ALTER TABLE "recipes" ADD CONSTRAINT "FK_8188b330b79f353885e77b9b14a" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`,
  `ALTER TABLE "recipe_categories" ADD CONSTRAINT "FK_bc02c647e75da3c57a2d22903db" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE CASCADE`,
  `ALTER TABLE "recipe_categories" ADD CONSTRAINT "FK_0849dba2a4b41b34c64fbc5df5e" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE CASCADE ON UPDATE CASCADE`,
  `ALTER TABLE "recipe_sections" ADD CONSTRAINT "FK_522037c3c49e42a40446a029e47" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "recipe_contents" ADD CONSTRAINT "FK_93f2a6969e9d69c840b0468cee2" FOREIGN KEY ("section_id") REFERENCES "recipe_sections"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "recipe_ingredients" ADD CONSTRAINT "FK_f240137e0e13bed80bdf64fed53" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "recipe_ingredients" ADD CONSTRAINT "FK_133545365243061dc2c55dc1373" FOREIGN KEY ("ingredient_id") REFERENCES "ingredients"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`,
  `ALTER TABLE "carts" ADD CONSTRAINT "FK_2ec1c94a977b940d85a4f498aea" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "cart_items" ADD CONSTRAINT "FK_6385a745d9e12a89b859bb25623" FOREIGN KEY ("cart_id") REFERENCES "carts"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "cart_items" ADD CONSTRAINT "FK_e28fe7e54dae0295a4b1086b4e5" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "favorites" ADD CONSTRAINT "FK_35a6b05ee3b624d0de01ee50593" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "favorites" ADD CONSTRAINT "FK_f013a5737104974aa8b57163708" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "reviews" ADD CONSTRAINT "FK_728447781a30bc3fcfe5c2f1cdf" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "reviews" ADD CONSTRAINT "FK_c7700bc1937b08b564d84e2abea" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "orders" ADD CONSTRAINT "FK_a922b820eeef29ac1c6800e826a" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`,
  `ALTER TABLE "order_items" ADD CONSTRAINT "FK_145532db85752b29c57d2b7b1f1" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "order_items" ADD CONSTRAINT "FK_16fd22c785a6c93c1df8faf38aa" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`,
  `ALTER TABLE "payments" ADD CONSTRAINT "FK_b2f7b823a21562eeca20e72b006" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`,
  `ALTER TABLE "recipe_access" ADD CONSTRAINT "FK_115f4d8334ce8619597d6f04bd1" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "recipe_access" ADD CONSTRAINT "FK_75324072d8ff466da1f5f61828c" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
  `ALTER TABLE "recipe_access" ADD CONSTRAINT "FK_2cc7b22c54315881709849b629d" FOREIGN KEY ("order_item_id") REFERENCES "order_items"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
];
