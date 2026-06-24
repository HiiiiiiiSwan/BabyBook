# BabyBook 后端服务

宝贝绘本 iOS App 的后端 API 服务，基于 NestJS + PostgreSQL 构建。

## 技术栈

- **框架**: NestJS 11
- **数据库**: PostgreSQL 16 + TypeORM 0.3.20
- **部署**: Railway + Docker
- **AI**: 豆包 Seedream 5.0 Lite（九宫格图片生成）
- **定时任务**: NestJS Schedule（失败重试、超时处理）

## 项目结构

```
src/
├── common/
│   └── enums.ts              # 业务枚举（订单状态、绘本模板、任务状态）
├── order/
│   ├── entities/
│   │   └── order.entity.ts   # 订单实体
│   ├── dto/
│   │   └── order.dto.ts      # 订单 DTO
│   ├── order.service.ts      # 订单服务
│   ├── order.controller.ts   # 订单控制器
│   └── order.module.ts       # 订单模块
├── payment/
│   ├── dto/
│   │   └── payment.dto.ts    # 支付 DTO
│   ├── payment.service.ts    # 支付服务（Apple IAP 验证）
│   ├── payment.controller.ts # 支付控制器
│   └── payment.module.ts     # 支付模块
├── task/
│   ├── entities/
│   │   └── task.entity.ts    # 任务实体
│   ├── dto/
│   │   └── task.dto.ts       # 任务 DTO
│   ├── task.service.ts       # 任务服务（生成队列、重试机制）
│   ├── task.controller.ts    # 任务控制器
│   └── task.module.ts        # 任务模块
├── ai/
│   ├── ai.service.ts         # AI 生成服务（豆包 Seedream）
│   └── ai.module.ts          # AI 模块
├── book/
│   ├── book.service.ts       # 绘本服务（下载）
│   ├── book.controller.ts    # 绘本控制器
│   └── book.module.ts        # 绘本模块
├── app.module.ts             # 根模块
└── main.ts                   # 入口文件
```

## 核心业务流程

```
用户选择绘本 → 创建订单(UNPAID) → Apple IAP 支付
  → 提交支付验证 → 服务端验证收据
    → 验证成功 → 自动创建生成任务 → 更新订单为 GENERATING
      → AI 生成九宫格图片（单本仅调用一次）
        → 生成成功 → 订单变为 SUCCESS
        → 生成失败 → 自动重试 2 次 → 仍失败标记 FAILED
    → 验证失败 → 保持 UNPAID
```

## 环境变量

复制 `.env.example` 为 `.env` 并配置：

| 变量名 | 说明 | 必填 |
|--------|------|------|
| `NODE_ENV` | 环境模式 | 是 |
| `PORT` | 服务端口 | 否（默认 3000） |
| `DB_HOST` | 数据库主机 | 是 |
| `DB_PORT` | 数据库端口 | 否（默认 5432） |
| `DB_USERNAME` | 数据库用户名 | 是 |
| `DB_PASSWORD` | 数据库密码 | 是 |
| `DB_DATABASE` | 数据库名称 | 是 |
| `DB_SSL` | 是否启用 SSL | 否 |
| `DOUBAO_API_KEY` | 豆包 API Key | 是 |
| `DOUBAO_API_URL` | 豆包 API 地址 | 否（有默认值） |
| `DOUBAO_MODEL` | 模型名称 | 否（默认 seedream-5.0-lite） |
| `APPLE_SHARED_SECRET` | Apple Shared Secret | 否 |

## 本地开发

```bash
# 安装依赖
npm install

# 启动 PostgreSQL（使用 Docker）
docker-compose up -d db

# 配置环境变量
cp .env.example .env
# 编辑 .env 填入数据库和豆包 API 配置

# 启动开发服务器
npm run start:dev

# 访问 Swagger 文档
open http://localhost:3000/api/docs
```

## 部署到 Railway

详见 [RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md)。

## API 文档

详见 [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)。

## 关键设计决策

1. **匿名用户模式**：无需登录/注册，使用 `device_id` 标识用户
2. **支付后自动创建任务**：服务端自动触发，确保用户关闭 App/崩溃/断网不影响生成
3. **单本绘本仅调用一次 AI**：输出单张 2048×2048 九宫格图片，控制成本
4. **数据最小化**：宝宝照片和绘本图片生成后立即删除，仅保留订单记录
5. **自动重试机制**：AI 生成失败自动重试 2 次，超时任务自动标记失败

## 数据隐私

- **宝宝照片**：上传后仅用于 AI 生成，生成完成立即删除
- **绘本图片**：生成后立即删除，不保存
- **PDF 文件**：仅保存在用户本地 iOS Documents 目录，不上传云端
- **保留数据**：仅保存订单记录（order_id, device_id, book_id, payment_id, amount, status, 时间戳）
