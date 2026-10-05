import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserIdentity } from './entities/user-identity.entity';
import { User } from './entities/user.entity';
import { Favorite } from '../favorites/entities/favorite.entity';
import { RecipeAccess } from '../recipe-access/entities/recipe-access.entity';
import { Recipe } from '../recipes/entities/recipe.entity';
import { Review } from '../reviews/entities/review.entity';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      UserIdentity,
      Recipe,
      Favorite,
      RecipeAccess,
      Review,
    ]),
  ],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
