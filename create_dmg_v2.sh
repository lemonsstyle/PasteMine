#!/bin/bash

echo "📦 创建 PasteMine 安装包（DMG）- 简化版"
echo "================================"
echo ""

# 配置
APP_NAME="PasteMine"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
VOLUME_NAME="PasteMine Installer"

# 路径
SOURCE_APP="/Users/lemonstyle/Library/Developer/Xcode/DerivedData/PasteMine-bjkfxylqhmegxwgnfjobhpcofinj/Build/Products/Release/PasteMine.app"
DMG_DIR="/Users/lemonstyle/Documents/xcode_pj/pas/dmg_contents"
FINAL_DMG="/Users/lemonstyle/Documents/xcode_pj/pas/${DMG_NAME}"

# 清理
echo "🧹 清理旧文件..."
rm -rf "$DMG_DIR"
rm -f "$FINAL_DMG"
mkdir -p "$DMG_DIR"

# 检查源应用
if [ ! -d "$SOURCE_APP" ]; then
    echo "❌ 错误：找不到 PasteMine.app"
    exit 1
fi

# 复制文件到 DMG 内容目录
echo "📋 准备 DMG 内容..."
cp -R "$SOURCE_APP" "$DMG_DIR/"
cp "uninstall.sh" "$DMG_DIR/卸载 PasteMine.command"
chmod +x "$DMG_DIR/卸载 PasteMine.command"
cp "README_INSTALL.md" "$DMG_DIR/安装说明.md"

# 创建 Applications 符号链接
echo "🔗 创建 Applications 链接..."
ln -s /Applications "$DMG_DIR/Applications"

# 直接从文件夹创建 DMG
echo "💿 创建 DMG 文件..."
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$FINAL_DMG"

# 清理
echo "🧹 清理临时文件..."
rm -rf "$DMG_DIR"

if [ -f "$FINAL_DMG" ]; then
    echo ""
    echo "✅ DMG 创建成功！"
    echo ""
    echo "📍 文件位置："
    echo "   $FINAL_DMG"
    echo ""
    echo "📊 文件大小："
    ls -lh "$FINAL_DMG" | awk '{print "   " $5}'
    echo ""
    echo "🎯 使用方法："
    echo "   1. 双击 DMG 文件打开"
    echo "   2. 将 PasteMine 拖到 Applications 文件夹"
    echo "   3. 查看'安装说明.md'了解详细步骤"
    echo ""
    echo "================================"
    echo ""
    
    read -p "是否现在打开 DMG 文件查看？(y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$FINAL_DMG"
    fi
else
    echo "❌ DMG 创建失败"
    exit 1
fi

