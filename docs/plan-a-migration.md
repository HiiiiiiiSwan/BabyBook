# BabyBook 方案 A 迁移操作清单

## 目标

将数据库从 Railway PostgreSQL 迁移到 Supabase Free PostgreSQL，后端服务继续保留在 Railway，通过 keep-alive 避免 Supabase 自动暂停，并通过监控及时发现问题。

## 预期效果

- 月度成本从约 $15–25/月 降至约 **$5/月**（仅 Railway Hobby 后端）
- 数据库部分 $0（Supabase Free）
- 增加 keep-alive + 监控运维成本（一次性配置）

---

## 阶段一：创建 Supabase 数据库

### 步骤 1：注册/登录 Supabase

1. 访问 [supabase.com](https://supabase.com)
2. 用 GitHub 账号登录（推荐，部署集成方便）

### 步骤 2：新建项目

1. 点击 **New project**
2. 选择组织（Organization）
3. 填写：
   - **Name**：`babybook-production`
   - **Database Password**：设置强密码并保存到密码管理器
   - **Region**：选择离 Railway 部署区域最近的地区（如 Railway 在美国，就选 `North America` 下最近的）
4. 点击 **Create new project**，等待约 1–2 分钟初始化

### 步骤 3：获取数据库连接字符串

1. 进入项目后，点击左侧 **Project Settings**（齿轮图标）
2. 选择 **Database**
3. 找到 **Connection string** 区域
4. 选择 **URI** 格式，复制类似：
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.xxxxxxxxxxxxxxxxxxxx.supabase.co:5432/postgres
   ```
5. 把 `[YOUR-PASSWORD]` 替换为实际密码
6. 保存到安全位置（后续步骤使用）

### 步骤 4：确认网络访问权限

1. 在 Supabase 左侧菜单选择 **Project Settings → Database**
2. 找到 **Network Restrictions**
3. 确认允许所有 IP 访问（默认就是开放的）
4. 如果后续想更安全，可以只放 Railway 后端的出口 IP（需要查 Railway 文档获取）

---

## 阶段二：准备后端迁移

### 步骤 5：备份当前 Railway 数据库数据

目的：保留现有订单/任务记录，需要时可以手动迁移。

方法：

1. 打开 Railway 控制台
2. 进入项目的 PostgreSQL 服务
3. 找到 **Backups** 或 **Connect** 标签
4. 使用 `pg_dump` 导出：
   ```bash
   pg_dump $DATABASE_URL -F c -f babybook_backup.dump
   ```
5. 保存备份文件到本地安全位置

> 如果当前是测试数据，没有真实订单，可以跳过数据迁移，直接重新建表。

### 步骤 6：在本地测试 Supabase 连接

1. 在项目根目录创建临时 `.env.supabase`：
   ```bash
   DATABASE_URL=postgresql://postgres:你的密码@db.xxx.supabase.co:5432/postgres
   ```
2. 进入后端目录：
   ```bash
   cd backend/babybook-backend
   ```
3. 临时用该 env 测试迁移：
   ```bash
   export $(cat .env.supabase | xargs)
   npm run migration:run
   ```
4. 如果成功，检查 Supabase 中是否创建了 `orders` 和 `tasks` 表

---

## 阶段三：增强后端健康检查（可选但强烈建议）

当前 `/health` 只返回 `status: ok`，**不检查数据库连接**。迁移后需要让它真实检查数据库，这样监控才能发现 Supabase 暂停问题。

### 步骤 7：修改 health 接口

编辑文件：`backend/babybook-backend/src/app.controller.ts`

将：

```typescript
@Get('health')
@SkipThrottle()
health(): { status: string; timestamp: number } {
  return {
    status: 'ok',
    timestamp: Date.now(),
  };
}
```

改为：

```typescript
@Get('health')
@SkipThrottle()
async health(
  @InjectDataSource() private dataSource: DataSource,
): Promise<{ status: string; timestamp: number; db: string }> {
  try {
    await this.dataSource.query('SELECT 1');
    return {
      status: 'ok',
      timestamp: Date.now(),
      db: 'connected',
    };
  } catch (error) {
    return {
      status: 'error',
      timestamp: Date.now(),
      db: 'disconnected',
    };
  }
}
```

并添加导入：

```typescript
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
```

> 注意：当前 Railway 的健康检查配置是 `healthcheckPath: "/health"`，返回非 200 会被认为不健康。上面的代码即使数据库断开也返回 200（只是 `status: error`），这样容器不会重启，但监控可以检测到。如果你希望 Railway 自动重启，可以让数据库断开时抛出异常返回 500。

---

## 阶段四：配置 Railway 使用 Supabase

### 步骤 8：更新 Railway 环境变量

1. 打开 Railway 控制台
2. 进入 BabyBook 后端服务
3. 点击 **Variables**
4. 找到当前的 `DATABASE_URL`（Railway 自动注入的 PostgreSQL 变量）
5. 添加新的环境变量：
   - **Name**：`DATABASE_URL`
   - **Value**：Supabase 的连接字符串
6. 如果旧的 `DATABASE_URL` 是 Railway 自动生成的，需要先删除或覆盖它
7. 确保其他环境变量保持不变：
   - `DOUBAO_API_KEY`
   - `DOUBAO_API_URL`
   - `DOUBAO_MODEL`
   - `APPLE_SHARED_SECRET`
   - `NODE_ENV=production`

### 步骤 9：重新部署后端

1. 推送一次空提交触发部署，或在 Railway 控制台点击 **Deploy**：
   ```bash
   git commit --allow-empty -m "chore: 切换数据库到 Supabase Free"
   git push
   ```
2. Railway 部署前会自动执行 `npm run migration:run:prod`
3. 部署完成后访问：
   ```
   https://babybook-api-production-ef09.up.railway.app/health
   ```
4. 确认返回：
   ```json
   {
     "status": "ok",
     "timestamp": 1234567890,
     "db": "connected"
   }
   ```

### 步骤 10：验证核心流程

1. 用 App 或 Postman 测试：
   - `POST /api/order/create`
   - `POST /api/payment/verify`
   - `GET /api/task/order/:orderId`
   - `GET /api/book/:orderId/image`
2. 确认订单能正常写入 Supabase 数据库
3. 在 Supabase 的 **Table Editor** 中查看 `orders` 和 `tasks` 表是否有新记录

---

## 阶段五：Keep-Alive 防止 Supabase 暂停

Supabase Free 项目如果 **7 天内没有数据库查询活动**会自动暂停。需要每 1–2 天触发一次真实的数据库查询。

### 方案 A-1：GitHub Actions 定时唤醒（推荐，免费）

在代码仓库添加 GitHub Actions 工作流：

1. 新建文件：
   `.github/workflows/keep-supabase-alive.yml`

2. 内容：

```yaml
name: Keep Supabase Alive

on:
  schedule:
    # 每 36 小时运行一次（避免正好每 24 小时，分散任务）
    - cron: '0 6 */1 * *'
  workflow_dispatch: # 允许手动触发

jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - name: Ping Railway health endpoint
        run: |
          curl -fsS \
            --retry 3 \
            --max-time 30 \
            "https://babybook-api-production-ef09.up.railway.app/health" \
            | tee health_response.json

      - name: Check database status
        run: |
          DB_STATUS=$(jq -r '.db' health_response.json)
          STATUS=$(jq -r '.status' health_response.json)
          if [ "$DB_STATUS" != "connected" ] || [ "$STATUS" != "ok" ]; then
            echo "Database health check failed!"
            cat health_response.json
            exit 1
          fi
          echo "Health check passed: db=$DB_STATUS status=$STATUS"
```

3. 提交并推送到 GitHub：
   ```bash
   git add .github/workflows/keep-supabase-alive.yml
   git commit -m "chore: 添加 Supabase keep-alive 工作流"
   git push
   ```

4. 在 GitHub 仓库页面确认：
   - **Actions** 标签能看到该工作流
   - 手动运行一次测试成功
   - 每 36 小时自动运行

### 方案 A-2：UptimeRobot 外部监控（同时实现告警）

UptimeRobot 免费版可以每 5 分钟检查一次 URL：

1. 注册 [uptimerobot.com](https://uptimerobot.com)
2. 添加 Monitor：
   - **Monitor Type**：HTTP(s)
   - **Friendly Name**：`BabyBook Health`
   - **URL**：`https://babybook-api-production-ef09.up.railway.app/health`
3. 配置告警方式：
   - 邮箱（免费）
   - 或绑定 Slack / Telegram / 钉钉 Webhook
4. 如果 `/health` 返回非 200 或响应超时，会收到邮件通知

> 注意：UptimeRobot 只检查 HTTP 200，不解析 JSON。所以如果你按步骤 7 增强了 health，数据库断开时仍返回 200，UptimeRobot 会误判为正常。建议：
> - 方案 A-1 的 GitHub Actions 负责 keep-alive
> - 方案 A-2 的 UptimeRobot 只作为粗粒度可用性监控

### 方案 A-3：后端自身定时心跳（最省事但依赖后端存活）

利用后端已有的 `@nestjs/schedule` 模块，每天对数据库做一次查询：

1. 新建文件：`backend/babybook-backend/src/common/keep-alive.service.ts`

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

@Injectable()
export class KeepAliveService {
  private readonly logger = new Logger(KeepAliveService.name);

  constructor(@InjectDataSource() private dataSource: DataSource) {}

  @Cron('0 2 */1 * *') // 每天凌晨 2 点执行
  async keepDatabaseAlive() {
    try {
      await this.dataSource.query('SELECT 1');
      this.logger.log('Keep-alive query executed successfully');
    } catch (error) {
      this.logger.error('Keep-alive query failed', error);
    }
  }
}
```

2. 在 `backend/babybook-backend/src/app.module.ts` 的 `providers` 数组中添加 `KeepAliveService`

> 这个方案的问题是：如果 Railway 后端也休眠（Hobby 长时间无流量也会 sleep），定时任务不会执行。所以**不能单独依赖这个方案**，要和 GitHub Actions 或外部 ping 配合使用。

---

## 阶段六：监控告警方案（推荐组合）

### 推荐组合

| 工具 | 作用 | 费用 |
|------|------|------|
| **GitHub Actions** | 每 36 小时 ping `/health`，保持 Supabase 活跃 | 免费 |
| **UptimeRobot** | 每 5 分钟检查后端是否在线 | 免费 |
| **Railway 自带告警** | 服务异常时通知 | 免费 |

### 监控配置清单

1. **UptimeRobot Monitor**
   - URL：`https://babybook-api-production-ef09.up.railway.app/health`
   - 检查间隔：5 分钟
   - 超时：30 秒
   - 告警邮箱：你的邮箱
   - 告警方式：邮件（免费版）或 Slack Webhook

2. **GitHub Actions Keep-Alive**
   - 运行频率：每 36 小时
   - 触发目标：`/health`
   - 检查返回 JSON 中 `db === "connected"`

3. **Railway 健康检查**
   - 已配置：`healthcheckPath: "/health"`
   - 超时：30 秒
   - 失败自动重启：最多 10 次

### 告警内容示例

当 UptimeRobot 检测到后端不可用时，会收到类似邮件：

> Monitor: BabyBook Health  
> URL: https://babybook-api-production-ef09.up.railway.app/health  
> Status: DOWN  
> Reason: Connection timeout

当 GitHub Actions keep-alive 失败时，GitHub 会发邮件：

> [ babybook-backend ] Keep Supabase Alive workflow run failed

---

## 阶段七：成本与风险确认

### 迁移后月度成本

| 项目 | 平台 | 费用 |
|------|------|------|
| NestJS 后端服务 | Railway Hobby | **$5/月** |
| PostgreSQL 数据库 | Supabase Free | **$0/月** |
| 外部监控 | UptimeRobot Free | **$0/月** |
| Keep-Alive | GitHub Actions Free | **$0/月** |
| **合计** | | **约 $5/月** |

### 风险与应对

| 风险 | 影响 | 应对方案 |
|------|------|----------|
| Supabase 7 天暂停 | 用户下单/支付失败 | GitHub Actions 每 36 小时 ping |
| GitHub Actions 失效 | 暂停风险恢复 | UptimeRobot 监控 + 邮件告警 |
| Supabase Free 存储 500MB 用完 | 无法写入新订单 | 当前只存元数据，可用很多年；接近时清理旧记录或升级 |
| Supabase Free 流量 5GB/月 用完 | 查询变慢/受限 | 元数据查询极小，几乎不可能用完 |
| Railway Hobby 无流量休眠 | 首次访问慢 | 已被 UptimeRobot 5 分钟 ping 保持活跃 |
| 数据库迁移失败 | 服务不可用 | 保留 Railway PostgreSQL 备份，可快速回滚 |

---

## 阶段八：迁移检查表

- [ ] 创建 Supabase 项目并获取 `DATABASE_URL`
- [ ] 本地测试 Supabase 连接并运行迁移成功
- [ ] 增强 `/health` 接口检查数据库连接
- [ ] 更新 Railway 环境变量 `DATABASE_URL`
- [ ] 重新部署并验证 `/health` 返回 `db: connected`
- [ ] 测试完整下单/支付/生成流程
- [ ] 添加 GitHub Actions keep-alive 工作流
- [ ] 配置 UptimeRobot 监控
- [ ] 备份 Railway 数据库
- [ ] 确认旧 Railway PostgreSQL 服务可以删除（部署后 1 周无异常再删）

---

## 可选：进一步省钱

如果 $5/月也不想花，可以考虑：

1. **把后端也迁到免费平台**
   - Render Free：有免费 Web Service，但会休眠
   - Fly.io Free：有免费额度
   - Vercel/Netlify Functions：不适合 NestJS 长时间运行

2. **保留 Railway Hobby 的原因**
   - 生成任务需要长时间运行（AI 调用 10 分钟）
   - 需要稳定不休眠的环境
   - 需要磁盘空间存放临时图片

所以 **$5/月的 Railway Hobby + Supabase Free 是性价比最高的组合**。
