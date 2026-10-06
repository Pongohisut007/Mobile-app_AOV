import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'node:crypto';
import { DataSource, EntityManager } from 'typeorm';
import { AppModule } from '../../app.module';
import { Banner } from '../../banner/entities/banner.entity';
import { CacheNamespace } from '../../cache/app-cache.module';
import { AppCacheService } from '../../cache/app-cache.service';
import { CartItem } from '../../cart/entities/cart-item.entity';
import { Cart } from '../../cart/entities/cart.entity';
import { Category } from '../../categories/entities/category.entity';
import { Favorite } from '../../favorites/entities/favorite.entity';
import { Ingredient } from '../../ingredients/entities/ingredient.entity';
import { RecipeIngredient } from '../../ingredients/entities/recipe-ingredient.entity';
import { OrderItem } from '../../orders/entities/order-item.entity';
import { Order, OrderStatus } from '../../orders/entities/order.entity';
import { Payment, PaymentStatus } from '../../payments/entities/payment.entity';
import {
  RecipeAccess,
  RecipeAccessType,
} from '../../recipe-access/entities/recipe-access.entity';
import { RecipeComment } from '../../recipe-comments/entities/recipe-comment.entity';
import {
  RecipeContent,
  RecipeContentType,
} from '../../recipes/entities/recipe-content.entity';
import { RecipeSection } from '../../recipes/entities/recipe-section.entity';
import {
  Recipe,
  RecipeDifficulty,
  RecipeStatus,
  RecipeType,
} from '../../recipes/entities/recipe.entity';
import { REVIEW_TAGS } from '../../reviews/dto/upsert-review.dto';
import { Review, ReviewStatus } from '../../reviews/entities/review.entity';
import {
  IdentityProvider,
  UserIdentity,
} from '../../users/entities/user-identity.entity';
import { User, UserRole, UserStatus } from '../../users/entities/user.entity';
import {
  BANNERS,
  CATEGORIES,
  COMMENTS,
  DISHES,
  REVIEW_COMMENTS,
  STEP_VIDEOS,
  USERS,
  type DishSeed,
} from './demo-data';
import {
  descriptionFor,
  ingredientsFor,
  sectionsFor,
  timesFor,
} from './recipe-content';

/**
 * ล้างฐานข้อมูลแล้วใส่ข้อมูลตัวอย่าง เหมือนแอปถูกใช้งานมาราว 6 เดือน
 *   npm run seed
 * - ผู้ใช้ 20 คน (admin 1, creator 5, ผู้ใช้ 14 โดย 2 คนสมัครผ่าน Google)
 * - สูตร 100 สูตร (official ขายได้ / community ฟรี / draft / ซ่อน)
 * - คำสั่งซื้อ การจ่ายเงิน สิทธิ์ดูสูตร รีวิว คอมเมนต์ รายการโปรด ตะกร้า แบนเนอร์
 * สุ่มแบบกำหนด seed ไว้ รันกี่ครั้งก็ได้ข้อมูลหน้าตาเดิม (ยกเว้น id และวันที่อิงวันนี้)
 *
 * กันพลาด: ไม่ยอมรันบน staging/production เว้นแต่ตั้ง SEED_ALLOW_RESET=true
 */

const logger = new Logger('DatabaseSeed');
const PASSWORD = 'Password123!';
const DAY = 24 * 60 * 60 * 1000;

