#!/bin/bash
# 本地预览 / 构建检查脚本。
# 部署已交给 GitHub Actions（push 到 main 自动构建发布），不再手动 commit docs/。

set -e

case "${1:-serve}" in
  serve)
    echo "🚀 本地预览（含草稿），打开 http://localhost:1313"
    hugo server -D --navigateToChanged
    ;;
  build)
    echo "🔨 生产构建到 public/（仅本地检查，产物不入库）"
    hugo --gc --minify
    echo "✅ 构建完成，产物在 public/。push 到 main 后由 GitHub Actions 自动部署。"
    ;;
  *)
    echo "用法: ./build.sh [serve|build]"
    echo "  serve  本地预览（默认）"
    echo "  build  生产构建检查"
    exit 1
    ;;
esac
