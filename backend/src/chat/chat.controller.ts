import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { UploadedFileData } from '../uploads/uploads.service';
import { CHAT_IMAGE_TYPES, ChatMessage, ChatService } from './chat.service';
import { ChatMessageDto } from './dto/chat-message.dto';

@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  /**
   * ถามเกี่ยวกับสูตร AI จะจำบทสนทนาก่อนหน้า (หมดอายุเมื่อไม่ใช้งาน 20 นาที หรือเปลี่ยนสูตร)
   * ส่งเป็น JSON ได้ตามเดิม หรือส่ง multipart/form-data พร้อมไฟล์รูปในฟิลด์ image
   */
  @Post()
  @UseInterceptors(
    FileInterceptor('image', { limits: { fileSize: 5 * 1024 * 1024 } }),
  )
  chat(
    @CurrentUser('id') userId: string,
    @Body() dto: ChatMessageDto,
    @UploadedFile() image?: UploadedFileData,
  ): Promise<{ message: string }> {
    if (image && !CHAT_IMAGE_TYPES.includes(image.mimetype)) {
      throw new BadRequestException('Image must be JPEG, PNG, WEBP or GIF');
    }
    if (!dto.message && !image) {
      throw new BadRequestException('message or image is required');
    }
    return this.chatService.chat(userId, dto.recipeId, dto.message, image);
  }

  /** ให้แอปเช็กว่าจะแสดงปุ่มถาม AI หรือไม่ */
  @Get('recipes/:recipeId/permission')
  async permission(
    @CurrentUser('id') userId: string,
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
  ): Promise<{ canChat: boolean }> {
    return { canChat: await this.chatService.canChat(userId, recipeId) };
  }

  /** ประวัติแชทของสูตรนี้ (หมดอายุแล้วหรือคุยสูตรอื่นอยู่ จะได้ []) */
  @Get('recipes/:recipeId/history')
  async history(
    @CurrentUser('id') userId: string,
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
  ): Promise<{ messages: ChatMessage[] }> {
    return { messages: await this.chatService.getHistory(userId, recipeId) };
  }

  /** ล้างบทสนทนา เริ่มคุยใหม่ */
  @Delete()
  async reset(@CurrentUser('id') userId: string): Promise<{ success: true }> {
    await this.chatService.reset(userId);
    return { success: true };
  }
}
