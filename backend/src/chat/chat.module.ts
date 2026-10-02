import { Module } from '@nestjs/common';
import { RecipeAccessModule } from '../recipe-access/recipe-access.module';
import { RecipesModule } from '../recipes/recipes.module';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';

@Module({
  imports: [RecipesModule, RecipeAccessModule],
  controllers: [ChatController],
  providers: [ChatService],
})
export class ChatModule {}
