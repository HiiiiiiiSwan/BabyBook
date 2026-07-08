#!/bin/bash
# BabyBook 模拟器截图辅助脚本
# 用法：bash open_simulator.sh

# 自动选择可用的最大尺寸 iPhone 模拟器，优先 iPhone 17 Pro Max / 16 Pro Max / 15 Pro Max
for MODEL in "iPhone 17 Pro Max" "iPhone 16 Pro Max" "iPhone 15 Pro Max" "iPhone 14 Pro Max"; do
    DEVICE_ID=$(xcrun simctl list devices available | grep "$MODEL" | head -1 | sed -E 's/.*\(([A-F0-9\-]+)\).*/\1/')
    if [ -n "$DEVICE_ID" ]; then
        echo "找到 $MODEL，Device ID: $DEVICE_ID"
        break
    fi
done

if [ -z "$DEVICE_ID" ]; then
    echo "未找到大尺寸 iPhone 模拟器，正在创建 iPhone 17 Pro Max..."
    RUNTIME=$(xcrun simctl list runtimes | grep "iOS" | tail -1 | sed -E 's/.*\(([A-F0-9\-]+)\).*/\1/')
    if [ -z "$RUNTIME" ]; then
        echo "错误：未找到任何 iOS runtime"
        exit 1
    fi
    xcrun simctl create "iPhone 17 Pro Max" "iPhone 17 Pro Max" "$RUNTIME"
    DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone 17 Pro Max" | head -1 | sed -E 's/.*\(([A-F0-9\-]+)\).*/\1/')
fi

echo "正在启动模拟器: $DEVICE_ID"
open -a Simulator --args -CurrentDeviceUDID "$DEVICE_ID"

echo "模拟器已启动，请在 Xcode 中选择对应机型运行 App，然后按 Cmd + S 截图"
