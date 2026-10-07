import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationsModule } from '../notifications/notifications.module';
import { RecipeAccessModule } from '../recipe-access/recipe-access.module';
import { Recipe } from '../recipes/entities/recipe.entity';
import { User } from '../users/entities/user.entity';
import { RecipeComment } from './entities/recipe-comment.entity';
import { RecipeCommentsController } from './recipe-comments.controller';
import { RecipeCommentsService } from './recipe-comments.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([RecipeComment, Recipe, User]),
    RecipeAccessModule,
    NotificationsModule,
  ],
  controllers: [RecipeCommentsController],
  providers: [RecipeCommentsService],
})
export class RecipeCommentsModule {}