// ---------- สุ่มแบบกำหนด seed ----------
function mulberry32(seed: number) {
  let state = seed;
  return () => {
    state |= 0;
    state = (state + 0x6d2b79f5) | 0;
    let t = Math.imul(state ^ (state >>> 15), 1 | state);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const random = mulberry32(20261006);
const between = (min: number, max: number) =>
  min + Math.floor(random() * (max - min + 1));
const chance = (probability: number) => random() < probability;
const pick = <T>(items: readonly T[]): T =>
  items[Math.floor(random() * items.length)];
function sample<T>(items: readonly T[], count: number): T[] {
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy.slice(0, Math.max(0, Math.min(count, copy.length)));
}

const now = Date.now();
const daysAgo = (days: number) =>
  new Date(now - days * DAY - Math.floor(random() * DAY));
/** วันที่สุ่มระหว่าง [from] ถึงเมื่อวาน */
const dateAfter = (from: Date, maxDaysLater?: number) => {
  const end = Math.min(
    now - DAY / 2,
    maxDaysLater ? from.getTime() + maxDaysLater * DAY : now,
  );
  const start = Math.min(from.getTime() + 60 * 60 * 1000, end);
  return new Date(start + random() * (end - start));
};
const latest = (...dates: Date[]) =>
  new Date(Math.max(...dates.map((date) => date.getTime())));

const slugify = (value: string) =>
  value
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

const money = (value: number) => value.toFixed(2);

// ---------- ตัวแทนข้อมูลระหว่างสร้าง ----------
interface SeededUser {
  id: string;
  key: string;
  email: string;
  displayName: string;
  role: UserRole;
  createdAt: Date;
}

interface SeededRecipe {
  id: string;
  dish: DishSeed;
  title: string;
  creatorId: string;
  type: RecipeType;
  status: RecipeStatus;
  price: number;
  publishedAt: Date | null;
}

/** ล้างทุกตารางของแอป (ใน transaction เดียวกับการใส่ข้อมูล: พลาดกลางทาง = ข้อมูลเดิมยังอยู่) */
async function resetDatabase(
  dataSource: DataSource,
  manager: EntityManager,
): Promise<void> {
  const tables = dataSource.entityMetadatas
    .map((metadata) => `"${metadata.tableName}"`)
    .join(', ');
  await manager.query(`TRUNCATE TABLE ${tables} RESTART IDENTITY CASCADE`);
}

async function seedUsers(
  manager: EntityManager,
  passwordHash: string,
): Promise<SeededUser[]> {
  const roleOf = {
    admin: UserRole.ADMIN,
    creator: UserRole.CREATOR,
    user: UserRole.USER,
  };
  const users: SeededUser[] = USERS.map((seed, index) => ({
    id: randomUUID(),
    key: seed.key,
    email: seed.email,
    displayName: seed.displayName,
    role: roleOf[seed.role],
    // admin/creator มาก่อน ผู้ใช้ทยอยสมัครตามมา
    createdAt:
      seed.role === 'user'
        ? daysAgo(between(20, 170))
        : daysAgo(200 - index * 3),
  }));

  await manager.insert(
    User,
    users.map((user, index) => ({
      id: user.id,
      email: user.email,
      passwordHash: USERS[index].googleOnly ? null : passwordHash,
      displayName: user.displayName,
      avatarUrl: USERS[index].avatarUrl,
      role: user.role,
      status: UserStatus.ACTIVE,
      tokenVersion: 0,
      createdAt: user.createdAt,
      updatedAt: user.createdAt,
    })),
  );

  const googleUsers = users.filter((_, index) => USERS[index].googleOnly);
  await manager.insert(
    UserIdentity,
    googleUsers.map((user) => ({
      userId: user.id,
      provider: IdentityProvider.GOOGLE,
      // sub ของ Google เป็นตัวเลข 21 หลัก
      providerUserId: `1${between(1e9, 1e10 - 1)}${between(1e9, 1e10 - 1)}`,
      email: user.email,
      createdAt: user.createdAt,
      updatedAt: user.createdAt,
    })),
  );
  return users;
}

async function seedCategories(
  manager: EntityManager,
): Promise<Map<string, string>> {
  const created = daysAgo(210);
  const rows = CATEGORIES.map((category, index) => ({
    id: randomUUID(),
    ...category,
    isActive: true,
    sortOrder: index + 1,
    createdAt: created,
    updatedAt: created,
  }));
  await manager.insert(Category, rows);
  return new Map(rows.map((row) => [row.slug, row.id]));
}

async function seedRecipes(
  manager: EntityManager,
  users: SeededUser[],
  categoryIds: Map<string, string>,
): Promise<SeededRecipe[]> {
  const creators = users.filter((user) => user.role === UserRole.CREATOR);
  const members = users.filter((user) => user.role === UserRole.USER);
  const prices = [39, 49, 59, 69, 79, 89, 99, 129, 149];
  // สูตรที่ยังไม่เสร็จ/ถูกซ่อน (index ใน DISHES)
  const drafts = new Set([11, 27, 44, 58, 70, 83, 91]);
  const hidden = new Set([33]);
  const rejected = new Set([64]);

  const recipes: SeededRecipe[] = [];
  const usedSlugs = new Set<string>();
  const ingredientIds = new Map<string, string>();
  const ingredientRows: object[] = [];
  const recipeRows: object[] = [];
  const categoryLinks: { recipeId: string; categoryId: string }[] = [];
  const sectionRows: object[] = [];
  const contentRows: object[] = [];
  const recipeIngredientRows: object[] = [];

  DISHES.forEach((dish, index) => {
    const official =
      dish.kind !== 'drink' && [0, 2, 4, 7, 9].includes(index % 12);
    const author = official
      ? creators[index % creators.length]
      : chance(0.25)
        ? pick(creators)
        : pick(members);

    const status = drafts.has(index)
      ? RecipeStatus.DRAFT
      : hidden.has(index)
        ? RecipeStatus.HIDDEN
        : rejected.has(index)
          ? RecipeStatus.REJECTED
          : RecipeStatus.PUBLISHED;
    const publishedAt =
      status === RecipeStatus.DRAFT ? null : dateAfter(author.createdAt);
    const createdAt = publishedAt
      ? new Date(publishedAt.getTime() - between(1, 5) * DAY)
      : dateAfter(new Date(now - 14 * DAY));
    const price = official ? pick(prices) : 0;

    let slug = slugify(dish.titleEn) || `recipe-${index + 1}`;
    while (usedSlugs.has(slug)) slug = `${slug}-${index + 1}`;
    usedSlugs.add(slug);

    const id = randomUUID();
    const { preparationMinutes, cookingMinutes, difficulty } = timesFor(dish);
    recipeRows.push({
      id,
      creatorId: author.id,
      title: dish.title,
      titleEn: dish.titleEn,
      slug,
      shortDescription: descriptionFor(dish),
      coverImageUrl: dish.imageUrl,
      showImgCommu: !official && chance(0.7),
      price: money(price),
      preparationMinutes,
      cookingMinutes,
      servingCount: between(1, 4),
      difficulty: difficulty as RecipeDifficulty,
      type: official ? RecipeType.OFFICIAL : RecipeType.COMMUNITY,
      status,
      publishedAt,
      createdAt,
      updatedAt: publishedAt ?? createdAt,
    });
    for (const slugOfCategory of dish.categories) {
      const categoryId = categoryIds.get(slugOfCategory);
      if (!categoryId) throw new Error(`Unknown category ${slugOfCategory}`);
      categoryLinks.push({ recipeId: id, categoryId });
    }

    // ขั้นตอน: section แรกเป็นตัวอย่าง (ดูได้ก่อนซื้อ)
    const video =
      official && index % 7 === 0
        ? STEP_VIDEOS[(index / 7) % STEP_VIDEOS.length]
        : null;
    sectionsFor(dish, official, video).forEach((section, sectionIndex) => {
      const sectionId = randomUUID();
      sectionRows.push({
        id: sectionId,
        recipeId: id,
        title: section.title,
        description: section.description,
        sortOrder: sectionIndex + 1,
        isPreview: sectionIndex === 0,
        createdAt,
        updatedAt: createdAt,
      });
      section.contents.forEach((content, contentIndex) => {
        const isVideo = content.type === 'video';
        contentRows.push({
          sectionId,
          contentType: content.type as RecipeContentType,
          title: content.title,
          textContent: isVideo ? null : content.text,
          mediaUrl: isVideo ? content.text : null,
          durationSeconds: isVideo ? 60 : null,
          sortOrder: contentIndex + 1,
          createdAt,
          updatedAt: createdAt,
        });
      });
    });

    ingredientsFor(dish).forEach((line, lineIndex) => {
      let ingredientId = ingredientIds.get(line.name);
      if (!ingredientId) {
        ingredientId = randomUUID();
        ingredientIds.set(line.name, ingredientId);
        ingredientRows.push({
          id: ingredientId,
          name: line.name,
          imageUrl: null,
          isActive: true,
        });
      }
      recipeIngredientRows.push({
        recipeId: id,
        ingredientId,
        amount: line.amount === null ? null : line.amount.toFixed(3),
        unit: line.unit,
        groupName: 'main',
        preparationNote: line.note ?? null,
        isOptional: line.optional ?? false,
        sortOrder: lineIndex + 1,
      });
    });

    recipes.push({
      id,
      dish,
      title: dish.title,
      creatorId: author.id,
      type: official ? RecipeType.OFFICIAL : RecipeType.COMMUNITY,
      status,
      price,
      publishedAt,
    });
  });

  await manager.insert(Ingredient, ingredientRows);
  await manager.insert(Recipe, recipeRows);
  await manager
    .createQueryBuilder()
    .insert()
    .into('recipe_categories')
    .values(
      categoryLinks.map((link) => ({
        recipe_id: link.recipeId,
        category_id: link.categoryId,
      })),
    )
    .execute();
  await manager.insert(RecipeSection, sectionRows);
  await manager.insert(RecipeContent, contentRows);
  await manager.insert(RecipeIngredient, recipeIngredientRows);
  return recipes;
}

interface Purchase {
  userId: string;
  recipeId: string;
  grantedAt: Date;
}

async function seedPurchases(
  manager: EntityManager,
  users: SeededUser[],
  recipes: SeededRecipe[],
): Promise<Purchase[]> {
  const forSale = recipes.filter(
    (recipe) =>
      recipe.type === RecipeType.OFFICIAL &&
      recipe.status === RecipeStatus.PUBLISHED,
  );
  const buyers = users.filter((user) => user.role !== UserRole.ADMIN);
  const purchases: Purchase[] = [];
  const orders: object[] = [];
  const orderItems: object[] = [];
  const payments: object[] = [];
  const accesses: object[] = [];
  let orderNumber = 1;

  const newOrderNumber = (date: Date) =>
    `RCP-${date.toISOString().slice(0, 10).replaceAll('-', '')}-${String(orderNumber++).padStart(4, '0')}`;

  for (const buyer of buyers) {
    const isCreator = buyer.role === UserRole.CREATOR;
    const wanted = sample(
      forSale.filter((recipe) => recipe.creatorId !== buyer.id),
      isCreator ? between(0, 3) : between(2, 9),
    );

    // แบ่งเป็นคำสั่งซื้อละ 1-3 สูตร
    while (wanted.length > 0) {
      const items = wanted.splice(0, between(1, 3));
      const earliest = latest(
        buyer.createdAt,
        ...items.map((recipe) => recipe.publishedAt ?? buyer.createdAt),
      );
      const paidAt = dateAfter(earliest);
      const orderId = randomUUID();
      const total = items.reduce((sum, recipe) => sum + recipe.price, 0);
      orders.push({
        id: orderId,
        orderNumber: newOrderNumber(paidAt),
        userId: buyer.id,
        subtotal: money(total),
        discountAmount: money(0),
        totalAmount: money(total),
        currency: 'THB',
        status: OrderStatus.PAID,
        paidAt,
        cancelledAt: null,
        createdAt: paidAt,
        updatedAt: paidAt,
      });
      payments.push({
        orderId,
        provider: 'google_play',
        providerTransactionId: `GPA.${between(1000, 9999)}-${between(1000, 9999)}-${between(1000, 9999)}-${orderNumber}`,
        paymentMethod: 'google_play',
        amount: money(total),
        currency: 'THB',
        status: PaymentStatus.SUCCESSFUL,
        paidAt,
        failureReason: null,
        providerResponse: { seeded: true },
        createdAt: paidAt,
        updatedAt: paidAt,
      });
      for (const recipe of items) {
        const orderItemId = randomUUID();
        orderItems.push({
          id: orderItemId,
          orderId,
          recipeId: recipe.id,
          recipeTitle: recipe.title,
          creatorId: recipe.creatorId,
          unitPrice: money(recipe.price),
          createdAt: paidAt,
          updatedAt: paidAt,
        });
        accesses.push({
          userId: buyer.id,
          recipeId: recipe.id,
          orderItemId,
          accessType: RecipeAccessType.PURCHASE,
          grantedAt: paidAt,
          expiresAt: null,
          revokedAt: null,
          createdAt: paidAt,
          updatedAt: paidAt,
        });
        purchases.push({
          userId: buyer.id,
          recipeId: recipe.id,
          grantedAt: paidAt,
        });
      }
    }

    // บางคนจ่ายเงินไม่ผ่านบ้าง (ไม่ได้สิทธิ์ดูสูตร)
    if (!isCreator && chance(0.3)) {
      const recipe = pick(forSale);
      const failedAt = dateAfter(
        latest(buyer.createdAt, recipe.publishedAt ?? buyer.createdAt),
      );
      const orderId = randomUUID();
      orders.push({
        id: orderId,
        orderNumber: newOrderNumber(failedAt),
        userId: buyer.id,
        subtotal: money(recipe.price),
        discountAmount: money(0),
        totalAmount: money(recipe.price),
        currency: 'THB',
        status: OrderStatus.FAILED,
        paidAt: null,
        cancelledAt: null,
        createdAt: failedAt,
        updatedAt: failedAt,
      });
      orderItems.push({
        orderId,
        recipeId: recipe.id,
        recipeTitle: recipe.title,
        creatorId: recipe.creatorId,
        unitPrice: money(recipe.price),
        createdAt: failedAt,
        updatedAt: failedAt,
      });
      payments.push({
        orderId,
        provider: 'google_play',
        providerTransactionId: null,
        paymentMethod: 'google_play',
        amount: money(recipe.price),
        currency: 'THB',
        status: PaymentStatus.FAILED,
        paidAt: null,
        failureReason: 'Payment declined by the card issuer',
        providerResponse: { seeded: true },
        createdAt: failedAt,
        updatedAt: failedAt,
      });
    }
  }

  await manager.insert(Order, orders);
  await manager.insert(OrderItem, orderItems);
  await manager.insert(Payment, payments);
  await manager.insert(RecipeAccess, accesses);
  return purchases;
}

async function seedReviews(
  manager: EntityManager,
  purchases: Purchase[],
): Promise<number> {
  const ratingFor = () => {
    const roll = random();
    if (roll < 0.45) return 5;
    if (roll < 0.8) return 4;
    if (roll < 0.93) return 3;
    if (roll < 0.98) return 2;
    return 1;
  };
  const rows = purchases
    .filter(() => chance(0.65))
    .map((purchase, index) => {
      const rating = ratingFor();
      const at = dateAfter(purchase.grantedAt, 20);
      return {
        userId: purchase.userId,
        recipeId: purchase.recipeId,
        rating,
        comment: chance(0.85)
          ? pick(REVIEW_COMMENTS[Math.max(rating, 2)])
          : null,
        tags: rating >= 4 ? sample(REVIEW_TAGS, between(0, 3)) : [],
        // ทีมงานซ่อนรีวิวที่ไม่เหมาะสมไปบ้าง
        status:
          index % 37 === 36 ? ReviewStatus.HIDDEN : ReviewStatus.PUBLISHED,
        createdAt: at,
        updatedAt: at,
      };
    });
  await manager.insert(Review, rows);
  return rows.length;
}

async function seedComments(
  manager: EntityManager,
  users: SeededUser[],
  recipes: SeededRecipe[],
): Promise<number> {
  const commenters = users.filter((user) => user.role !== UserRole.ADMIN);
  const rows: object[] = [];
  for (const recipe of recipes) {
    if (recipe.type !== RecipeType.COMMUNITY || !recipe.publishedAt) continue;
    if (recipe.status !== RecipeStatus.PUBLISHED) continue;
    for (const user of sample(commenters, between(0, 7))) {
      const at = dateAfter(latest(recipe.publishedAt, user.createdAt));
      rows.push({
        recipeId: recipe.id,
        userId: user.id,
        comment: pick(COMMENTS),
        createdAt: at,
        updatedAt: at,
      });
    }
  }
  await manager.insert(RecipeComment, rows);
  return rows.length;
}

async function seedFavorites(
  manager: EntityManager,
  users: SeededUser[],
  recipes: SeededRecipe[],
): Promise<number> {
  const published = recipes.filter(
    (recipe) => recipe.status === RecipeStatus.PUBLISHED,
  );
  const rows: object[] = [];
  for (const user of users) {
    if (user.role === UserRole.ADMIN) continue;
    for (const recipe of sample(published, between(4, 15))) {
      const at = dateAfter(latest(recipe.publishedAt!, user.createdAt));
      rows.push({
        userId: user.id,
        recipeId: recipe.id,
        createdAt: at,
        updatedAt: at,
      });
    }
  }
  await manager.insert(Favorite, rows);
  return rows.length;
}

async function seedCarts(
  manager: EntityManager,
  users: SeededUser[],
  recipes: SeededRecipe[],
  purchases: Purchase[],
): Promise<number> {
  const owned = new Set(purchases.map((p) => `${p.userId}:${p.recipeId}`));
  const carts: object[] = [];
  const items: object[] = [];
  for (const user of users) {
    if (user.role !== UserRole.USER || !chance(0.5)) continue;
    const choices = recipes.filter(
      (recipe) =>
        recipe.type === RecipeType.OFFICIAL &&
        recipe.status === RecipeStatus.PUBLISHED &&
        !owned.has(`${user.id}:${recipe.id}`),
    );
    const cartId = randomUUID();
    const at = daysAgo(between(0, 10));
    carts.push({ id: cartId, userId: user.id, createdAt: at, updatedAt: at });
    for (const recipe of sample(choices, between(1, 2))) {
      items.push({ cartId, recipeId: recipe.id, createdAt: at, updatedAt: at });
    }
  }
  await manager.insert(Cart, carts);
  await manager.insert(CartItem, items);
  return items.length;
}

async function seedBanners(manager: EntityManager): Promise<void> {
  await manager.insert(
    Banner,
    BANNERS.map((banner, index) => {
      const startDate = daysAgo(30 - index * 7);
      return {
        ...banner,
        startDate,
        endDate: new Date(now + (60 + index * 30) * DAY),
        createdAt: startDate,
        updatedAt: startDate,
      };
    }),
  );
}

async function seed(): Promise<void> {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['log', 'error', 'warn'],
  });

  try {
    const config = app.get(ConfigService);
    const appEnv = config.get<string>('app.env');
    if (appEnv !== 'development' && process.env.SEED_ALLOW_RESET !== 'true') {
      throw new Error(
        `Refusing to wipe the ${appEnv} database. Set SEED_ALLOW_RESET=true if you really mean it.`,
      );
    }

    const dataSource = app.get(DataSource);
    const passwordHash = await bcrypt.hash(
      PASSWORD,
      config.get<number>('jwt.bcryptSaltRounds', 10),
    );

    const summary = await dataSource.transaction(async (manager) => {
      await resetDatabase(dataSource, manager);
      const users = await seedUsers(manager, passwordHash);
      const categoryIds = await seedCategories(manager);
      const recipes = await seedRecipes(manager, users, categoryIds);
      const purchases = await seedPurchases(manager, users, recipes);
      const reviews = await seedReviews(manager, purchases);
      const comments = await seedComments(manager, users, recipes);
      const favorites = await seedFavorites(manager, users, recipes);
      const cartItems = await seedCarts(manager, users, recipes, purchases);
      await seedBanners(manager);
      return {
        users: users.length,
        recipes: recipes.length,
        purchases: purchases.length,
        reviews,
        comments,
        favorites,
        cartItems,
        banners: BANNERS.length,
      };
    });

    // ข้อมูลเก่าที่ cache ไว้ (RAM/Redis) ใช้ไม่ได้แล้ว
    const cache = app.get(AppCacheService, { strict: false });
    await Promise.all(
      Object.values(CacheNamespace).map((namespace) =>
        cache.invalidate(namespace),
      ),
    );

    logger.log(`Seed completed: ${JSON.stringify(summary)}`);
    logger.log(`Every account with a password uses: ${PASSWORD}`);
    logger.log('Admin:   admin@recipy.local');
    logger.log('Creator: chef.mook@recipy.local (and 4 more creators)');
    logger.log('User:    somchai@example.com (and 13 more users)');
  } finally {
    await app.close();
  }
}

void seed().catch((error: unknown) => {
  logger.error(
    'Seed failed',
    error instanceof Error ? error.stack : String(error),
  );
  process.exitCode = 1;
});
