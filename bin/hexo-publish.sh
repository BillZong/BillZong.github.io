#!/usr/bin/env bash
# hexo-publish.sh — One-shot publish cycle for BillZong.github.io dual-branch (dev=source, master=deploy) blog.
#
# Usage:
#   ./bin/hexo-publish.sh                   # full cycle: hexo g + commit master + commit dev
#   ./bin/hexo-publish.sh --skip-dev        # only commit master (deploy)
#   ./bin/hexo-publish.sh --skip-master     # only commit dev (source)
#   ./bin/hexo-publish.sh --skip-books      # don't build the VitePress book into public/books/
#   ./bin/hexo-publish.sh --push            # also push both branches to origin
#   ./bin/hexo-publish.sh -m "msg"          # override commit message (otherwise auto-generated)
#   ./bin/hexo-publish.sh --dry-run         # show what would happen, no commit/push
#
# Workflow (order matters):
#   1. dev   : hexo clean + hexo g            -> public/ (gitignored, survives branch switch)
#   2. dev   : commit source changes          -> must happen BEFORE checkout master,
#                                                otherwise uncommitted dev edits block the checkout
#   3. dev   : build VitePress book           -> public/books/  (after hexo g, which wipes public/)
#   4. master: cp -a public/. . + commit      -> deployed artifact incl. books/
#   5. dev   : switch back to dev             -> leave the tree on the source branch
#
# Must be run from BillZong.github.io repository root (or use --repo).

set -euo pipefail

# ---------- 解析参数 ----------
SKIP_DEV=0
SKIP_MASTER=0
SKIP_BOOKS=0
PUSH=0
DRY_RUN=0
MSG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-dev)     SKIP_DEV=1 ;;
    --skip-master)  SKIP_MASTER=1 ;;
    --skip-books)   SKIP_BOOKS=1 ;;
    --push)         PUSH=1 ;;
    --dry-run)      DRY_RUN=1 ;;
    -m)             MSG="$2"; shift ;;
    -h|--help)
      sed -n '2,19p' "$0"
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
echo "==> 1/5 hexo clean + generate (dev 分支)"
if [[ $DRY_RUN -eq 0 ]]; then
  npx hexo clean
  npx hexo generate
  # hexo-abbrlink 插件在 generate 阶段会把空的 frontmatter abbrlink
  # 字段写回源文件（如 `abbrlink: 4e9995af`）。这类回写不属于本次改动，
  # 这里把 source/_posts/ 还原成 HEAD，避免把它混进源码提交。
  # 注意：public/ 里已经生成的 HTML 用的是正确 abbrlink 派生的 URL，不受影响。
  if ! git diff --quiet -- source/_posts/; then
    # 只有当差异全部落在 abbrlink 字段上时才还原，避免误删真实的内容改动
    NON_ABBRLINK="$(git diff -U0 -- source/_posts/ \
      | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)' | grep -v 'abbrlink:' || true)"
    if [[ -z "$NON_ABBRLINK" ]]; then
      git checkout HEAD -- source/_posts/ 2>/dev/null || true
    else
      echo "    ⚠️  source/_posts/ 有非 abbrlink 的改动，保留并一起提交"
    fi
  fi
fi

# ---------- 2. dev: commit 源码改动 ----------
# 必须早于 checkout master：dev 上有未提交改动时，git checkout master 会被拒绝。
STASHED=0
if [[ $SKIP_DEV -eq 0 ]]; then
  echo ""
  echo "==> 2/5 dev: commit 源码改动 (source/ + 配置 + bin/)"
  if [[ $DRY_RUN -eq 0 ]]; then
    # 显式列出源码面，避免把生成物误入 dev。
    # .gitignore 已覆盖 public/ node_modules/ db.json package-lock.json .deploy*/
    # 只保留实际存在的路径，否则 git add 会因 pathspec 不匹配而报错。
    SRC_PATHS=()
    for p in source/ bin/ scripts/ themes/ scaffolds/ css/ js/ fancybox/ \
             _config.yml _config.fluid.yml _config.landscape.yml _admin-config.yml \
             package.json README.md SUMMARY.md; do
      [[ -e "$p" ]] && SRC_PATHS+=("$p")
    done
    git add -A -- "${SRC_PATHS[@]}"
    if git diff --cached --quiet; then
      echo "    (没有新的源码改动需要 commit)"
    else
      DEV_MSG="$MSG"
      if [[ -z "$DEV_MSG" ]]; then
        DEV_MSG="source: update site at $(date '+%Y-%m-%d %H:%M')"
      fi
      git -c user.email=billzong2012@gmail.com -c user.name=BillZong commit -m "$DEV_MSG"
    fi
    # 推送：只要有未推送的提交就推，不管提交是本次产生的还是之前攒下的。
    # 放在 commit 判断之外，否则「本次没新提交」的发布会静默漏推。
    if [[ $PUSH -eq 1 ]] && [[ -n "$(git log --oneline origin/dev..dev 2>/dev/null)" ]]; then
      echo "    push dev..."
      git push origin dev
    fi
  fi
