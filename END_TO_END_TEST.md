# BabyBook 端到端测试步骤

## 测试环境要求

- macOS + Xcode 16+
- iOS 18+ 模拟器或真机
- Node.js 22+
- PostgreSQL 16（或 Docker）
- 可选：豆包 API Key（真实 AI 测试）

---

## 一、后端启动测试

### 步骤 1：启动数据库

```bash
# 使用 Docker 启动 PostgreSQL
docker run -d \
  --name babybook-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=babybook \
  -p 5432:5432 \
  postgres:16-alpine

# 验证数据库启动
docker ps | grep babybook-postgres
```

### 步骤 2：启动后端服务

```bash
cd backend/babybook-backend

# 安装依赖（如未安装）
npm install

# 配置环境变量
cp .env.example .env
# 编辑 .env，确保以下配置：
# DB_HOST=localhost
# DB_PORT=5432
# DB_USERNAME=postgres
# DB_PASSWORD=postgres
# DB_DATABASE=babybook
# MOCK_AI_GENERATION=true  # 测试环境使用 Mock

# 启动开发服务器
npm run start:dev
```

### 步骤 3：验证后端服务

```bash
# 测试健康检查
curl http://localhost:3000/api/order

# 测试 Swagger 文档
open http://localhost:3000/api/docs

# 运行 API 测试脚本
cd test
./test-api.sh
```

**预期结果**：
- 服务启动无报错
- Swagger 文档可访问
- 测试脚本全部通过

---

## 二、App 预览测试（SwiftUI Preview）

### 步骤 1：配置本地环境

编辑 `BabyBook/Sources/BabyBookApp/Services/APIConfig.swift`：

```swift
static let current: Environment = .local  // 切换到本地环境
```

### 步骤 2：Xcode 打开项目

```bash
# 使用 VSCode 打开（已配置 Swift 扩展）
cd BabyBook
# 或使用 Xcode 打开 Package.swift
open Package.swift
```

### 步骤 3：运行预览

在 Xcode 中：
1. 打开任意 SwiftUI 视图文件
2. 点击 `#Preview` 旁边的「运行」按钮
3. 观察 UI 渲染效果

**可预览的视图**：
- `HomeView.swift` - 首页
- `BookDetailView.swift` - 绘本详情
- `UploadPhotoView.swift` - 上传照片
- `PaymentView.swift` - 支付页面
- `GeneratingView.swift` - 生成中
- `CompleteView.swift` - 完成页面
- `MyBooksView.swift` - 我的绘本
- `OnboardingView.swift` - 首次引导

---

## 三、模拟器集成测试

### 步骤 1：启动 iOS 模拟器

Xcode → Window → Devices and Simulators → Simulators
选择 iPhone 16 Pro (iOS 18)

### 步骤 2：运行 App

Xcode → Product → Run (Cmd+R)

### 步骤 3：执行测试流程

#### 测试 A：首次启动引导

1. 删除 App（长按图标 → 删除）
2. 重新运行 App
3. **验证**：显示 4 页引导（欢迎 → 上传 → AI生成 → 保存）
4. 点击「开始使用」
5. **验证**：显示隐私提示弹窗
6. 点击「我知道了」
7. **验证**：进入首页

#### 测试 B：完整购买流程（Mock）

1. 首页左右滑动，切换绘本
2. 点击「一键定制」
3. **验证**：底部弹出上传面板
4. 点击「从相册选择」
5. 选择一张模拟器自带照片
6. **验证**：显示加载中「正在上传照片...」
7. **验证**：自动跳转到支付页
8. 点击「Apple Pay 支付」
9. **验证**：显示 Mock 支付成功，跳转到生成页
10. **验证**：显示进度动画，3 秒后自动完成
11. **验证**：跳转到完成页，显示绘本封面
12. 点击「保存绘本图片」
13. **验证**：提示已保存到相册
14. 点击「生成 PDF 电子版」
15. **验证**：提示 PDF 已生成
16. 点击底部「我的绘本」
17. **验证**：显示已生成的绘本列表

#### 测试 C：断网恢复测试

1. 重新开始购买流程
2. 在生成中页面，关闭 Mac 网络
3. **验证**：进度停止，显示网络错误提示
4. 恢复网络
5. **验证**：自动恢复轮询，继续生成

#### 测试 D：App 重启恢复测试

1. 完成支付，进入生成中页面
2. 按 Home 键退出 App（模拟器：Cmd+Shift+H）
3. 双击 Home 键，上滑关闭 App
4. 重新打开 App
5. **验证**：首页显示，但订单状态为 PAID/GENERATING
6. 进入「我的绘本」或重新查询
7. **验证**：能恢复之前的生成任务

---

## 四、真机测试（需要 Apple Developer 账号）

