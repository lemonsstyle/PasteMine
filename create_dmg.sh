#!/bin/bash

echo "📦 创建 PasteMine 安装包（DMG）"
echo "================================"
echo ""

# 配置
APP_NAME="PasteMine"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
VOLUME_NAME="PasteMine Installer"

# 路径
SOURCE_APP="/Users/lemonstyle/Library/Developer/Xcode/DerivedData/PasteMine-bjkfxylqhmegxwgnfjobhpcofinj/Build/Products/Release/PasteMine.app"
BUILD_DIR="/Users/lemonstyle/Documents/xcode_pj/pas/build_dmg"
TEMP_DMG="${BUILD_DIR}/temp.dmg"
FINAL_DMG="/Users/lemonstyle/Documents/xcode_pj/pas/${DMG_NAME}"

# 清理旧文件
echo "🧹 清理旧文件..."
rm -rf "$BUILD_DIR"
rm -f "$FINAL_DMG"
mkdir -p "$BUILD_DIR"

# 检查源应用是否存在
if [ ! -d "$SOURCE_APP" ]; then
    echo "❌ 错误：找不到 PasteMine.app"
    echo "请先构建 Release 版本"
    exit 1
fi

# 复制应用到构建目录
echo "📋 复制应用文件..."
cp -R "$SOURCE_APP" "$BUILD_DIR/"

# 复制卸载脚本
echo "📋 添加卸载脚本..."
cp uninstall.sh "$BUILD_DIR/卸载 PasteMine.command"
chmod +x "$BUILD_DIR/卸载 PasteMine.command"

# 复制安装说明
echo "📋 添加安装说明..."
cp README_INSTALL.md "$BUILD_DIR/安装说明.md"

# 创建 Applications 快捷方式
echo "🔗 创建 Applications 链接..."
ln -s /Applications "$BUILD_DIR/Applications"

# 计算所需大小（MB）
SIZE=$(du -sm "$BUILD_DIR" | awk '{print $1}')
SIZE=$((SIZE + 50))  # 添加一些余量

echo "💾 创建临时磁盘镜像..."
hdiutil create -size ${SIZE}m -fs HFS+ -volname "$VOLUME_NAME" "$TEMP_DMG"

echo "📂 挂载磁盘镜像..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | egrep '^/dev/' | sed 1q | awk '{print $1}')
MOUNT_POINT="/Volumes/$VOLUME_NAME"

# 等待磁盘镜像完全挂载
sleep 2

echo "📦 复制文件到磁盘镜像..."
ditto "$BUILD_DIR/PasteMine.app" "$MOUNT_POINT/PasteMine.app"
ditto "$BUILD_DIR/卸载 PasteMine.command" "$MOUNT_POINT/卸载 PasteMine.command"
ditto "$BUILD_DIR/安装说明.md" "$MOUNT_POINT/安装说明.md"
ln -s /Applications "$MOUNT_POINT/Applications"

# 确保文件已写入
sync
sleep 1

# 设置窗口属性（如果有 .DS_Store 模板）
echo "🎨 设置窗口样式..."
# 这里可以添加自定义的 .DS_Store 文件来美化 DMG 窗口

# 等待文件系统同步
sync

echo "💿 卸载磁盘镜像..."
hdiutil detach "$DEVICE"

echo "🗜️  压缩并转换为最终 DMG..."
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"

# 清理临时文件
echo "🧹 清理临时文件..."
rm -rf "$BUILD_DIR"
rm -f "$TEMP_DMG"

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
    echo "🧪 测试卸载重装："
    echo "   1. 先双击'卸载 PasteMine.command'卸载"
    echo "   2. 再重新从 DMG 安装"
    echo "   3. 测试首次安装时的权限请求"
    echo ""
    echo "================================"
    echo ""
    
    read -p "是否现在打开 DMG 文件？(y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$FINAL_DMG"
    fi
else
    echo "❌ DMG 创建失败"
    exit 1
fi

