import {
  ForbiddenException,
  Injectable,
  OnModuleDestroy,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import OpenAI from 'openai';
import { RecipeAccessService } from '../recipe-access/recipe-access.service';
import { RecipeContentType } from '../recipes/entities/recipe-content.entity';
import { Recipe, RecipeType } from '../recipes/entities/recipe.entity';
import { RecipesService } from '../recipes/recipes.service';

const DEFAULT_BASE_URL = 'https://ai.psu.blue/v1';
const DEFAULT_MODEL = 'openai/gpt-5.6-luna';
const DEFAULT_REDIS_URL = 'redis://localhost:6379';

const INSTRUCTIONS = `
คุณคือผู้ช่วยของแอปสูตรอาหาร ผู้ใช้กำลังดูสูตรอาหารตามข้อมูลด้านล่าง
ตอบได้เฉพาะเรื่องที่เกี่ยวกับสูตรนี้เท่านั้น เช่น วิธีทำ วัตถุดิบ วัตถุดิบทดแทน เทคนิค โภชนาการ การเก็บรักษา และกินคู่กับอะไร
ถ้าผู้ใช้ถามถึงเมนูอื่น (เช่น ถามวิธีทำเมนูอื่น) หรือเรื่องที่ไม่เกี่ยวกับสูตรนี้ ห้ามตอบเนื้อหานั้น
ให้ปฏิเสธอย่างสุภาพ บอกว่าตอบได้เฉพาะสูตรนี้ และแนะนำให้ไปเปิดสูตรเมนูนั้นในแอปแทน
ถ้าผู้ใช้แนบรูปมา ให้ดูรูปในบริบทของสูตรนี้ เช่น อาหารที่ทำออกมาเป็นอย่างไร หรือวัตถุดิบในรูปใช้กับสูตรนี้ได้ไหม
ถ้าผู้ใช้ส่งรูปที่ไม่เกี่ยวกับอาหารหรือสูตรนี้ ให้บอกสั้นๆ ว่าเป็นรูปอะไร แล้วแจ้งว่าช่วยได้เฉพาะเรื่องสูตรนี้
ถ้าข้อมูลในสูตรไม่พอแต่คำถามยังเกี่ยวกับสูตรนี้ ให้ตอบได้ โดยบอกว่าเป็นคำแนะนำทั่วไป ไม่ใช่ข้อมูลจากสูตร
ตอบเป็นภาษาเดียวกับที่ผู้ใช้ถาม กระชับ และอ่านง่าย
`.trim();

// ไม่มีการใช้งานเกิน 20 นาที ให้ลืมบทสนทนา (ใช้เป็น TTL ของ key ใน Redis)
const SESSION_TTL_SECONDS = 20 * 60;
// เก็บข้อความล่าสุดไม่เกินเท่านี้ กันไม่ให้ส่งไป AI ยาวเกินไป
const MAX_HISTORY = 20;
// รูปไม่เก็บใน Redis (ใหญ่เกิน) เก็บแค่ข้อความนี้ไว้ในประวัติแทน
const IMAGE_PLACEHOLDER = '[แนบรูปภาพ]';

export const CHAT_IMAGE_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
];

export type ChatMessage = { role: 'user' | 'assistant'; content: string };
type ChatImage = { mimetype: string; buffer: Buffer };
type ChatSession = {
  recipeId: string;
  // instructions + ข้อมูลสูตร ดึงจาก DB ครั้งเดียวตอนเริ่ม session
  instructions: string;
  history: ChatMessage[];
};

const sessionKey = (userId: string) => `chat:session:${userId}`;

@Injectable()
export class ChatService implements OnModuleDestroy {
  private readonly client: OpenAI;
  private readonly model: string;
  // เก็บ session ใน Redis key = chat:session:{userId} หมดอายุเองตาม TTL
  private readonly redis: Redis;

  constructor(
    config: ConfigService,
    private readonly recipesService: RecipesService,
    private readonly recipeAccessService: RecipeAccessService,
  ) {
    const apiKey = config.get<string>('PSU_AI_API_KEY');
    const baseURL = config.get<string>('PSU_AI_BASE_URL') ?? DEFAULT_BASE_URL;

    this.client = new OpenAI({ apiKey, baseURL });
    this.model = config.get<string>('PSU_AI_MODEL') ?? DEFAULT_MODEL;
    this.redis = new Redis(
      config.get<string>('REDIS_URL') ?? DEFAULT_REDIS_URL,
    );
  }

  async onModuleDestroy() {
    await this.redis.quit();
  }

  async chat(
    userId: string,
    recipeId: string,
    message = '',
    image?: ChatImage,
  ) {
    const session = await this.getSession(userId, recipeId);

    // ใช้ chat.completions แบบ stream เพราะ PSU AI ตัดรูปทิ้งถ้าส่งผ่าน responses API
    const content: OpenAI.Chat.ChatCompletionContentPart[] = [];
    if (message) content.push({ type: 'text', text: message });
    if (image) {
      const url = `data:${image.mimetype};base64,${image.buffer.toString('base64')}`;
      content.push({ type: 'image_url', image_url: { url } });
    }

    let reply = '';
    try {
      const stream = await this.client.chat.completions.create({
        model: this.model,
        stream: true,
        messages: [
          { role: 'system', content: session.instructions },
          ...session.history,
          { role: 'user', content },
        ],
      });
      for await (const chunk of stream) {
        reply += chunk.choices[0]?.delta?.content ?? '';
      }
    } catch {
      throw new ServiceUnavailableException('Chat is temporarily unavailable');
    }

    // บันทึกเฉพาะตอนที่ AI ตอบสำเร็จ
    const userText = image
      ? [message, IMAGE_PLACEHOLDER].filter(Boolean).join(' ')
      : message;
    const history: ChatMessage[] = [
      ...session.history,
      { role: 'user', content: userText },
      { role: 'assistant', content: reply },
    ];
    session.history = history.slice(-MAX_HISTORY);
    await this.saveSession(userId, session);

    return { message: reply };
  }

