#!/usr/bin/env bash
# hexo-publish.sh — One-shot publish cycle for BillZong.github.io dual-branch (dev=source, master=deploy) blog.
#
# Usage:
#   ./scripts/hexo-publish.sh                   # full cycle: hexo g + commit master + commit dev
#   ./scripts/hexo-publish.sh --skip-dev        # only commit master (deploy)
#   ./scripts/hexo-publish.sh --skip-master     # only commit dev (source)
#   ./scripts/hexo-publish.sh --push            # also push both branches to origin
#   ./scripts/hexo-publish.sh -m "msg"          # override commit message (otherwise auto-generated)
#   ./scripts/hexo-publish.sh --dry-run         # show what would happen, no commit/push
#
# Workflow:
#   dev (source):  hexo clean + hexo g
#   master (deploy): cp -a public/. . + git add -A + reset ignore + commit
#   dev (source): git add source/_posts/ source/images/ + commit
#
# Must be run from BillZong.github.io repository root (or use --repo).

set -euo pipefail

# ---------- 解析参数 ----------
SKIP_DEV=0
SKIP_MASTER=0
PUSH=0
DRY_RUN=0
MSG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-dev)     SKIP_DEV=1 ;;
    --skip-master)  SKIP_MASTER=1 ;;
    --push)         PUSH=1 ;;
    --dry-run)      DRY_RUN=1 ;;
    -m)             MSG="$2"; shift ;;
    -h|--help)
      sed -n '2,15p' "$0"
      exit 0
      ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
  shift
done

if [[ $SKIP_MASTER -eq 1 && $SKIP_DEV -eq 1 ]]; then
  echo "❌ --skip-master 和 --skip-dev 不能同时使用"; exit 1
fi

# ---------- 切到仓库根 ----------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"
echo "📁 仓库根: $REPO_ROOT"

# ---------- 前置检查 ----------
if [[ ! -d .git ]]; then
  echo "❌ 当前目录不是 git 仓库"; exit 1
fi
if [[ ! -f package.json ]]; then
  echo "❌ package.json 不存在"; exit 1
fi
if [[ ! -d node_modules ]]; then
  echo "❌ node_modules 不存在，先跑 yarn install 或 npm install"; exit 1
fi

# ---------- 切到 dev 分支 ----------
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "dev" ]]; then
  echo "==> 当前在 $CURRENT_BRANCH，切到 dev"
  git checkout dev
fi

# ---------- 1. dev 上 hexo clean + generate ----------
echo ""
echo "==> 1/4 hexo clean + generate (dev 分支)"
if [[ $DRY_RUN -eq 0 ]]; then
  npx hexo clean
  npx hexo generate
fi

# ---------- 2. master: 平铺 public 到根并 commit ----------
if [[ $SKIP_MASTER -eq 0 ]]; then
  echo ""
  echo "==> 2/4 master: 平铺 public/. 到根并 commit"
  if [[ $DRY_RUN -eq 0 ]]; then
    git checkout master
    cp -a public/. .
    # 清理 dev checkout master 时可能残留的源文件
    # (master 是部署分支，不应包含 _config.yml / package.json / yarn.lock 等)
    mavis-trash _config.yml _config.fluid.yml _config.landscape.yml _admin-config.yml \
                package.json yarn.lock package-lock.json 2>/dev/null || true
    find . -maxdepth 1 \( -name "*.bak" -o -name "*.original" \) -exec mavis-trash {} + 2>/dev/null || true
    git add -A
    # 忽略掉不该 commit 的
    git reset HEAD public/ node_modules/ package-lock.json db.json source/ \
                   yarn.lock.bak yarn.lock.original 2>/dev/null || true
    if git diff --cached --quiet; then
      echo "    (没有需要 commit 的改动)"
    else
      if [[ -z "$MSG" ]]; then
        TIMESTAMP="$(date '+%Y-%m-%d %H:%M')"
        MSG="site: hexo g rebuild at $TIMESTAMP"
      fi
      git -c user.email=billzong@163.com -c user.name=BillZong commit -m "$MSG"
      if [[ $PUSH -eq 1 ]]; then
        echo "    push master..."
        git push origin master
      fi
    fi
  fi
else
  echo ""
  echo "==> 2/4 (跳过 master)"
fi

# ---------- 3. dev: commit 新的 source/_posts/ 和 source/images/ ----------
if [[ $SKIP_DEV -eq 0 ]]; then
  echo ""
  echo "==> 3/4 dev: commit 新 source/_posts/ + source/images/"
  if [[ $DRY_RUN -eq 0 ]]; then
    git checkout dev
    git add source/_posts/ source/images/
    if git diff --cached --quiet; then
      echo "    (没有新的 source 文件需要 commit)"
    else
      if [[ -z "$MSG" ]]; then
        TIMESTAMP="$(date '+%Y-%m-%d %H:%M')"
        MSG="source: add posts/images at $TIMESTAMP"
      fi
      git -c user.email=billzong@163.com -c user.name=BillZong commit -m "$MSG"
      if [[ $PUSH -eq 1 ]]; then
        echo "    push dev..."
        git push origin dev
      fi
    fi
  fi
else
  echo ""
  echo "==> 3/4 (跳过 dev)"
fi

# ---------- 总结 ----------
echo ""
echo "✅ 完成"
if [[ $PUSH -eq 0 ]]; then
  echo "   还没 push。要推送跑："
  echo "     git push origin master"
  echo "     git push origin dev"
fi
echo "   当前分支状态："
git branch -vv
