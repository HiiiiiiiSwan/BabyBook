# BabyBook 项目变更日志

## 格式规范

- **日期**: YYYY-MM-DD
- **版本**: 使用语义化版本号（MVP 阶段用 v0.x.x）
- **类型**: `feat` 新功能 / `fix` 修复 / `docs` 文档 / `style` 样式 / `refactor` 重构 / `chore` 杂项

---

## [Unreleased]

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

