#!/bin/bash
# BabyBook Xcode 预览修复脚本

echo "🔧 开始修复 Xcode 预览问题..."

# 1. 清理 Derived Data
echo "🧹 清理 Derived Data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/BabyBookApp-*
rm -rf ~/Library/Developer/Xcode/DerivedData/Package-*

# 2. 清理 Swift Package 缓存
echo "🧹 清理 Swift Package 缓存..."
rm -rf /Users/wang/Documents/Vibe\ coding/【新】宝贝绘本/BabyBook/.build/
rm -rf /Users/wang/Documents/Vibe\ coding/【新】宝贝绘本/BabyBook/.swiftpm/xcode/package.resolved

# 3. 清理 Xcode 预览缓存
echo "🧹 清理预览缓存..."
rm -rf ~/Library/Developer/Xcode/UserData/Previews/

# 4. 重置模拟器缓存（可选）
echo "🧹 清理模拟器缓存..."
rm -rf ~/Library/Developer/CoreSimulator/Caches/

echo "✅ 清理完成！"
echo ""
echo "📋 接下来请按以下步骤操作："
echo "   1. 完全退出 Xcode（Cmd+Q）"
echo "   2. 重新打开 Xcode"
echo "   3. 等待 Swift Package 解析完成（菜单栏 File → Packages → Resolve Package Versions）"
echo "   4. 在 scheme 选择器中选择 BabyBookApp → iOS Simulator"
echo "   5. 按 Cmd+B 编译一次项目"
echo "   6. 回到 BookDetailView.swift，按 Cmd+Option+Enter 打开预览"
echo ""
echo "⚠️  如果仍然报错，尝试："
echo "   - 点击预览面板的 '刷新' 按钮（或按 Cmd+Option+P）"
echo "   - 在预览代码前添加 @MainActor:"
echo ""
echo "   #Preview @MainActor"
echo "   struct BookDetailView_Previews: PreviewProvider {"
echo "       static var previews: some View {"
echo "           NavigationStack {"
echo "               BookDetailView(book: MockService.shared.mockBooks[0])"
echo "           }"
echo "       }"
echo "   }"
