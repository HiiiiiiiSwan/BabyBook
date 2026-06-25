import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Mock AI 生成服务
 * 用于测试环境，不调用真实 AI API
 */
@Injectable()
export class MockAiService {
  constructor(private configService: ConfigService) {}

  /**
   * Mock 生成绘本图片
   * 返回预设图片 URL，用于测试流程
   */
  async generateBookImage(params: { bookId: string; imageUrl: string }): Promise<string> {
    const mockImageUrl = this.configService.get(
      'MOCK_IMAGE_URL',
      'https://picsum.photos/2048/2048',
    );

    // 模拟生成延迟
    await this.delay(3000);

    return mockImageUrl;
  }

  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
