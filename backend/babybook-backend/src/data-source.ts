import { DataSource } from 'typeorm';
import { config } from 'dotenv';

// 加载本地 .env（如果存在）
config();

/**
 * TypeORM DataSource
 * 用于 CLI 执行迁移：npm run migration:run / migration:generate
 */
export default new DataSource({
  type: 'postgres',
  url: process.env.DATABASE_URL,
  host: process.env.DATABASE_URL ? undefined : (process.env.DB_HOST || 'localhost'),
  port: process.env.DATABASE_URL ? undefined : parseInt(process.env.DB_PORT || '5432', 10),
  username: process.env.DATABASE_URL ? undefined : (process.env.DB_USERNAME || 'postgres'),
  password: process.env.DATABASE_URL ? undefined : (process.env.DB_PASSWORD || 'postgres'),
  database: process.env.DATABASE_URL ? undefined : (process.env.DB_DATABASE || 'babybook'),
  entities: [__dirname + '/**/*.entity{.ts,.js}'],
  migrations: [__dirname + '/migrations/**/*{.ts,.js}'],
  synchronize: false,
  ssl: process.env.DATABASE_URL
    ? { rejectUnauthorized: false }
    : process.env.DB_SSL === 'true'
      ? { rejectUnauthorized: false }
      : false,
});
