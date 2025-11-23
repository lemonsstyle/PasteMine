#!/bin/bash

echo "🎁 PasteMine 安装程序"
echo "================================"
echo ""

# 源文件路径
SOURCE_APP="/Users/lemonstyle/Library/Developer/Xcode/DerivedData/PasteMine-bjkfxylqhmegxwgnfjobhpcofinj/Build/Products/Release/PasteMine.app"

# 目标路径
TARGET_APP="/Applications/PasteMine.app"

# 检查源文件是否存在
if [ ! -d "$SOURCE_APP" ]; then
    echo "❌ 错误: 找不到构建的应用"
    echo "请先运行构建命令"
    exit 1
fi

echo "📦 准备安装 PasteMine..."
echo ""

# 如果已经存在旧版本，先删除
if [ -d "$TARGET_APP" ]; then
    echo "🗑️  发现旧版本，正在删除..."
    rm -rf "$TARGET_APP"
fi

# 复制应用到 /Applications
echo "📥 正在安装到 /Applications..."
cp -R "$SOURCE_APP" "$TARGET_APP"

if [ $? -eq 0 ]; then
    echo "✅ 安装成功！"
    echo ""
    echo "📍 应用位置: /Applications/PasteMine.app"
    echo ""
    echo "🎯 下一步："
    echo "   1. 打开启动台或访达"
    echo "   2. 找到 PasteMine 并打开"
    echo "   3. 系统会提示授予权限"
    echo ""
    echo "🔐 需要授予的权限："
    echo "   ✓ 辅助功能（自动粘贴）"
    echo "   ✓ 输入监控（全局快捷键）"
    echo ""
    echo "💡 提示："
    echo "   - 托盘图标在屏幕右上角"
    echo "   - 按 ⌘⇧V 唤起窗口"
    echo "   - 首次打开可能需要右键 → 打开"
    echo ""
    echo "================================"
    echo ""
    
    read -p "是否现在打开 PasteMine？(y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🚀 正在启动 PasteMine..."
        open "/Applications/PasteMine.app"
    fi
else
    echo "❌ 安装失败"
    exit 1
fi

