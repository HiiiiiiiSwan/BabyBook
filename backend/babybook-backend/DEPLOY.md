# BabyBook 后端生产环境部署配置

## 1. 数据库配置（Supabase）

### 创建 Supabase 项目
1. 访问 https://supabase.com/ 并注册/登录
2. 点击 "New Project"
3. 设置项目名称：`babybook-prod`
4. 选择地区：新加坡（离中国最近）
5. 选择 Free Plan
6. 设置数据库密码（保存好！）

### 获取数据库连接信息
1. 进入项目 Dashboard → Settings → Database
2. 找到 "Connection string" → "URI" 格式：
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.xxxxxxxx.supabase.co:5432/postgres
   ```
3. 这个 URI 就是 `DATABASE_URL`

### 注意事项
- Supabase Free 计划有 500MB 存储限制，足够 MVP 使用
- 连接池限制：10 个并发连接
- 备份：每天自动备份

## 2. Railway 部署步骤

### 方式一：GitHub 部署（推荐）

1. **推送代码到 GitHub**
   ```bash
   git add .
   git commit -m "feat: 配置 Railway 生产环境部署"
   git push origin main
   ```

2. **在 Railway 中创建项目**
   - 访问 https://railway.app/
   - 点击 "New Project" → "Deploy from GitHub repo"
   - 选择 `babybook-backend` 仓库
   - Railway 会自动检测 Dockerfile

3. **添加 PostgreSQL 数据库（可选，也可直接用 Supabase）**
   - 点击 "New" → "Database" → "Add PostgreSQL"
   - 或跳过此步，使用外部 Supabase 数据库

4. **配置环境变量**
   在 Railway Dashboard → 你的服务 → Variables 中添加：

   | 变量名 | 值 | 说明 |
   |--------|-----|------|
   | `NODE_ENV` | `production` | 生产环境标识 |
   | `DATABASE_URL` | `postgresql://...` | Supabase 连接 URI |
   | `DOUBAO_API_KEY` | `ark-...` | 豆包 API Key |
   | `DOUBAO_API_URL` | `https://ark.cn-beijing.volces.com/api/v3/images/generations` | 豆包 API 地址 |
   | `DOUBAO_MODEL` | `doubao-seedream-5-0-260128` | 模型名称 |
   | `APPLE_SHARED_SECRET` | `your_secret` | Apple IAP Shared Secret（可选） |
   | `MOCK_AI_GENERATION` | `false` | 关闭 Mock 模式 |

5. **部署**
   - Railway 会自动构建并部署
   - 查看 Logs 确认启动成功

### 方式二：Railway CLI 部署

```bash
# 安装 Railway CLI
npm install -g @railway/cli

# 登录
railway login

# 进入项目目录
cd backend/babybook-backend

# 关联项目（首次）
railway link

# 设置环境变量
railway variables set NODE_ENV=production
railway variables set DATABASE_URL="postgresql://..."
railway variables set DOUBAO_API_KEY="ark-..."

# 部署
railway up
```

## 3. 数据库迁移

首次部署后，需要创建数据库表：

```bash
# 进入 Railway 容器
railway connect

# 运行 TypeORM 同步（生产环境建议手动迁移）
npx typeorm schema:sync -d dist/src/data-source.js
```

或者使用 SQL 手动创建表（见 database/init.sql）。

## 4. 验证部署

部署完成后，访问以下地址验证：

- **API 文档**：`https://your-app-url.railway.app/api/docs`
- **健康检查**：`https://your-app-url.railway.app/api/order`
- **Swagger UI**：`https://your-app-url.railway.app/api/docs`

## 5. 自定义域名（可选）

在 Railway Dashboard → Settings → Domains 中绑定自定义域名。

## 6. 监控与日志

- **日志**：Railway Dashboard → Logs
- **指标**：Railway Dashboard → Metrics
- **告警**：可设置 CPU/内存/重启告警

## 注意事项

1. **API Key 安全**：
   - 永远不要把 `.env` 文件提交到 Git
   - 已在 `.gitignore` 中排除
   - 生产环境变量只在 Railway 中设置

2. **数据库安全**：
   - Supabase 默认启用 SSL
   - 已配置 `rejectUnauthorized: false` 适配
   - 定期备份数据

3. **成本控制**：
   - Railway Free Plan：每月 $5 额度，足够小项目
   - Supabase Free Plan：500MB 存储，足够 MVP
   - 豆包 API：按调用量计费，注意监控

4. **故障处理**：
   - Railway 自动重启崩溃服务
   - 数据库连接失败会自动重试
   - AI 生成失败会自动重试 2 次
