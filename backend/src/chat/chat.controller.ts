import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ChatService } from './chat.service';
import { ChatMessageDto } from './dto/chat-message.dto';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  //@UseGuards(JwtAuthGuard)
  @Post()
  chat(@Body() dto: ChatMessageDto): Promise<{ message: string }> {
    return this.chatService.chat(dto.message);
  }
}
