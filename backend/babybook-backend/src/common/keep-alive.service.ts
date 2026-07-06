import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

/**
 * Supabase Free 项目 7 天无查询会自动暂停。
 * 本服务作为多层 keep-alive 的一环，每天对数据库做一次真实查询。
 * 注意：它不能替代 GitHub Actions/UptimeRobot 的外部心跳，
 * 因为 Railway Hobby 长期无流量时也会休眠，导致定时任务不执行。
 */
@Injectable()
export class KeepAliveService {
  private readonly logger = new Logger(KeepAliveService.name);

  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  @Cron('7 2 */1 * *') // 每天凌晨 2:07 执行，避开准点高峰
  async keepDatabaseAlive() {
    try {
      await this.dataSource.query('SELECT 1');
      this.logger.log('Keep-alive query executed successfully');
    } catch (error) {
      this.logger.error('Keep-alive query failed', error);
    }
  }
}
