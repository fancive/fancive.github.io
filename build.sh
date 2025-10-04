#!/bin/bash
# Hugo 博客构建和发布脚本

set -e  # 遇到错误立即退出

echo "🚀 开始构建 Hugo 站点..."

# 构建站点
hugo

echo "✅ 构建完成！"
echo ""
echo "📝 生成的文件在 docs/ 目录"
echo ""

# 检查 docs 目录是否有变更
if [[ -n $(git status -s docs/) ]]; then
    echo "📦 检测到 docs/ 目录有变更"

    # 询问是否提交
    read -p "是否提交并推送到远程仓库? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 获取提交信息
        read -p "请输入提交信息 (默认: Update site): " commit_msg
        commit_msg=${commit_msg:-"Update site"}

        # 提交并推送
        git add docs/
        git commit -m "$commit_msg"
        git push

        echo "✅ 已推送到远程仓库"
        echo "🌐 站点将在几分钟后更新: https://fancive.github.io/"
    else
        echo "⏭️  跳过提交"
    fi
else
    echo "ℹ️  docs/ 目录没有变更"
fi
