#!/bin/bash

echo "🗑️  PasteMine 卸载程序"
echo "================================"
echo ""

# 应用路径
APP_PATH="/Applications/PasteMine.app"

# 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "ℹ️  PasteMine 未安装或已被删除"
    exit 0
fi

echo "⚠️  警告：这将完全删除 PasteMine"
echo ""
read -p "确定要卸载吗？(y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 已取消卸载"
    exit 0
fi

echo ""
echo "🔍 正在检查运行中的进程..."

# 强制退出正在运行的应用
if pgrep -x "PasteMine" > /dev/null; then
    echo "⏹️  正在关闭 PasteMine..."
    killall PasteMine 2>/dev/null
    sleep 1
fi

echo "🗑️  正在删除应用..."
rm -rf "$APP_PATH"

if [ $? -eq 0 ]; then
    echo "✅ PasteMine 已成功卸载"
    echo ""
    echo "📝 注意："
    echo "   - 应用数据已清除"
    echo "   - 系统权限设置不会自动移除"
    echo "   - 如需移除权限，请手动前往："
    echo "     系统偏好设置 → 安全性与隐私 → 隐私"
    echo ""
else
    echo "❌ 卸载失败，请尝试手动删除"
    echo "应用位置: $APP_PATH"
fi

echo "================================"

