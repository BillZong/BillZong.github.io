#!/usr/bin/env bash
# build-books.sh — 构建小书（VitePress）并拼进博客的 public/books/
#
# 用法:
#   ./bin/build-books.sh              # 构建 + 拼进 public/books/
#
# 依赖:
#   - books 仓库已 clone 到 BOOK_REPO 指定的路径
#   - books 仓库已 npm install
#
# 产物结构:
#   public/books/index.html          小书站点首页
#   public/books/algorithm/*.html    《算法体系》21 章
#   public/books/assets/*            静态资源
#
# 为什么用拼进主站而不是独立仓库:
#   billzong.github.io 是【用户站点】, 同一账号下只有这个仓库能占用根域名,
#   其他仓库的 Pages 只能挂在 /仓库名/ 子路径。想让 URL 是 /books/,
#   只能由主站仓库自己提供这个目录。
#
# 注意: public/books/ 每次都是全量重建, 目标目录会被先清空。
#   VitePress 的资源文件名带内容哈希, 内容一改文件名就变,
#   旧文件留着就是历史内容继续挂在公网上。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# 小书仓库位置：默认与博客同级
BOOK_REPO="${BOOK_REPO:-$REPO_ROOT/../books}"
BOOK_DOCS="$BOOK_REPO/docs"
BOOK_DIST="$BOOK_DOCS/.vitepress/dist"
BOOK_BASE="/books/"

echo "==> 1/5 检查小书仓库"
if [[ ! -d "$BOOK_REPO" ]]; then
  echo "❌ 找不到小书仓库: $BOOK_REPO"
  echo "   请先 clone，或用 BOOK_REPO 环境变量指定路径"
  exit 1
fi
if [[ ! -d "$BOOK_REPO/node_modules" ]]; then
  echo "==> 安装小书依赖"
  (cd "$BOOK_REPO" && npm install)
fi
echo "   小书仓库: $BOOK_REPO"

echo "==> 2/5 同步 iCloud 原稿"
# 同步脚本会顺带修正指向汇总稿的链接与跨站绝对地址。
# 原稿缺失时不该中断发布（内容可能已手工改过），故用 || true 兜底。
(cd "$BOOK_REPO" && npm run sync) || echo "   ⚠️  同步失败，跳过（使用仓库中已有内容）"

echo "==> 3/5 隔离检查"
# 各本书不能互相污染（重名章节、相对路径串书、目录漏登记）。
# 不通过就停在这里, 不产出任何会被发布的东西。
(cd "$BOOK_REPO" && node scripts/check-isolation.mjs)

echo "==> 4/5 构建 VitePress"
(cd "$BOOK_REPO" && npx vitepress build "$BOOK_DOCS" --base "$BOOK_BASE")

if [[ ! -f "$BOOK_DIST/index.html" ]]; then
  echo "❌ 构建产物异常: 缺少 $BOOK_DIST/index.html"
  exit 1
fi

echo "==> 5/5 拼进 public/books/"
TARGET="$REPO_ROOT/public/books"
# 每次构建都是全新产物, 资源文件名带内容哈希, 旧文件不会再被引用。
# 必须先清空目标目录, 否则历史 chunk 会一直堆积并被发布出去
# (既浪费空间, 也等于把改过之前的历史内容继续挂在公网上)。
rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -a "$BOOK_DIST/." "$TARGET/"

# 泄漏门禁: 产物里不允许出现本机路径、小书仓库地址、iCloud 路径。
# 源码仓库是私有的, 这些东西一旦进产物就等于公开了。
LEAKS="$(grep -rIlE "/Users/[A-Za-z0-9._-]+|BillZong/books|com~apple~CloudDocs" "$TARGET" 2>/dev/null | head -5 || true)"
if [[ -n "$LEAKS" ]]; then
  echo "❌ 产物里出现本机路径或仓库地址，已中止发布："
  echo "$LEAKS" | sed 's/^/     /'
  exit 1
fi

COUNT=$(find "$TARGET" -name "*.html" | wc -l | tr -d ' ')
SIZE=$(du -sh "$TARGET" | cut -f1)
echo "   ✅ public/books/ 就绪：$COUNT 个 HTML，$SIZE"

# 提示：hexo generate 会重建 public/，所以必须在 hexo g 之后跑本脚本。
# hexo-publish.sh 已按此顺序编排。
