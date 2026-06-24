import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
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
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get('DB_HOST', 'localhost'),
        port: configService.get<number>('DB_PORT', 5432),
        username: configService.get('DB_USERNAME', 'postgres'),
        password: configService.get('DB_PASSWORD', 'postgres'),
        database: configService.get('DB_DATABASE', 'babybook'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: configService.get('NODE_ENV') !== 'production', // 生产环境关闭自动同步
        ssl: configService.get('DB_SSL') === 'true' ? { rejectUnauthorized: false } : false,
      }),
      inject: [ConfigService],
    }),
    // 定时任务模块（用于轮询和重试）
    ScheduleModule.forRoot(),
    // 业务模块
    OrderModule,
    PaymentModule,
    TaskModule,
    AiModule,
    BookModule,
    UploadModule,
  ],
})
export class AppModule {}
