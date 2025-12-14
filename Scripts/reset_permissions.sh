#!/bin/bash

# PasteMine 权限重置脚本
# 用于清理测试期间积累的权限缓存，解决频繁安装卸载导致的权限问题

set -e

APP_NAME="PasteMine"
BUNDLE_ID="com.lemonstyle.PasteMine44"

echo "🧹 开始清理 ${APP_NAME} 的权限缓存..."
echo ""

# 1. 关闭应用
echo "1️⃣  关闭 ${APP_NAME}（如果正在运行）..."
killall "${APP_NAME}" 2>/dev/null || echo "   应用未运行"
echo ""

# 2. 重置辅助功能权限
echo "2️⃣  重置辅助功能权限..."
tccutil reset Accessibility "${BUNDLE_ID}" 2>/dev/null || echo "   无需重置（首次安装或已清理）"
echo ""

# 3. 重置 AppleEvents 权限（自动粘贴需要）
echo "3️⃣  重置 AppleEvents 权限..."
tccutil reset AppleEvents "${BUNDLE_ID}" 2>/dev/null || echo "   无需重置（首次安装或已清理）"
echo ""

# 4. 清理通知中心缓存
echo "4️⃣  清理通知中心缓存..."
killall usernoted 2>/dev/null || echo "   通知守护进程未运行"
killall NotificationCenter 2>/dev/null || echo "   通知中心未运行"
rm -rf ~/Library/Caches/com.apple.notificationcenter 2>/dev/null || echo "   缓存已清理或不存在"
echo ""

# 5. 清理通知数据库中的旧记录（需要关闭系统保护，不推荐）
echo "5️⃣  清理通知数据库记录..."
DB_PATH="${HOME}/Library/Application Support/NotificationCenter"
if [ -d "${DB_PATH}" ]; then
    echo "   找到通知数据库目录"
    # 注意：直接删除数据库可能会影响其他应用的通知设置
    # 这里只是提示位置，不实际删除
    echo "   数据库路径: ${DB_PATH}"
    echo "   ⚠️  如需彻底清理，可以手动删除该目录（会清除所有应用的通知设置）"
else
    echo "   通知数据库目录不存在"
fi
echo ""

# 6. 删除应用的用户偏好设置
echo "6️⃣  清理应用偏好设置..."
defaults delete "${BUNDLE_ID}" 2>/dev/null || echo "   无偏好设置需要清理"
rm -f ~/Library/Preferences/"${BUNDLE_ID}".plist 2>/dev/null || echo "   偏好设置文件不存在"
echo ""

# 7. 清理 Launch Services 数据库
echo "7️⃣  重建 Launch Services 数据库..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
echo "   Launch Services 数据库已重建"
echo ""

# 8. 重启系统服务
echo "8️⃣  重启相关系统服务..."
# 等待通知中心自动重启
sleep 2
echo "   通知中心已重启"
echo ""

echo "✅ 权限清理完成！"
echo ""
echo "📝 后续步骤："
echo "   1. 重新安装 ${APP_NAME}"
echo "   2. 首次启动时应该会看到系统权限请求弹窗"
echo "   3. 如果仍然无法弹出通知权限请求，请手动操作："
echo "      • 打开 系统设置 > 通知"
echo "      • 在左侧列表中找到并删除旧的 ${APP_NAME} 条目（如果存在）"
echo "      • 重新启动应用"
echo ""
echo "⚠️  注意事项："
echo "   - 辅助功能权限已重置，需要重新授权"
echo "   - 通知权限可能需要重启系统才能完全清除（如果上述方法无效）"
echo "   - 应用的所有偏好设置已清除，将恢复到初始状态"
echo ""
