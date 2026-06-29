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

  // 配置 Swagger 文档
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

  // 启用 CORS（允许 iOS App 访问）
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type,Authorization,X-Device-Id',
  });

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`🚀 BabyBook 后端服务已启动，端口: ${port}`);
  console.log(`📚 API 文档地址: http://localhost:${port}/api/docs`);
}
bootstrap();
