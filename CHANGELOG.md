# BabyBook 项目变更日志

## 格式规范

- **日期**: YYYY-MM-DD
- **版本**: 使用语义化版本号（MVP 阶段用 v0.x.x）
- **类型**: `feat` 新功能 / `fix` 修复 / `docs` 文档 / `style` 样式 / `refactor` 重构 / `chore` 杂项

---

## [Unreleased]

### 2026-07-07

- `feat` 优化生成中页面进度体验并添加耗时诊断日志
  - 后端任务进度统一映射到前端：0%=未创建、10%=已创建/排队/已提交、10%~89%=真实生图过程
  - AI 生图阶段匀速爬升从 135 秒拉长到 180 秒，降低卡在 89% 的概率
  - 新增 `[生成耗时]` 诊断日志：到达 89% 时间、后端 COMPLETED 总耗时、89% 等待时长
  - 真机沙盒验收：成功加载 3 个产品，支付+生成完整链路跑通，总耗时 156.1 秒

- `fix` 修复 App Store Connect 上传验证失败
  - `TARGETED_DEVICE_FAMILY` 从 `"1,2"` 改为 `"1"`，仅支持 iPhone，解决 iPad 多任务方向校验失败
  - `Info.plist` build version 从 1 升到 2
  - Build 2 已成功上传 TestFlight，状态 Ready to Submit

### 2026-07-06

- `fix` 修复 Railway 部署缺失绘本模板导致《认识颜色》生成失败
  - 根因：Docker 构建上下文为 `backend/babybook-backend`，未包含项目根目录的 `templates/`，容器内 `/templates/...` 路径不存在
  - `railway.json`：构建上下文改为项目根目录，`dockerfilePath` 指定为 `backend/babybook-backend/Dockerfile`
  - `Dockerfile`：从项目根目录复制后端源码与 `templates/` 到镜像 `/app/templates`
  - `ai.service.ts`：`getTemplatePath` 增加 `/app/templates` 等多路径候选，兼容 Docker 生产环境与本地开发
  - 新增项目根目录 `.dockerignore`，限制构建上下文仅包含后端源码与模板资源

- `fix` 修复 App 健康检查端点 URL 错误
  - 后端 `/health` 位于根路径，不加 `/api` 前缀
  - `APIConfig.swift`：`healthCheck` 使用 `baseURL + "/health"`，其他接口仍使用 `fullBaseURL`

- `feat` 后端生产环境加固与 App 上线前优化
  - 切换 App API 环境为 production，保留 Railway 域名占位符
  - 后端 CORS 改为白名单配置，生产环境只允许 `CORS_ORIGIN` 配置的域名
  - 生产环境关闭 Swagger 文档暴露
  - `paymentId` 添加唯一索引，并在支付验证前校验 `transactionId` 是否已被使用
  - `GET /api/upload/image/:filename` 增加 `DeviceAuthGuard` 认证
  - 新增 `/health` 健康检查端点，Dockerfile `HEALTHCHECK` 改为探测 `/health`
  - 创建 TypeORM 迁移脚本与 `data-source.ts`，`package.json` 新增 `migration:generate/run/revert` 脚本
  - 统一模板目录命名为 `pages`（`dream_job`、`color_recognition`）
  - App 价格展示改用 StoreKit `Product.displayPrice`，无产品时回退到本地价格
  - 新增 `PrivacyInfo.xcprivacy` 隐私清单文件，并集成到 Xcode 项目与生成脚本

- `fix` 修复杀端恢复后失败页误触发与历史订单反复弹窗
  - `BabyBookApp.swift`：启动时调用 `loadLastOrder()` 清理超过 30 分钟的过期本地订单，防止历史失败记录反复弹窗
  - 恢复弹窗根据订单状态（`FAILED` / `SUCCESS` / `GENERATING`）动态调整标题、文案与路由
  - `FAILED` 订单直接跳转 `FailureResultView`，不再经过 `GeneratingView` 再闪跳失败页
  - `OrderStatusManager.restoreOrderIfNeeded()` 不再启动轮询，统一由 `GeneratingView.onAppear` 调用 `startPolling`，避免旧 `timeoutTask` 残留 `isTimeout=true` 与新的状态监听器产生竞态
  - `FailureResultView` 进入 `onAppear` 时立即清除本地订单记录，避免用户在失败页杀端后下次启动再次弹窗
  - `GeneratingView` 进入时重置 `isTimeout` 与 `pollingFailureCount`，消除上次残留状态
  - 新增 AI 生图阶段匀速进度动画（0~89%），以真实后端进度为地板持续爬升，避免进度条长时间死卡在 30%
  - 网络异常时暂停进度动画，网络恢复后继续，避免视觉倒退
  - 超时监听增加 `!statusManager.isPolling` 保护，过滤残留超时信号误触发失败页

- `chore` 后端 AI 调用超时调整
  - `ai.service.ts`：`axios` 超时从 300 秒延长至 600 秒，匹配实测 1~5 分钟生图耗时
  - `task.service.ts`：兜底超时 Cron 阈值从 5 分钟延长至 15 分钟，仅作为 axios 异常未被捕获时的兜底

