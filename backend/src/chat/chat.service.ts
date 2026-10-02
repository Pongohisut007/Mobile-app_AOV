import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';

const DEFAULT_BASE_URL = 'https://ai.psu.blue/v1';
const DEFAULT_MODEL = 'openai/gpt-5.6-luna';

const INSTRUCTIONS = `
คุณคือผู้ช่วยด้านอาหารของแอปสูตรอาหาร
ตอบได้เฉพาะเรื่องอาหารเท่านั้น เช่น สูตรอาหาร วิธีทำ วัตถุดิบ เทคนิคการทำอาหาร โภชนาการ และการแนะนำเมนู
ถ้าผู้ใช้ถามเรื่องอื่นที่ไม่เกี่ยวกับอาหาร ให้ปฏิเสธอย่างสุภาพ และชวนให้ถามเรื่องอาหารแทน
ตอบเป็นภาษาเดียวกับที่ผู้ใช้ถาม กระชับ และอ่านง่าย
`.trim();

// ไม่มีการใช้งานเกิน 20 นาที ให้ลืมบทสนทนา
const SESSION_TIMEOUT_MS = 20 * 60 * 1000;
// เก็บข้อความล่าสุดไม่เกินเท่านี้ กันไม่ให้ส่งไป AI ยาวเกินไป
const MAX_HISTORY = 20;

type ChatMessage = { role: 'user' | 'assistant'; content: string };
type ChatSession = { history: ChatMessage[]; lastActiveAt: number };

@Injectable()
export class ChatService {
  private readonly client: OpenAI;
  private readonly model: string;
  // key = userId (เก็บในหน่วยความจำ restart server แล้วหาย)
  private readonly sessions = new Map<string, ChatSession>();

  constructor(config: ConfigService) {
    const apiKey = config.get<string>('PSU_AI_API_KEY');
    const baseURL = config.get<string>('PSU_AI_BASE_URL') ?? DEFAULT_BASE_URL;

    this.client = new OpenAI({ apiKey, baseURL });
    this.model = config.get<string>('PSU_AI_MODEL') ?? DEFAULT_MODEL;
  }

  async chat(userId: string, message: string) {
    const session = this.getSession(userId);
    const input: ChatMessage[] = [
      ...session.history,
      { role: 'user', content: message },
    ];

    let reply: string;
    try {
      const response = await this.client.responses.create({
        model: this.model,
        instructions: INSTRUCTIONS,
        input,
      });
      reply = response.output_text;
    } catch {
      throw new ServiceUnavailableException('Chat is temporarily unavailable');
    }

    // บันทึกเฉพาะตอนที่ AI ตอบสำเร็จ
    input.push({ role: 'assistant', content: reply });
    session.history = input.slice(-MAX_HISTORY);
    session.lastActiveAt = Date.now();

    return { message: reply };
  }

  reset(userId: string) {
    this.sessions.delete(userId);
  }

  private getSession(userId: string): ChatSession {
    this.removeExpiredSessions();

    let session = this.sessions.get(userId);
    if (!session) {
      session = { history: [], lastActiveAt: Date.now() };
      this.sessions.set(userId, session);
    }
    return session;
  }

  private removeExpiredSessions() {
    const now = Date.now();
    for (const [userId, session] of this.sessions) {
      if (now - session.lastActiveAt > SESSION_TIMEOUT_MS) {
        this.sessions.delete(userId);
      }
    }
  }
}
