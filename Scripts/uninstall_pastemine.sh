#!/bin/bash

# PasteMine 完整卸载清理脚本
# 用于彻底清理应用及其所有权限、数据和缓存

set -e

APP_NAME="PasteMine"
# 支持多个 Bundle ID（历史版本）
BUNDLE_IDS=(
    "com.lemonstyle.PasteMine44"
    "com.lemonstyle.PasteMine43"
    "com.lemonstyle.PasteMine"
    "com.example.PasteMine"
)

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         PasteMine 完整卸载清理脚本                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  警告：此脚本将："
echo "   • 删除应用程序"
echo "   • 清除所有应用数据和缓存"
echo "   • 重置所有系统权限"
echo "   • 删除所有偏好设置"
echo ""
read -p "确认继续？(y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 已取消"
    exit 1
fi
echo ""

# ==============================================================================
# 步骤 1: 关闭应用
# ==============================================================================
echo "1️⃣  关闭 ${APP_NAME}（如果正在运行）..."
if killall "${APP_NAME}" 2>/dev/null; then
    echo "   ✓ 应用已关闭"
    sleep 2
else
    echo "   ✓ 应用未运行"
fi
echo ""

# ==============================================================================
# 步骤 2: 删除应用程序
# ==============================================================================
echo "2️⃣  删除应用程序..."
APP_PATHS=(
    "/Applications/${APP_NAME}.app"
    "${HOME}/Applications/${APP_NAME}.app"
    "${HOME}/Desktop/${APP_NAME}.app"
    "${HOME}/Downloads/${APP_NAME}.app"
)

FOUND=false
for APP_PATH in "${APP_PATHS[@]}"; do
    if [ -d "${APP_PATH}" ]; then
        echo "   找到应用: ${APP_PATH}"
        rm -rf "${APP_PATH}"
        echo "   ✓ 已删除: ${APP_PATH}"
        FOUND=true
    fi
done

if [ "$FOUND" = false ]; then
    echo "   ℹ️  未找到应用程序文件"
fi
echo ""

# ==============================================================================
# 步骤 3: 清理应用数据
# ==============================================================================
echo "3️⃣  清理应用数据..."

# Application Support
APP_SUPPORT="${HOME}/Library/Application Support/${APP_NAME}"
if [ -d "${APP_SUPPORT}" ]; then
    echo "   清理 Application Support..."
    rm -rf "${APP_SUPPORT}"
    echo "   ✓ 已删除应用数据"
else
    echo "   ℹ️  无 Application Support 数据"
fi

# Caches
for BUNDLE_ID in "${BUNDLE_IDS[@]}"; do
    CACHE_PATH="${HOME}/Library/Caches/${BUNDLE_ID}"
    if [ -d "${CACHE_PATH}" ]; then
        echo "   清理缓存: ${BUNDLE_ID}"
        rm -rf "${CACHE_PATH}"
        echo "   ✓ 已删除"
    fi
done

# Containers
CONTAINER_PATH="${HOME}/Library/Containers/${BUNDLE_ID}"
if [ -d "${CONTAINER_PATH}" ]; then
    echo "   清理 Container 数据..."
    rm -rf "${CONTAINER_PATH}"
    echo "   ✓ 已删除 Container"
fi

# Group Containers
GROUP_CONTAINER=$(find "${HOME}/Library/Group Containers" -name "*${APP_NAME}*" 2>/dev/null)
if [ -n "${GROUP_CONTAINER}" ]; then
    echo "   清理 Group Container..."
    rm -rf "${GROUP_CONTAINER}"
    echo "   ✓ 已删除 Group Container"
fi

echo ""

# ==============================================================================
# 步骤 4: 清理偏好设置
# ==============================================================================
echo "4️⃣  清理偏好设置..."
for BUNDLE_ID in "${BUNDLE_IDS[@]}"; do
    # 使用 defaults 命令删除
    if defaults delete "${BUNDLE_ID}" 2>/dev/null; then
        echo "   ✓ 已清理偏好: ${BUNDLE_ID}"
    fi

    # 删除 plist 文件
    PLIST_PATH="${HOME}/Library/Preferences/${BUNDLE_ID}.plist"
    if [ -f "${PLIST_PATH}" ]; then
        rm -f "${PLIST_PATH}"
        echo "   ✓ 已删除 plist: ${BUNDLE_ID}"
    fi
done
echo ""

# ==============================================================================
# 步骤 5: 重置系统权限
# ==============================================================================
echo "5️⃣  重置系统权限..."

