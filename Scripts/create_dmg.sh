#!/bin/bash

# PasteMine DMG 创建脚本
# 用于将编译后的 .app 打包成 DMG 分发文件

set -e

APP_NAME="PasteMine"
DMG_NAME="${APP_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "🔧 ${APP_NAME} DMG 创建工具"
echo "================================"
echo ""

# 查找 .app 文件
# 优先级: 1. 命令行参数 2. Xcode DerivedData 3. 当前目录

if [ -n "$1" ]; then
    APP_PATH="$1"
elif [ -d "${HOME}/Library/Developer/Xcode/DerivedData" ]; then
    # 在 DerivedData 中查找最新的 PasteMine.app
    APP_PATH=$(find "${HOME}/Library/Developer/Xcode/DerivedData" -name "${APP_NAME}.app" -type d 2>/dev/null | head -1)
fi

# 如果还没找到，尝试当前目录
if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    if [ -d "./${APP_NAME}.app" ]; then
        APP_PATH="./${APP_NAME}.app"
    elif [ -d "../${APP_NAME}.app" ]; then
        APP_PATH="../${APP_NAME}.app"
    fi
fi

# 验证 .app 是否存在
if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ 错误: 找不到 ${APP_NAME}.app${NC}"
    echo ""
    echo "请先在 Xcode 中编译项目 (Product > Build)，或指定 .app 路径:"
    echo "  ./create_dmg.sh /path/to/${APP_NAME}.app"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ 找到应用:${NC} ${APP_PATH}"

# 输出目录（默认桌面）
OUTPUT_DIR="${2:-${HOME}/Desktop}"
DMG_PATH="${OUTPUT_DIR}/${DMG_NAME}"

# 临时目录
TMP_DIR=$(mktemp -d)
DMG_TMP="${TMP_DIR}/dmg_contents"

echo "📁 输出路径: ${DMG_PATH}"
echo ""

# 创建临时 DMG 内容目录
echo "1️⃣  准备 DMG 内容..."
mkdir -p "${DMG_TMP}"

# 复制 .app 到临时目录
cp -R "${APP_PATH}" "${DMG_TMP}/"

# 创建 Applications 快捷方式
ln -s /Applications "${DMG_TMP}/Applications"

# 删除旧的 DMG（如果存在）
if [ -f "${DMG_PATH}" ]; then
    echo "2️⃣  删除旧的 DMG..."
    rm -f "${DMG_PATH}"
fi

# 创建 DMG
echo "3️⃣  创建 DMG 文件..."
hdiutil create \
    -volname "${VOLUME_NAME}" \
    -srcfolder "${DMG_TMP}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}" \
    > /dev/null

# 清理临时目录
echo "4️⃣  清理临时文件..."
rm -rf "${TMP_DIR}"

# 验证 DMG
if [ -f "${DMG_PATH}" ]; then
    DMG_SIZE=$(du -h "${DMG_PATH}" | cut -f1)
    echo ""
    echo -e "${GREEN}✅ DMG 创建成功!${NC}"
    echo ""
    echo "📦 文件: ${DMG_PATH}"
    echo "📏 大小: ${DMG_SIZE}"
    echo ""
    echo "💡 提示:"
    echo "   - 双击 DMG 文件打开"
    echo "   - 将 ${APP_NAME}.app 拖到 Applications 文件夹完成安装"
    echo ""

    # 可选：打开 DMG 所在目录
    # open "${OUTPUT_DIR}"
else
    echo -e "${RED}❌ DMG 创建失败${NC}"
    exit 1
fi