### 步骤 1：配置签名

Xcode → Signing & Capabilities
- Team: 选择你的 Apple Developer 账号
- Bundle Identifier: `com.yourcompany.babybook`

### 步骤 2：配置内购商品（沙盒测试）

App Store Connect → 你的 App → 订阅/内购
- 创建 3 个 Consumable 商品：
  - `com.babybook.book001` - 《这是我》
  - `com.babybook.book002` - 《我长大想做什么》
  - `com.babybook.book003` - 《认识颜色》

### 步骤 3：配置沙盒测试员

App Store Connect → 用户和访问 → 沙盒测试员
- 创建测试账号（使用真实邮箱格式，如 test@example.com）

### 步骤 4：真机运行

1. 连接 iPhone 到 Mac
2. Xcode → 选择你的 iPhone
3. Product → Run
4. 在 iPhone 设置 → App Store → 登录沙盒测试员账号

### 步骤 5：真实支付测试

1. 选择绘本 → 一键定制
2. 上传真实宝宝照片
3. 点击 Apple Pay 支付
4. **验证**：弹出 Apple Pay 确认界面
5. 使用 Touch ID / Face ID 确认
6. **验证**：支付成功，进入生成页面
7. 等待生成完成（Mock 模式约 3 秒，真实 AI 约 30-60 秒）
8. **验证**：下载图片和 PDF

---

## 五、后端压力测试

### 步骤 1：安装压测工具

```bash
npm install -g autocannon
```

### 步骤 2：运行压测

```bash
# 测试订单创建接口
autocannon -c 10 -d 30 \
  -m POST \
  -H "Content-Type: application/json" \
  -b '{"bookId":"Book001","deviceId":"test_device"}' \
  http://localhost:3000/api/order/create

# 测试订单查询接口
autocannon -c 50 -d 30 \
  http://localhost:3000/api/order?page=1&limit=10
```

### 预期结果

- 订单创建：RPS > 100，平均延迟 < 200ms
- 订单查询：RPS > 500，平均延迟 < 50ms

---

## 六、数据隐私验证

### 步骤 1：上传照片并生成

1. 完成一次完整购买流程
2. 记录上传的图片文件名

### 步骤 2：验证临时文件删除

```bash
# 检查后端 uploads/temp 目录
ls backend/babybook-backend/uploads/temp/

# 预期：上传的图片已删除（生成完成后自动清理）
```

### 步骤 3：验证数据库

```bash
# 连接数据库
docker exec -it babybook-postgres psql -U postgres -d babybook

# 查询订单
SELECT id, device_id, book_id, status, image_url, result_image_url FROM orders;

# 预期：image_url 和 result_image_url 应为空（已清理）
```

---

## 七、测试通过标准

| 测试项 | 通过标准 |
|--------|---------|
| 后端编译 | `npm run build` 无错误 |
| 后端启动 | 无报错，端口 3000 可访问 |
| API 测试 | `test-api.sh` 全部通过 |
| 首页显示 | 3 本绘本轮播正常 |
| 上传流程 | 选择照片 → 上传 → 创建订单成功 |
| 支付流程 | Mock/真实支付成功，状态变为 PAID |
| 生成流程 | 任务自动创建，轮询正常，最终 SUCCESS |
| 下载流程 | 图片保存到相册，PDF 保存到 Documents |
| 断网恢复 | 网络恢复后自动继续轮询 |
| App 重启 | 能恢复未完成的生成任务 |
| 数据隐私 | 临时图片已删除，数据库无残留 |

---

## 八、常见问题排查

### 问题 1：后端启动报错 `Connection refused`

**原因**：PostgreSQL 未启动
**解决**：
```bash
docker start babybook-postgres
```

### 问题 2：App 无法连接后端

**原因**：模拟器和后端不在同一网络
**解决**：
```swift
// 使用 localhost（模拟器）
static let baseURL = "http://localhost:3000"

// 或局域网 IP（真机）
static let baseURL = "http://192.168.x.x:3000"
```

### 问题 3：StoreKit 支付失败

**原因**：未配置沙盒测试员或商品 ID 不匹配
**解决**：
1. 检查 App Store Connect 商品配置
2. 检查 `PaymentService.swift` 中的 productIDs
3. 确保登录沙盒测试员账号

### 问题 4：AI 生成超时

**原因**：真实 AI API 调用较慢
**解决**：
```bash
# 测试环境使用 Mock
MOCK_AI_GENERATION=true
```

---

## 九、测试完成后的清理

```bash
# 停止后端
Ctrl+C

# 停止数据库
docker stop babybook-postgres
docker rm babybook-postgres

# 清理上传的临时文件
rm -rf backend/babybook-backend/uploads/temp/*
```
