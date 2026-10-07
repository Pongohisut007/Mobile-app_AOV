import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PasswordResetCode } from '../auth/entities/password-reset-code.entity';
import { Banner } from '../banner/entities/banner.entity';
import { CartItem } from '../cart/entities/cart-item.entity';
import { Cart } from '../cart/entities/cart.entity';
import { Category } from '../categories/entities/category.entity';
import { Favorite } from '../favorites/entities/favorite.entity';
import { Ingredient } from '../ingredients/entities/ingredient.entity';
import { DeviceToken } from '../notifications/entities/device-token.entity';
import { NotificationSettings } from '../notifications/entities/notification-settings.entity';
import { Notification } from '../notifications/entities/notification.entity';
import { RecipeIngredient } from '../ingredients/entities/recipe-ingredient.entity';
import { OrderItem } from '../orders/entities/order-item.entity';
import { Order } from '../orders/entities/order.entity';
import { Payment } from '../payments/entities/payment.entity';
import { RecipeAccess } from '../recipe-access/entities/recipe-access.entity';
import { RecipeComment } from '../recipe-comments/entities/recipe-comment.entity';
import { RecipeContent } from '../recipes/entities/recipe-content.entity';
import { RecipeSection } from '../recipes/entities/recipe-section.entity';
import { Recipe } from '../recipes/entities/recipe.entity';
import { Review } from '../reviews/entities/review.entity';
import { UserIdentity } from '../users/entities/user-identity.entity';
import { User } from '../users/entities/user.entity';

const entities = [
  User,
  UserIdentity,
  PasswordResetCode,
  Recipe,
  RecipeSection,
  RecipeContent,
  Category,
  Ingredient,
  RecipeIngredient,
  Order,
  OrderItem,
  Payment,
  RecipeAccess,
  RecipeComment,
  Review,
  Favorite,
  Banner,
  Cart,
  CartItem,
  Notification,
  DeviceToken,
  NotificationSettings,
];

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',

        host: config.getOrThrow<string>('database.host'),
        port: config.getOrThrow<number>('database.port'),
        username: config.getOrThrow<string>('database.username'),
        password: config.getOrThrow<string>('database.password'),
        database: config.getOrThrow<string>('database.name'),

        entities,
        autoLoadEntities: true,

        // เปิดเฉพาะเครื่องนักพัฒนา staging/production ใช้ migration เท่านั้น
        synchronize: config.get<string>('app.env') === 'development',

        migrations: [`${__dirname}/migrations/*{.ts,.js}`],
      }),
    }),
  ],
})
export class DatabaseModule {}
