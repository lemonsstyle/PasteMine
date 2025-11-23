#!/bin/bash

# PasteMine 权限设置辅助脚本

APP_PATH="/Users/lemonstyle/Library/Developer/Xcode/DerivedData/PasteMine-bjkfxylqhmegxwgnfjobhpcofinj/Index.noindex/Build/Products/Debug/PasteMine.app"

echo "🚀 PasteMine 权限设置向导"
echo "================================"
echo ""
echo "📍 您的 PasteMine.app 路径："
echo "$APP_PATH"
echo ""
echo "请按照以下步骤操作："
echo ""
echo "1️⃣  授予【辅助功能】权限（用于自动粘贴）："
echo "   - 我将为您打开系统设置"
echo "   - 点击左下角的 🔒 解锁"
echo "   - 点击 + 按钮"
echo "   - 按 ⌘⇧G 粘贴路径（已复制到剪贴板）"
echo "   - 选择 PasteMine.app 并打开"
echo "   - 勾选 PasteMine ✅"
echo ""

# 复制路径到剪贴板
echo -n "$APP_PATH" | pbcopy
echo "✅ 应用路径已复制到剪贴板"
echo ""

read -p "按 Enter 键打开【辅助功能】设置..." 

# 打开辅助功能设置
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo ""
echo "⏳ 请在系统设置中完成【辅助功能】权限设置..."
read -p "完成后按 Enter 继续..." 

echo ""
echo "2️⃣  授予【输入监控】权限（用于全局快捷键）："
echo "   - 在同一个设置页面"
echo "   - 点击左侧的【输入监控】"
echo "   - 重复相同的步骤添加 PasteMine.app"
echo ""

# 重新复制路径
echo -n "$APP_PATH" | pbcopy
echo "✅ 应用路径已再次复制到剪贴板"
echo ""

read -p "按 Enter 键打开【输入监控】设置..." 

# 打开输入监控设置
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"

echo ""
echo "⏳ 请在系统设置中完成【输入监控】权限设置..."
read -p "完成后按 Enter 继续..." 

echo ""
echo "✅ 权限设置完成！"
echo ""
echo "📝 下一步："
echo "   1. 返回 Xcode"
echo "   2. 停止应用 (⌘.)"
echo "   3. 重新运行 (⌘R)"
echo ""
echo "🎮 测试功能："
echo "   - 按 ⌘⇧V 应该能唤起窗口了"
echo "   - 点击历史记录应该能自动粘贴了"
echo ""
echo "================================"

