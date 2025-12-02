#!/bin/bash

# PasteMine DMG 打包脚本 - 新版本

set -e

APP_NAME="PasteMine"
VERSION="1.1"
APP_PATH="PasteMine/build/Release/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
TEMP_DMG="temp_${DMG_NAME}"
VOLUME_NAME="${APP_NAME}"
DMG_DIR="dmg_temp"

echo "🚀 开始创建 DMG 安装包..."

# 检查 app 文件是否存在
if [ ! -d "${APP_PATH}" ]; then
    echo "❌ 错误: 找不到 ${APP_PATH}"
    echo "请先运行构建命令"
    exit 1
fi

# 清理旧文件
rm -rf "${DMG_DIR}"
rm -f "${DMG_NAME}"
rm -f "${TEMP_DMG}"

# 创建临时目录
mkdir -p "${DMG_DIR}"

# 复制 app 到临时目录
echo "📦 复制应用..."
cp -R "${APP_PATH}" "${DMG_DIR}/"

# 创建 Applications 快捷方式
echo "🔗 创建 Applications 快捷方式..."
ln -s /Applications "${DMG_DIR}/Applications"

# 创建临时 DMG
echo "💿 创建临时 DMG..."
hdiutil create -volname "${VOLUME_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov -format UDRW \
    "${TEMP_DMG}"

# 挂载临时 DMG
echo "📂 挂载 DMG..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "${TEMP_DMG}" | \
    egrep '^/dev/' | sed 1q | awk '{print $1}')

sleep 2

# 设置 Finder 视图选项
echo "🎨 设置 Finder 视图..."
echo '
   tell application "Finder"
     tell disk "'${VOLUME_NAME}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 900, 450}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 100
           set position of item "'${APP_NAME}'.app" of container window to {120, 120}
           set position of item "Applications" of container window to {380, 120}
           update without registering applications
           delay 2
           close
     end tell
   end tell
' | osascript

sync

# 卸载临时 DMG
echo "📤 卸载临时 DMG..."
hdiutil detach "${DEVICE}"

# 转换为压缩的只读 DMG
echo "🗜️  压缩 DMG..."
hdiutil convert "${TEMP_DMG}" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${DMG_NAME}"

# 清理临时文件
echo "🧹 清理临时文件..."
rm -f "${TEMP_DMG}"
rm -rf "${DMG_DIR}"

# 显示结果
DMG_SIZE=$(du -h "${DMG_NAME}" | cut -f1)
echo ""
echo "✅ DMG 创建成功！"
echo "📦 文件: ${DMG_NAME}"
echo "📏 大小: ${DMG_SIZE}"
echo "📍 路径: $(pwd)/${DMG_NAME}"
echo ""
echo "安装说明："
echo "1. 双击打开 ${DMG_NAME}"
echo "2. 将 ${APP_NAME} 拖拽到 Applications 文件夹"
echo "3. 在 Launchpad 或 Applications 文件夹中启动应用"
echo ""
echo "本版本新增功能："
echo "- 隐私设置：忽略应用列表"
echo "- 隐私设置：忽略复制类型列表"
echo "- 隐私设置：退出时清空剪贴板开关"
