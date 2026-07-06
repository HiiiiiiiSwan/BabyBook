import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 启用全局验证管道
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true, // 自动剔除 DTO 中未定义的属性
    transform: true, // 自动转换类型
    forbidNonWhitelisted: true, // 禁止提交 DTO 中未定义的属性
  }));

  // 配置 Swagger 文档（生产环境不暴露）
  if (process.env.NODE_ENV !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('BabyBook API')
      .setDescription('宝贝绘本后端 API 文档')
      .setVersion('1.0.0')
      .addTag('订单', '订单管理相关接口')
      .addTag('支付', 'Apple IAP 支付验证')
      .addTag('任务', 'AI 生成任务管理')
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
  }

  // 启用 CORS（iOS App 白名单）
  const nodeEnv = process.env.NODE_ENV;
  const corsOriginEnv = process.env.CORS_ORIGIN;
  const productionOrigins = corsOriginEnv ? corsOriginEnv.split(',').map((o) => o.trim()) : [];

  app.enableCors({
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      // 生产环境：只允许配置的白名单域名
      if (nodeEnv === 'production') {
        if (!origin || productionOrigins.includes(origin)) {
          callback(null, true);
          return;
        }
        callback(new Error('不允许的跨域来源'), false);
        return;
      }

      // 开发/测试环境：允许本地、局域网、预发布域名
      const allowedOrigins = [
        'http://localhost:3000',
        'http://localhost:8081',
        'https://staging-api.babybook.com',
        ...productionOrigins,
      ];
      const isAllowed =
        !origin ||
        allowedOrigins.includes(origin) ||
        /^https?:\/\/192\.168\.\d{1,3}\.\d{1,3}(:\d+)?$/.test(origin) ||
        /^https?:\/\/10\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d+)?$/.test(origin);

      if (isAllowed) {
        callback(null, true);
      } else {
        callback(new Error('不允许的跨域来源'), false);
      }
    },
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type,Authorization,X-Device-Id',
    credentials: false,
  });

  const port = process.env.PORT ?? 3000;
  // 监听 0.0.0.0 以支持局域网真机访问（默认 localhost 只允许本机）
  await app.listen(port, '0.0.0.0');
  console.log(`🚀 BabyBook 后端服务已启动，端口: ${port}`);
  console.log(`📚 API 文档地址: http://localhost:${port}/api/docs`);
}
bootstrap();