### 2026-07-05

- `fix` 生成中页断网恢复与失败状态判定优化
  - `GeneratingView` 支持真实任务轮询、网络异常 Toast、自动重试与网络恢复监听
  - 新增整理阶段进度动画，生成完成后自动下载并预加载绘本图片
  - 新增 `FailureResultView` 跳转入口，AI 最终失败后展示失败原因
  - **关键修复**：后端任务 `FAILED` 后仍会自动重试最多 2 次，期间订单仍保持 `GENERATING`；生成中页现在以订单状态为准，只有订单真正 `FAILED` 才跳转失败页，避免断网/杀端恢复后直接进入失败结果页
  - `OrderStatusManager` 新增轮询失败计数与超时标志，完善杀端/崩溃后订单恢复轮询逻辑

- `chore` 上线前安全与审核修复
  - 清理后端 `dist` 构建产物，避免源码/密钥随编译输出提交
  - 后端接入 `@nestjs/throttler` 全局限流：默认 60 秒 60 次请求，保护豆包生图接口不被高频滥用
  - 新增 `generate:books` / `generate:color` npm 脚本，用于绘本模板批量生成
  - 新增 `backend/babybook-backend/.dockerignore`，避免 Docker 构建时打包 dist / node_modules / 环境变量文件
  - 新增 `FailureResultView.swift`：AI 最终生成失败后展示失败原因与客服二维码，引导用户返回首页
  - 移除 `GeneratingView` 的「取消生成」按钮及相关 Alert，避免消耗型商品误操作导致不可退款的审核风险
  - 新增 `BabyBook/Sources/BabyBookApp/Info.plist` 与 `zh-Hans.lproj/InfoPlist.strings`，完善权限说明本地化
  - 新增 `BabyBookProducts.storekit` StoreKit 配置文件，便于 IAP 审核与本地测试
  - 新增 `support.png` 客服二维码资源，用于失败结果页与完成页
  - 更新 `PRIVACY_POLICY.md`：补充照片临时 URL、生成结果图片 URL、Apple 支付收据、失败错误信息的收集与保留说明
  - 更新 `design/directions.png` 流程图，删除/重命名旧版 photocase 资源，新增 IAP 审核用绘本示例图
  - 多处 App UI 与资源微调：完成页、我的绘本列表/详情、首页、支付页、上传照片弹窗等

### 2026-06-30

- `feat` 我的绘本自动生成与列表 UI 优化
  - 生成成功后自动保存绘本到本地（真机下载 task.resultUrl，模拟器使用 cover 资源模拟）
  - 绘本生成时间使用 `task.updatedAt`，我的绘本按生成时间排序展示
  - 我的绘本列表页封面改为 80×80 正方形缩放展示，完整显示生成图片
  - 我的绘本详情页封面放大，与完成页尺寸保持一致
  - 我的绘本列表底部增加保存提示文案，距最后卡片 16pt
  - 移除顶部「共 X 本」计数文案
- `fix` 消耗型 IAP 合规：移除我的绘本页「恢复购买」按钮
  - 绘本定制为 Consumable 消耗型商品，Apple 不要求也不支持恢复购买
  - 未完成交易仍通过 `Transaction.updates` 自动恢复

### 2026-06-30

- `style` 优化上传照片弹窗、绘本详情页和完成页 UI
  - 上传照片弹窗：标题改为「请上传照片并完成支付」，新增副标题并高亮「1张」「￥1.0」主色
  - 上传照片弹窗：新增灰底照片建议区，标题改为「上传照片建议：」，示例照片放大到 120×120pt
  - 上传照片弹窗：「示例」标签移至照片左上角，仅左上角和右下角圆角
  - 上传照片弹窗：拍照按钮图标和文字颜色改为主色 `#F28C28`
  - 绘本详情页：预览区域加入封底（`9.png`），分页指示器从 5 页扩展为 6 页
  - 绘本详情页：「绘本示例」标题改为横线 + 星星装饰样式，字号 18pt 加粗
  - 绘本详情页：分页指示器文案去掉「第」「页」，仅显示「1 / 6」
  - 完成页：去掉绘本名称下方的「9页 · 中英双语」文案

### 2026-06-29

- `chore` 添加 App Store 加密合规声明 `ITSEncryptionExportComplianceCode`
  - 在 `generate_xcode_proj.py` 的 Debug/Release 配置中添加 `INFOPLIST_KEY_ITSEncryptionExportComplianceCode = ""`
  - 说明：BabyBook 使用标准 HTTPS（TLS）和 iOS 系统 Keychain，属于 Apple 加密豁免范围，无需上传加密文档
  - 解决 App Store Connect 提交时 "App Encryption Documentation" 要求

### 2026-06-28

