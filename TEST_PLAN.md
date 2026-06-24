# BabyBook 测试方案

## 一、测试环境准备

### 1.1 后端本地测试环境

```bash
# 1. 进入后端目录
cd backend/babybook-backend

# 2. 安装依赖
npm install

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env，填入测试配置：
# - DB_HOST=localhost (本地 PostgreSQL)
# - DOUBAO_API_KEY=your_key (可选，AI测试可用 Mock)

# 4. 启动本地 PostgreSQL（或用 Docker）
docker run -d \
  --name babybook-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DATABASE=babybook \
  -p 5432:5432 \
  postgres:16-alpine

# 5. 启动后端服务
npm run start:dev
```

### 1.2 iOS App 测试配置

在 `APIConfig.swift` 中切换测试环境：

```swift
enum APIConfig {
    // 本地测试
    static let baseURL = "http://localhost:3000"
    
    // 局域网测试（真机）
    // static let baseURL = "http://192.168.x.x:3000"
    
    // 生产环境
    // static let baseURL = "https://your-railway-app.railway.app"
}
```

---

## 二、分层测试策略

### 2.1 后端单元测试（NestJS）

| 测试文件 | 测试内容 | 命令 |
|---------|---------|------|
| `order.service.spec.ts` | 订单创建、查询、状态流转 | `npm test -- order` |
| `payment.service.spec.ts` | 支付验证、收据校验 | `npm test -- payment` |
| `task.service.spec.ts` | 任务创建、状态更新、重试 | `npm test -- task` |
| `ai.service.spec.ts` | Prompt 构建、API 调用 | `npm test -- ai` |

### 2.2 后端 API 集成测试

使用 `test/api-test.http` 或 Postman 进行接口测试。

### 2.3 iOS App 测试

| 测试类型 | 工具 | 范围 |
|---------|------|------|
| UI 预览测试 | Xcode Preview | 单个视图 |
| 单元测试 | XCTest | Services、Models |
| UI 测试 | XCUITest | 完整用户流程 |
| 真机测试 | iPhone | 支付、相机、相册 |

---

## 三、核心流程测试用例

### 用例 1：完整购买流程（Happy Path）

**前置条件**：后端启动，数据库已连接

**步骤**：
1. 调用 `POST /api/order/create` 创建订单
2. 调用 `POST /api/upload/image` 上传宝宝照片
3. 调用 `PATCH /api/order/:id/image` 更新订单图片
4. 调用 `POST /api/payment/verify` 验证支付（Mock Apple 收据）
5. 调用 `GET /api/task/order/:orderId` 轮询任务状态
6. 调用 `GET /api/book/:orderId/download` 获取下载信息

**预期结果**：
- 订单状态流转：UNPAID → PAID → GENERATING → SUCCESS
- 任务状态：PENDING → RUNNING → COMPLETED
- 返回图片 URL

### 用例 2：支付后 App 崩溃恢复

**步骤**：
1. 完成支付验证（步骤 1-4）
2. 模拟 App 崩溃（关闭 App）
3. 重新打开 App，查询订单列表
4. 发现 PAID 订单，继续轮询任务状态

**预期结果**：
- 服务端已自动创建生成任务
- App 能恢复轮询并获取最终结果

### 用例 3：AI 生成失败重试

**步骤**：
1. 配置错误的 AI API Key
2. 完成支付
3. 观察任务状态变为 FAILED
4. 等待 2 分钟（定时任务重试）
5. 配置正确的 API Key

**预期结果**：
- 任务自动重试 2 次
- 重试成功后状态变为 COMPLETED

### 用例 4：数据隐私验证

**步骤**：
1. 上传宝宝照片
2. 完成生成
3. 检查 `uploads/temp` 目录
4. 检查数据库 `orders` 表

**预期结果**：
- 临时图片已删除
- 数据库中无图片 URL 残留（或已清空）

---

## 四、测试检查清单

### 后端检查项

- [ ] `npm run build` 编译成功
- [ ] `npm test` 全部通过
- [ ] Swagger 文档可访问：`http://localhost:3000/api/docs`
- [ ] 数据库连接正常
- [ ] 定时任务运行正常（重试、超时）
- [ ] CORS 配置正确（iOS 可访问）

### App 检查项

- [ ] 首次启动引导显示正常
- [ ] 隐私提示弹窗正常
- [ ] 首页绘本轮播正常
- [ ] 绘本详情页翻页正常
- [ ] 照片选择/上传正常
- [ ] 订单创建成功
- [ ] 支付流程（Mock/真实）正常
- [ ] 生成进度轮询正常
- [ ] 下载图片保存到相册
- [ ] PDF 生成并保存到 Documents
- [ ] 我的绘本列表显示正常
- [ ] 分享功能正常
- [ ] 删除功能正常

### 端到端检查项

- [ ] 完整流程：上传 → 支付 → 生成 → 下载
- [ ] 断网恢复：生成中关闭网络，恢复后继续轮询
- [ ] App 重启恢复：支付后杀掉 App，重新打开继续
- [ ] 多设备隔离：device_id 不同，数据不互通

---

## 五、Mock 测试模式

### 5.1 后端 Mock 模式

在 `.env` 中设置：

```env
# 启用 Mock AI 生成（不调用真实 API）
MOCK_AI_GENERATION=true
MOCK_IMAGE_URL=https://example.com/mock-book.png
```

### 5.2 App Mock 模式

在 `APIConfig.swift` 中：

```swift
enum APIConfig {
    static let useMock = true  // 切换 Mock/真实
    
    static var baseURL: String {
        return useMock ? "http://localhost:3000" : "https://production-api.com"
    }
}
```

---

## 六、性能测试

| 指标 | 目标 | 测试方法 |
|------|------|---------|
| 订单创建 | < 500ms | 重复调用 100 次 |
| 图片上传 | < 3s (5MB) | 上传不同大小图片 |
| 支付验证 | < 2s | Mock 收据测试 |
| AI 生成 | < 60s | 真实 API 调用 |
| 任务轮询 | 3s 间隔 | 观察服务端压力 |
| PDF 生成 | < 2s | 本地测试 |

---

## 七、测试命令速查

```bash
# 后端测试
npm run build          # 编译
npm test               # 运行所有测试
npm test -- order      # 仅运行订单测试
npm run start:dev      # 开发模式启动

# App 测试
# Xcode: Cmd+U 运行单元测试
# Xcode: Product > Test 运行 UI 测试
# 真机：连接 iPhone，选择设备运行
```
