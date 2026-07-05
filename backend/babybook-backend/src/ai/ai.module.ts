import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AiService } from './ai.service';
import { MockAiService } from './mock-ai.service';

/**
 * AI 模块
 * 根据环境配置切换真实 AI / Mock AI
 */
const aiServiceProvider = {
  provide: AiService,
  useFactory: (configService: ConfigService) => {
    const useMock = configService.get('MOCK_AI_GENERATION') === 'true';
    if (useMock) {
      console.log('[AI 模块] MOCK_AI_GENERATION=true, 使用 MockAI 服务');
      return new MockAiService(configService);
    }
    console.log('[AI 模块] MOCK_AI_GENERATION=false, 使用真实豆包 Seedream 服务');
    return new AiService(configService);
  },
  inject: [ConfigService],
};

@Module({
  imports: [ConfigModule],
  providers: [aiServiceProvider, MockAiService],
  exports: [AiService],
})
export class AiModule {}
