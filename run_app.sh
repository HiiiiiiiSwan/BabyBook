#!/bin/bash
# 在 iPhone 17 Pro Max 模拟器上运行 BabyBook App

PROJECT_PATH="/Users/wang/Documents/Vibe coding/【新】宝贝绘本/BabyBook/BabyBook.xcodeproj"
SCHEME="BabyBook"

# 查找 iPhone 17 Pro Max 的 device ID
DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone 17 Pro Max" | head -1 | sed -E 's/.*\(([A-F0-9\-]+)\).*/\1/')

if [ -z "$DEVICE_ID" ]; then
    echo "错误：未找到 iPhone 17 Pro Max 模拟器"
    echo "请先运行：bash open_simulator.sh"
    exit 1
fi

echo "目标设备: iPhone 17 Pro Max ($DEVICE_ID)"
echo "正在打开 Xcode 项目..."

open "$PROJECT_PATH"

echo ""
echo "请手动在 Xcode 中："
echo "1. 确认顶部设备选择框为 iPhone 17 Pro Max"
echo "2. 按 Cmd + R 运行"
echo ""
echo "或者运行以下命令行构建（较慢）："
echo "xcodebuild -project \"$PROJECT_PATH\" -scheme $SCHEME -destination 'platform=iOS Simulator,id=$DEVICE_ID' build"
