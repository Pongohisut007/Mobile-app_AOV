import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';

const DEFAULT_BASE_URL = 'https://ai.psu.blue/v1';
const DEFAULT_MODEL = 'openai/gpt-5.6-luna';

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
        input: message,
      });
      return { message: response.output_text };
    } catch {
      throw new ServiceUnavailableException('Chat is temporarily unavailable');
    }
  }
}