# 权限类型列表
PERMISSION_TYPES=(
    "Accessibility"           # 辅助功能
    "AppleEvents"            # Apple Events（自动粘贴）
    "SystemPolicyAllFiles"   # 完全磁盘访问
    "ScreenCapture"          # 屏幕录制
    "ListenEvent"            # 输入监控
    "PostEvent"              # 发送事件
)

for BUNDLE_ID in "${BUNDLE_IDS[@]}"; do
    echo "   重置权限: ${BUNDLE_ID}"
    for PERMISSION in "${PERMISSION_TYPES[@]}"; do
        if tccutil reset "${PERMISSION}" "${BUNDLE_ID}" 2>/dev/null; then
            echo "   ✓ ${PERMISSION} 已重置"
        fi
    done
done
echo ""

# ==============================================================================
# 步骤 6: 清理通知权限
# ==============================================================================
echo "6️⃣  清理通知权限..."

# 关闭通知中心
echo "   关闭通知中心..."
killall usernoted 2>/dev/null || true
killall NotificationCenter 2>/dev/null || true

# 清理通知缓存
NOTIF_CACHE="${HOME}/Library/Caches/com.apple.notificationcenter"
if [ -d "${NOTIF_CACHE}" ]; then
    rm -rf "${NOTIF_CACHE}"
    echo "   ✓ 已清理通知缓存"
fi

# 清理通知数据库
NOTIF_DB="${HOME}/Library/Application Support/NotificationCenter"
if [ -d "${NOTIF_DB}" ]; then
    echo "   ⚠️  通知数据库位置: ${NOTIF_DB}"
    echo "   提示：如需彻底清理，可以删除该目录（会影响所有应用）"
fi

sleep 2
echo "   ✓ 通知中心已重启"
echo ""

# ==============================================================================
# 步骤 7: 清理启动项
# ==============================================================================
echo "7️⃣  清理启动项..."

# Launch Agents
LAUNCH_AGENT="${HOME}/Library/LaunchAgents/com.lemonstyle.PasteMine*.plist"
if ls ${LAUNCH_AGENT} 1> /dev/null 2>&1; then
    rm -f ${LAUNCH_AGENT}
    echo "   ✓ 已删除 Launch Agent"
else
    echo "   ℹ️  无启动项需要清理"
fi
echo ""

# ==============================================================================
# 步骤 8: 清理日志文件
# ==============================================================================
echo "8️⃣  清理日志文件..."

# 系统日志
LOG_PATHS=(
    "${HOME}/Library/Logs/${APP_NAME}"
    "${HOME}/Library/Logs/DiagnosticReports/*${APP_NAME}*"
)

for LOG_PATH in "${LOG_PATHS[@]}"; do
    if ls ${LOG_PATH} 1> /dev/null 2>&1; then
        rm -rf ${LOG_PATH}
        echo "   ✓ 已清理日志"
    fi
done
echo ""

# ==============================================================================
# 步骤 9: 重建 Launch Services 数据库
# ==============================================================================
echo "9️⃣  重建 Launch Services 数据库..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -kill -r -domain local -domain system -domain user
echo "   ✓ Launch Services 数据库已重建"
echo ""

# ==============================================================================
# 步骤 10: 清理 Spotlight 索引
# ==============================================================================
echo "🔟  清理 Spotlight 索引..."
mdimport -r /Applications 2>/dev/null || true
echo "   ✓ Spotlight 索引已更新"
echo ""

# ==============================================================================
# 完成
# ==============================================================================
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  ✅ 清理完成！                                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📝 已清理的内容："
echo "   ✓ 应用程序文件"
echo "   ✓ 应用数据和缓存"
echo "   ✓ 偏好设置"
echo "   ✓ 系统权限（辅助功能、Apple Events 等）"
echo "   ✓ 通知权限"
echo "   ✓ 启动项"
echo "   ✓ 日志文件"
echo "   ✓ Launch Services 注册"
echo ""
echo "🔄 后续步骤："
echo "   1. 【推荐】重启 Mac 以确保所有更改生效"
echo "   2. 或者注销并重新登录"
echo "   3. 重新安装 PasteMine"
echo "   4. 首次启动时会看到全新的权限请求弹窗"
echo ""
echo "💡 提示："
echo "   • 如果重启后仍有问题，请手动检查："
echo "     系统设置 > 隐私与安全性 > 辅助功能"
echo "     系统设置 > 通知"
echo "   • 确保旧的 PasteMine 条目已被移除"
echo ""
echo "⚠️  注意：系统可能需要几分钟来更新权限数据库"
echo ""