- `feat` P2 模块：体验优化（人脸检测 + 拍照功能 + 取消退款提示）
  - 新增 `FaceDetectionService.swift`：基于 Apple Vision 框架实现真实人脸检测
    - 支持检测单张/多张人脸、无人脸、检测失败三种结果
    - 使用 `VNDetectFaceRectanglesRequest` 进行人脸矩形检测
    - 非 UIKit 平台自动跳过检测
  - 新增 `CameraView.swift`：基于 AVFoundation 的相机拍照功能
    - 使用 `UIViewControllerRepresentable` 桥接 UIKit 到 SwiftUI
    - 支持实时预览、拍照、切换前后摄像头、点击对焦
    - 相机权限检查（未授权时引导用户到设置）
  - 更新 `UploadPhotoView.swift` 和 `HomeView.swift` 的 `UploadPhotoSheet`：
    - 拍照按钮从空 action 改为调用 `checkCameraPermission()`
    - 从相册选择后调用 `performFaceDetection()` 替代模拟延迟
    - 新增人脸检测失败 Alert（未检测到人脸 / 多张人脸 / 检测失败）
  - 更新 `GeneratingView.swift`：取消生成后显示退款提示
    - 新增 `showRefundAlert`："绘本生成已取消，已支付金额将原路退回（预计 1-3 个工作日到账）"
    - 点击"返回首页"清空导航栈回到首页
  - 更新 `project.pbxproj`：添加 `NSCameraUsageDescription` 和 `NSPhotoLibraryUsageDescription` 权限声明
  - 截图验收：新增 `07-generating-page.png`, `08-home-camera-button.png`

### 2026-06-27

- `style` 调整首页插画布局、完成页和生成页标题字号
  - 首页: 重构底部操作区为 ZStack，插画作为背景贴底，移除按钮背景色透出插画
  - 首页: 调整插画左右边距为 45px，底部内边距为 110px
  - 首页: 更新 homeBG.png 和 balloon.png 插画资源
  - 完成页: 标题「专属绘本已生成」字号从 22pt 放大到 28pt
  - 生成页: 标题文案改为「魔法生成中...」，字号从 20pt 放大到 28pt

### 2026-06-26

- `security` 将 device_id 从 UserDefaults 迁移到 iOS Keychain 存储
  - 新增 `KeychainService` 封装类，基于 iOS Security 框架
  - 支持 save/read/delete 操作，使用 `kSecAttrAccessibleAfterFirstUnlock` 安全级别
  - `DeviceService` 优先从 Keychain 读取，兼容旧版本 UserDefaults 自动迁移
  - 卸载 App 后 device_id 仍然保留，符合匿名设备模式设计规范
  - 新增 `BabyBookApp.entitlements` 文件修复编译问题

- `feat` 配置 App Store IAP 产品 ID、Bundle ID、Team ID 和沙盒测试环境
  - 更新 Bundle ID: `com.babybook.app` → `com.shihui.babybook`（与 App Store Connect 一致）
  - 设置 Development Team ID: `7BSKXTD6DF`
  - 更新 IAP 产品 ID 前缀: `com.shihui.babybook.book001/002/003`
  - 添加 `StoreKit.framework` 和 In-App Purchase Capability
  - 新增 `BabyBookApp.entitlements` 启用 IAP 权限
  - 生成 3 张 IAP 审核截图占位图 (640×920)，用于 App Store Connect 提交

- `feat` 完成3本绘本AI九宫格生成方案验证，含生成脚本和效果测试
  - 新增 `generate-grid-book.ts`: 《这是我》绘本单本生成脚本（2图参考模式）
  - 新增 `generate-books.ts`: 多绘本批量生成脚本（职业+颜色）
  - 验证3本绘本生成效果：《这是我》《我长大想做什么》《认识颜色》
  - 测试不同宝宝照片（babyimage.png / babyimage2.png）的生成效果
  - 对比2图 vs 3图参考模式，确认2图模式更稳定且人物特征保留更好
  - 新增 babyimage2.png 测试素材
  - 生成效果文件：uploads/grid-generated-*.png

### 2026-06-25

- `feat` 接入豆包 Seedream 5.0 图生图模型，实现绘本九宫格 AI 生成能力
  - 重写 `ai.service.ts`，使用多图参考模式（模板图 + 宝宝照片）
  - 构建详细中文 Prompt，精确控制每格内容、肤色、姿态、背景融合
  - 支持 3 本绘本：《这是我》《我长大想做什么》《认识颜色》
  - 更新 `mock-ai.service.ts` 兼容新接口签名
  - 更新 `.env.example` 配置模板（模型名 `doubao-seedream-5-0-260128`）
  - 效果已验证：《这是我》绘本生成成功，同一宝宝一致性、模板文字保留、身体部位对应均达标
- `chore` 补充绘本模板素材：`dream_job/all-none.png`、`color_recognition/all-none.png`、`color_recognition/all.png`

### 2026-06-24

- `feat` 初始化 Git 仓库，添加 `.gitignore` 和 `CHANGELOG.md`
- `docs` 更新 `CLAUDE.md`，补充页面导航说明、关键组件说明、导航标题规范
- `fix` 修复首页「一键定制」按钮无法拉起上传照片弹窗的问题（统一 `.overlay` 条件判断）
- `style` 绘本完成页：去掉多余返回箭头、去掉底部 Tab 导航栏
- `style` 生成中页：标题改为 `.toolbar` 规范、去掉左上角返回箭头、添加底部插画 `generating.png`
- `style` 生成中页：底部插画宽度调整为页面全宽