  /** ประวัติแชทของสูตรนี้ ให้แอปโหลดกลับมาแสดงตอนเปิด popup ใหม่ */
  async getHistory(userId: string, recipeId: string): Promise<ChatMessage[]> {
    const raw = await this.redis.get(sessionKey(userId));
    const session = raw ? (JSON.parse(raw) as ChatSession) : null;
    // session เป็นของสูตรอื่น ถือว่าสูตรนี้ยังไม่มีแชท
    return session?.recipeId === recipeId ? session.history : [];
  }

  async reset(userId: string) {
    await this.redis.del(sessionKey(userId));
  }

  /** ใช้ได้เฉพาะสูตร official ที่เป็นเจ้าของหรือซื้อแล้ว (community ไม่มี AI) */
  async canChat(userId: string, recipeId: string): Promise<boolean> {
    const recipe = await this.recipesService.findOne(recipeId);
    return this.hasAccess(userId, recipe);
  }

  private async hasAccess(userId: string, recipe: Recipe): Promise<boolean> {
    if (recipe.type !== RecipeType.OFFICIAL) return false;
    return (
      recipe.creatorId === userId ||
      this.recipeAccessService.hasActiveAccess(userId, recipe.id)
    );
  }

  private async getSession(
    userId: string,
    recipeId: string,
  ): Promise<ChatSession> {
    const raw = await this.redis.get(sessionKey(userId));
    const existing = raw ? (JSON.parse(raw) as ChatSession) : null;
    // ยังคุยสูตรเดิมอยู่ ใช้ session เดิมต่อ
    if (existing && existing.recipeId === recipeId) return existing;

    // ไม่มี session หรือเปลี่ยนสูตร: เช็กสิทธิ์แล้วเริ่ม session ใหม่
    const recipe = await this.recipesService.findOne(recipeId);
    if (!(await this.hasAccess(userId, recipe))) {
      throw new ForbiddenException(
        'Chat is only available for purchased official recipes',
      );
    }

    const session: ChatSession = {
      recipeId,
      instructions: `${INSTRUCTIONS}\n\n# ข้อมูลสูตร\n${describeRecipe(recipe)}`,
      history: [],
    };
    await this.saveSession(userId, session);
    return session;
  }

  /** บันทึก session และต่ออายุ TTL ทุกครั้งที่มีการใช้งาน */
  private async saveSession(userId: string, session: ChatSession) {
    await this.redis.set(
      sessionKey(userId),
      JSON.stringify(session),
      'EX',
      SESSION_TTL_SECONDS,
    );
  }
}

/** แปลงสูตรจาก DB เป็นข้อความให้ AI อ่าน */
function describeRecipe(recipe: Recipe): string {
  const lines: string[] = [`ชื่อเมนู: ${recipe.title}`];

  if (recipe.shortDescription)
    lines.push(`คำอธิบาย: ${recipe.shortDescription}`);
  if (recipe.preparationMinutes != null)
    lines.push(`เวลาเตรียม: ${recipe.preparationMinutes} นาที`);
  if (recipe.cookingMinutes != null)
    lines.push(`เวลาทำ: ${recipe.cookingMinutes} นาที`);
  if (recipe.servingCount != null)
    lines.push(`สำหรับ: ${recipe.servingCount} ที่`);
  if (recipe.difficulty) lines.push(`ความยาก: ${recipe.difficulty}`);

  const ingredients = [...recipe.recipeIngredients].sort(
    (a, b) => a.sortOrder - b.sortOrder,
  );
  if (ingredients.length > 0) {
    lines.push('', '## วัตถุดิบ');
    for (const item of ingredients) {
      const amount = [item.amount, item.unit].filter(Boolean).join(' ');
      const note = item.preparationNote ? ` (${item.preparationNote})` : '';
      const optional = item.isOptional ? ' [ไม่ใส่ก็ได้]' : '';
      lines.push(
        `- ${item.ingredient.name} ${amount}${note}${optional}`.trim(),
      );
    }
  }

  // sections กับ contents ถูกเรียงตาม sortOrder มาแล้วจาก findOne
  if (recipe.sections.length > 0) {
    lines.push('', '## ขั้นตอน');
    recipe.sections.forEach((section, index) => {
      lines.push(`${index + 1}. ${section.title}`);
      if (section.description) lines.push(`   ${section.description}`);
      for (const content of section.contents) {
        if (!content.textContent) continue;
        const prefix =
          content.contentType === RecipeContentType.TIP
            ? 'เคล็ดลับ: '
            : content.contentType === RecipeContentType.WARNING
              ? 'ข้อควรระวัง: '
              : '';
        lines.push(`   - ${prefix}${content.textContent}`);
      }
    });
  }

  return lines.join('\n');
}
