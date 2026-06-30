# BabyBook 项目变更日志

## 格式规范

- **日期**: YYYY-MM-DD
- **版本**: 使用语义化版本号（MVP 阶段用 v0.x.x）
- **类型**: `feat` 新功能 / `fix` 修复 / `docs` 文档 / `style` 样式 / `refactor` 重构 / `chore` 杂项

---

## [Unreleased]

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

