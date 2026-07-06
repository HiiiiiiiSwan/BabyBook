# BabyBook 后端 Railway 部署配置

## 1. 创建 Railway 项目

访问 https://railway.app/ 并登录，创建新项目。

## 2. 添加 PostgreSQL 数据库

在 Railway 项目中：
- 点击 "New" → "Database" → "Add PostgreSQL"
- Railway 会自动创建数据库并注入 `DATABASE_URL` 环境变量

## 3. 部署后端服务

### 方式一：通过 GitHub 部署（推荐）

1. 将代码推送到 GitHub 仓库
2. 在 Railway 中点击 "New" → "GitHub Repo"
3. 选择你的仓库，Railway 会自动检测 Dockerfile 并部署

### 方式二：通过 Railway CLI 部署

```bash
# 安装 Railway CLI
npm install -g @railway/cli

# 登录
railway login

# 关联项目
railway link

# 部署
railway up
```

## 4. 环境变量配置

在 Railway 项目的 "Variables" 中设置以下环境变量：

| 变量名 | 说明 | 必填 |
|--------|------|------|
| `NODE_ENV` | 环境模式，设为 `production` | 是 |
| `DOUBAO_API_KEY` | 豆包 API Key | 是 |
| `DOUBAO_API_URL` | 豆包 API 地址 | 否（有默认值） |
| `DOUBAO_MODEL` | 模型名称 | 否（默认 seedream-5.0-lite） |
| `APPLE_SHARED_SECRET` | Apple Shared Secret（可选） | 否 |

注意：`DATABASE_URL` 和 `PORT` 由 Railway 自动注入，无需手动设置。

## 5. 数据库迁移

首次部署后，需要执行数据库迁移：

```bash
# 进入 Railway 容器
railway connect

# 运行迁移（生产环境已关闭 synchronize，必须手动执行）
npm run migration:run
```

## 6. 验证部署

部署完成后，访问以下地址验证：

- API 文档：`https://your-app-url.railway.app/api/docs`（生产环境已关闭）
- 健康检查：`https://your-app-url.railway.app/health`

## 7. 自定义域名（可选）

在 Railway 的 Settings 中可以绑定自定义域名。

## 注意事项

1. **数据库 SSL**：Railway 的 PostgreSQL 默认启用 SSL，应用已配置自动适配
2. **环境变量**：生产环境不要在代码中硬编码敏感信息
3. **日志查看**：在 Railway Dashboard 中查看服务日志
4. **自动重启**：Railway 会自动重启崩溃的服务
