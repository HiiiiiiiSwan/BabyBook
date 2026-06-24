"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const app_module_1 = require("./app.module");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
    }));
    const config = new swagger_1.DocumentBuilder()
        .setTitle('BabyBook API')
        .setDescription('宝贝绘本后端 API 文档')
        .setVersion('1.0.0')
        .addTag('订单', '订单管理相关接口')
        .addTag('支付', 'Apple IAP 支付验证')
        .addTag('任务', 'AI 生成任务管理')
        .build();
    const document = swagger_1.SwaggerModule.createDocument(app, config);
    swagger_1.SwaggerModule.setup('api/docs', app, document);
    app.enableCors({
        origin: '*',
        methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
        allowedHeaders: 'Content-Type,Authorization',
    });
    const port = process.env.PORT ?? 3000;
    await app.listen(port);
    console.log(`🚀 BabyBook 后端服务已启动，端口: ${port}`);
    console.log(`📚 API 文档地址: http://localhost:${port}/api/docs`);
}
bootstrap();
//# sourceMappingURL=main.js.map