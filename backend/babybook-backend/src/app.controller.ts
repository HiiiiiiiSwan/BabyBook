import { Controller, Get } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { SkipThrottle } from '@nestjs/throttler';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    @InjectDataSource() private readonly dataSource: DataSource,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  /**
   * 健康检查接口
   * 用于容器健康探测与 App 启动时触发网络权限弹窗，无需认证，不限流
   * 迁移到 Supabase 后增加真实数据库探测，便于 keep-alive/监控发现暂停
   */
  @Get('health')
  @SkipThrottle()
  async health(): Promise<{ status: string; timestamp: number; db: string }> {
    try {
      await this.dataSource.query('SELECT 1');
      return {
        status: 'ok',
        timestamp: Date.now(),
        db: 'connected',
      };
    } catch {
      return {
        status: 'error',
        timestamp: Date.now(),
        db: 'disconnected',
      };
    }
  }
}
