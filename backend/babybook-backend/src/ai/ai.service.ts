import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import FormData from 'form-data';
import { BookTemplate } from '../common/enums';

/**
 * AI 生成请求参数
 */
interface GenerateImageParams {
  bookId: BookTemplate;
  imageUrl: string; // 宝宝照片 URL
}

/**
 * 豆包 Seedream API 响应
 */
interface SeedreamResponse {
  data?: {
    image_url?: string;
    images?: string[];
  };
  error?: {
    code: string;
    message: string;
  };
}

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly apiKey: string;
  private readonly apiUrl: string;
  private readonly modelName: string;

  constructor(private configService: ConfigService) {
    // 从环境变量读取豆包 API 配置
    this.apiKey = this.configService.get<string>('DOUBAO_API_KEY', '');
    this.apiUrl = this.configService.get<string>(
      'DOUBAO_API_URL',
      'https://ark.cn-beijing.volces.com/api/v3/images/generations',
    );
    this.modelName = this.configService.get<string>('DOUBAO_MODEL', 'seedream-5.0-lite');
  }

  /**
   * 生成绘本九宫格图片
   * 核心业务：单本绘本仅调用一次生图模型，输出单张 2048×2048 九宫格图片
   */
  async generateBookImage(params: GenerateImageParams): Promise<string> {
    const { bookId, imageUrl } = params;

    if (!this.apiKey) {
      throw new Error('豆包 API Key 未配置');
    }

    // 根据绘本模板获取对应的 Prompt
    const prompt = this.buildPrompt(bookId);

    this.logger.log(`开始生成绘本图片: ${bookId}, 模型: ${this.modelName}`);

    try {
      // 构建请求体
      const requestBody = {
        model: this.modelName,
        prompt: prompt,
        reference_images: [
          {
            image_url: imageUrl,
            // 多图参考模式，使用宝宝照片作为角色参考
            reference_type: 'character',
          },
        ],
        // 输出 2048×2048 九宫格图片
        width: 2048,
        height: 2048,
        // 返回图片 URL
        response_format: 'url',
      };

      const response = await axios.post<SeedreamResponse>(
        this.apiUrl,
        requestBody,
        {
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 300000, // 300 秒超时（九宫格生成较慢）
        },
      );

      if (response.data.error) {
        throw new Error(`AI 生成失败: ${response.data.error.message}`);
      }

      // 获取生成的图片 URL
      const resultUrl =
        response.data.data?.image_url ||
        response.data.data?.images?.[0];

      if (!resultUrl) {
        throw new Error('AI 生成返回结果为空');
      }

      this.logger.log(`绘本图片生成成功: ${resultUrl.substring(0, 50)}...`);
      return resultUrl;
    } catch (error) {
      this.logger.error(`AI 生成失败: ${error.message}`);
      throw new Error(`AI 生成失败: ${error.message}`);
    }
  }

  /**
   * 构建绘本生成 Prompt
   * 根据绘本模板生成对应的九宫格内容描述
   */
  private buildPrompt(bookId: BookTemplate): string {
    const basePrompt =
      'Create a warm storybook 3D illustration in a 3x3 grid layout (2048x2048). ' +
      'Each cell contains one page of a children\'s picture book. ' +
      'Style: Warm Storybook 3D, cute chibi proportions, rounded shapes, soft lighting, low complexity details. ' +
      'The main character is the baby from the reference photo. ' +
      'Background elements: clouds, grass, hot air balloons, teddy bears, rabbits, stars, books, leaves. ';

    const bookPrompts: Record<BookTemplate, string> = {
      [BookTemplate.SELF_INTRO]:
        basePrompt +
        'Theme: Body awareness "This is Me". ' +
        'Page 1: Cover with title "This is Me" and the baby. ' +
        'Page 2: "This is my head" - baby touching head. ' +
        'Page 3: "This is my eyes" - baby pointing to eyes. ' +
        'Page 4: "This is my nose" - baby touching nose. ' +
        'Page 5: "This is my mouth" - baby smiling. ' +
        'Page 6: "This is my ears" - baby touching ears. ' +
        'Page 7: "This is my hands" - baby waving hands. ' +
        'Page 8: "This is my feet" - baby showing feet. ' +
        'Page 9: "I love myself" - baby hugging self. ' +
        'Color palette: warm orange #F28C28, cream #FFF9F2, soft green.',

      [BookTemplate.DREAM_JOB]:
        basePrompt +
        'Theme: Career awareness "What I Want to Be When I Grow Up". ' +
        'Page 1: Cover with title and the baby in a graduation cap. ' +
        'Page 2: "I want to be a doctor" - baby with stethoscope. ' +
        'Page 3: "I want to be a teacher" - baby with books. ' +
        'Page 4: "I want to be a chef" - baby with chef hat. ' +
        'Page 5: "I want to be an astronaut" - baby in space suit. ' +
        'Page 6: "I want to be a firefighter" - baby with helmet. ' +
        'Page 7: "I want to be a scientist" - baby with microscope. ' +
        'Page 8: "I want to be an artist" - baby with paintbrush. ' +
        'Page 9: "I can be anything" - baby surrounded by all professions. ' +
        'Color palette: warm orange #F28C28, sky blue, soft yellow.',

      [BookTemplate.COLOR_RECOGNITION]:
        basePrompt +
        'Theme: Color recognition "Learning Colors". ' +
        'Page 1: Cover with title "Learning Colors" and rainbow. ' +
        'Page 2: "Red" - red apple, red balloon, red flower. ' +
        'Page 3: "Orange" - orange fruit, orange sun, orange cat. ' +
        'Page 4: "Yellow" - yellow banana, yellow star, yellow duck. ' +
        'Page 5: "Green" - green leaf, green frog, green tree. ' +
        'Page 6: "Blue" - blue sky, blue whale, blue bird. ' +
        'Page 7: "Purple" - purple grape, purple butterfly, purple flower. ' +
        'Page 8: "Pink" - pink pig, pink flower, pink candy. ' +
        'Page 9: "All colors together" - rainbow with the baby. ' +
        'Color palette: vibrant but soft, pastel backgrounds.',
    };

    return bookPrompts[bookId] || basePrompt;
  }
}
