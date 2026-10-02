import { Body, Controller, Delete, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ChatService } from './chat.service';
import { ChatMessageDto } from './dto/chat-message.dto';

@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  /** ส่งข้อความ AI จะจำบทสนทนาก่อนหน้าของ user คนนี้ (หมดอายุเมื่อไม่ใช้งาน 20 นาที) */
  @Post()
  chat(
    @CurrentUser('id') userId: string,
    @Body() dto: ChatMessageDto,
  ): Promise<{ message: string }> {
    return this.chatService.chat(userId, dto.message);
  }

  /** ล้างบทสนทนา เริ่มคุยใหม่ */
  @Delete()
  reset(@CurrentUser('id') userId: string): { success: true } {
    this.chatService.reset(userId);
    return { success: true };
  }
}
