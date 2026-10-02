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

@Injectable()
export class ChatService {
  private readonly client: OpenAI;
  private readonly model: string;

  constructor(config: ConfigService) {
    const apiKey = config.get<string>('PSU_AI_API_KEY');
    const baseURL = config.get<string>('PSU_AI_BASE_URL') ?? DEFAULT_BASE_URL;

    this.client = new OpenAI({ apiKey, baseURL });
    this.model = config.get<string>('PSU_AI_MODEL') ?? DEFAULT_MODEL;
  }

  async chat(message: string) {
    try {
      const response = await this.client.responses.create({
        model: this.model,
        instructions: INSTRUCTIONS,
        input: message,
      });
      return { message: response.output_text };
    } catch {
      throw new ServiceUnavailableException('Chat is temporarily unavailable');
    }
  }
}
