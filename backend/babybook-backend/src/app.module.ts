import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { OrderModule } from './order/order.module';
import { PaymentModule } from './payment/payment.module';
import { TaskModule } from './task/task.module';
import { AiModule } from './ai/ai.module';
import { BookModule } from './book/book.module';
import { UploadModule } from './upload/upload.module';

@Module({
  imports: [
    // 配置模块，加载环境变量
    ConfigModule.forRoot({
      isGlobal: true, // 全局可用
      envFilePath: '.env',
    }),
    // 数据库模块
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => {
        // 优先使用 DATABASE_URL（Railway 自动注入）
        const databaseUrl = configService.get('DATABASE_URL');
        if (databaseUrl) {
          return {
            type: 'postgres',
            url: databaseUrl,
            entities: [__dirname + '/**/*.entity{.ts,.js}'],
            migrations: [__dirname + '/migrations/**/*{.ts,.js}'],
            synchronize: false, // 生产环境禁止自动同步
            migrationsRun: false, // 手动运行迁移，避免启动时不可控变更
            ssl: { rejectUnauthorized: false }, // Railway PostgreSQL 需要 SSL
          };
        }
        // 本地开发使用独立配置
        return {
          type: 'postgres',
          host: configService.get('DB_HOST', 'localhost'),
          port: configService.get<number>('DB_PORT', 5432),
          username: configService.get('DB_USERNAME', 'postgres'),
          password: configService.get('DB_PASSWORD', 'postgres'),
          database: configService.get('DB_DATABASE', 'babybook'),
          entities: [__dirname + '/**/*.entity{.ts,.js}'],
          migrations: [__dirname + '/migrations/**/*{.ts,.js}'],
          synchronize: configService.get('NODE_ENV') !== 'production',
          migrationsRun: false,
          ssl: configService.get('DB_SSL') === 'true' ? { rejectUnauthorized: false } : false,
        };
      },
      inject: [ConfigService],
    }),
    // 定时任务模块（用于轮询和重试）
    ScheduleModule.forRoot(),
    // 全局限流：防止接口被高频滥用烧掉豆包生图额度
    // 默认每个 IP 60 秒内最多 60 次请求；烧钱接口在 controller 层单独收紧
    ThrottlerModule.forRoot([
      {
        ttl: 60000, // 时间窗口 60 秒
        limit: 60, // 窗口内最大请求数
      },
    ]),
    // 业务模块
    OrderModule,
    PaymentModule,
    TaskModule,
    AiModule,
    BookModule,
    UploadModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    // 将 ThrottlerGuard 注册为全局守卫，所有接口默认受限流保护
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
