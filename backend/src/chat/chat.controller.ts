import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ChatService } from './chat.service';
import { ChatMessageDto } from './dto/chat-message.dto';

@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  /** ถามเกี่ยวกับสูตร AI จะจำบทสนทนาก่อนหน้า (หมดอายุเมื่อไม่ใช้งาน 20 นาที หรือเปลี่ยนสูตร) */
  @Post()
  chat(
    @CurrentUser('id') userId: string,
    @Body() dto: ChatMessageDto,
  ): Promise<{ message: string }> {
    return this.chatService.chat(userId, dto.recipeId, dto.message);
  }

  /** ให้แอปเช็กว่าจะแสดงปุ่มถาม AI หรือไม่ */
  @Get('recipes/:recipeId/permission')
  async permission(
    @CurrentUser('id') userId: string,
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
  ): Promise<{ canChat: boolean }> {
    return { canChat: await this.chatService.canChat(userId, recipeId) };
  }

  /** ล้างบทสนทนา เริ่มคุยใหม่ */
  @Delete()
  reset(@CurrentUser('id') userId: string): { success: true } {
    this.chatService.reset(userId);
    return { success: true };
  }
}
