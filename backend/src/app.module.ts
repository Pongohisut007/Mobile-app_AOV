import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppCacheModule } from './cache/app-cache.module';
import databaseConfig from '../config/database.config';
import googleConfig from '../config/google.config';
import jwtConfig from '../config/jwt.config';
import mailConfig from '../config/mail.config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { BannerModule } from './banner/banner.module';
import { CartModule } from './cart/cart.module';
import { ChatModule } from './chat/chat.module';
import { CategoriesModule } from './categories/categories.module';
import { DatabaseModule } from './database/database.module';
import { FavoritesModule } from './favorites/favorites.module';
import { IngredientsModule } from './ingredients/ingredients.module';
import { IapModule } from './iap/iap.module';
import { OrdersModule } from './orders/orders.module';
import { PaymentsModule } from './payments/payments.module';
import { RecipeAccessModule } from './recipe-access/recipe-access.module';
import { RecipeCommentsModule } from './recipe-comments/recipe-comments.module';
import { RecipesModule } from './recipes/recipes.module';
import { ReviewsModule } from './reviews/reviews.module';
import { UploadsModule } from './uploads/uploads.module';
import { UsersModule } from './users/users.module';
import r2ClientConfig from '../config/r2.client.config';

@Module({
  imports: [
    AppCacheModule,
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.production', '.env', '.env.development.local'],
      load: [
        databaseConfig,
        jwtConfig,
        r2ClientConfig,
        googleConfig,
        mailConfig,
      ],
    }),
    DatabaseModule,
    UsersModule,
    AuthModule,
    BannerModule,
    CategoriesModule,
    RecipesModule,
    IngredientsModule,
    IapModule,
    OrdersModule,
    PaymentsModule,
    RecipeAccessModule,
    RecipeCommentsModule,
    ReviewsModule,
    FavoritesModule,
    CartModule,
    ChatModule,
    UploadsModule,
    // FoodsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