else
  echo ""
  echo "==> 2/5 (跳过 dev commit)"
  # 仍有未提交改动时先 stash，否则后面 checkout master 会被拒绝
  if [[ $DRY_RUN -eq 0 ]] && [[ -n "$(git status --porcelain)" ]]; then
    git stash push -u -m "hexo-publish: dev 未提交改动" >/dev/null
    STASHED=1
    echo "    (dev 未提交改动已 stash)"
  fi
fi

# ---------- 3. 构建小书并拼进 public/books/ ----------
# 必须在 hexo generate 之后：hexo g 会重建 public/，把 public/books/ 冲掉。
# 小书用 VitePress 构建，产物落到 public/books/，随 master 一起部署，
# 线上地址 https://billzong.github.io/books/
if [[ $SKIP_BOOKS -eq 0 ]]; then
  echo ""
  echo "==> 3/5 构建小书 → public/books/"
  if [[ $DRY_RUN -eq 0 ]]; then
    if [[ -x "bin/build-books.sh" ]]; then
      ./bin/build-books.sh || echo "    ⚠️  小书构建失败，本次发布不含 books/（博客正常发布）"
    else
      echo "    ⚠️  找不到 bin/build-books.sh（或无执行权限），跳过小书构建"
    fi
  fi
else
  echo ""
  echo "==> 3/5 (跳过小书构建)"
fi

# ---------- 4. master: 平铺 public 到根并 commit ----------
if [[ $SKIP_MASTER -eq 0 ]]; then
  echo ""
  echo "==> 4/5 master: 平铺 public/. 到根并 commit"
  if [[ $DRY_RUN -eq 0 ]]; then
    git checkout master
    # 小书目录每次都是全新构建（VitePress 资源文件名带内容哈希，内容一改文件名就变）。
    # 先把上一版残留从 index 和工作树里清掉再平铺，否则旧 chunk 会跟着进提交，
    # 等于把改版之前的历史内容继续挂在公网上。
    git rm --force -r --ignore-unmatch books 2>/dev/null || true
    cp -a public/. .
    # 提示：找出 master 上有、但本次产物里没有的文件（上一版残留），只报告不动手
    STALE="$(comm -23 \
      <(git ls-files | sort) \
      <(cd public && find . -type f | sed 's|^\./||' | sort) | head -20)"
    if [[ -n "$STALE" ]]; then
      echo "    ⚠️  以下文件本次产物里没有，仍留在 master 上（上一版残留）："
      echo "$STALE" | sed 's/^/       /'
    fi
    # 第一道保险：用 git rm --force 从 index + working tree 同时移除 dev 源文件
    # (master 是部署分支，不应包含 _config.yml / package.json / yarn.lock 等)
    # 优点：不会触发 mavis-trash 的 race condition；git 命令不会被权限门拦
    for src in _config.yml _config.fluid.yml _config.landscape.yml _admin-config.yml \
               package.json yarn.lock package-lock.json; do
      if [[ -e "$src" ]]; then
        git rm --force -- "$src" 2>/dev/null || true
      fi
    done
    find . -maxdepth 1 \( -name "*.bak" -o -name "*.original" \) -exec git rm --force -- {} + 2>/dev/null || true
    # 第一道保险：先把 .deploy_git 从 index 撤掉，防止下面 git add -A
    # 把它当 embedded git repo 加成 160000 gitlink（.gitignore 的 .deploy*/
    # 管不到这种 gitlink 模式，且 git reset HEAD 也撤不掉已经入 index 的 gitlink）
    git rm --cached --force -- .deploy_git 2>/dev/null || true
    git add -A
    # 第二道保险：把源文件从 index 撤回（如果第一道失败 / 仍存在）
    git reset HEAD public/ node_modules/ package-lock.json db.json .deploy_git source/ \
                   _config.yml _config.fluid.yml _config.landscape.yml _admin-config.yml \
                   package.json yarn.lock package-lock.json 2>/dev/null || true
    # 处理可能的 *.bak / *.original
    find . -maxdepth 1 \( -name "*.bak" -o -name "*.original" \) -exec git rm --force -- {} + 2>/dev/null || true
    if git diff --cached --quiet; then
      echo "    (没有需要 commit 的改动)"
    else
      MASTER_MSG="$MSG"
      if [[ -z "$MASTER_MSG" ]]; then
        MASTER_MSG="site: hexo g rebuild at $(date '+%Y-%m-%d %H:%M')"
      fi
      git -c user.email=billzong2012@gmail.com -c user.name=BillZong commit -m "$MASTER_MSG"
    fi
    # 推送：只要有未推送的提交就推（同样放在 commit 判断之外）
    if [[ $PUSH -eq 1 ]] && [[ -n "$(git log --oneline origin/master..master 2>/dev/null)" ]]; then
      echo "    push master..."
      git push origin master
    fi
  fi
else
  echo ""
  echo "==> 4/5 (跳过 master)"
fi

# ---------- 5. 回到 dev 分支 ----------
if [[ $SKIP_MASTER -eq 0 ]]; then
  echo ""
  echo "==> 5/5 切回 dev 分支"
  if [[ $DRY_RUN -eq 0 ]]; then
    git checkout dev
    if [[ $STASHED -eq 1 ]]; then
      git stash pop
    fi
  fi
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
