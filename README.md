# BillZong.github.io

个人技术博客，双分支发布：**`dev` = 源码，`master` = 部署产物**（GitHub Pages 从 `master` 根目录取站点）。

## 目录结构

| 路径 | 说明 |
| --- | --- |
| `source/` | Hexo 源文件（文章、页面、CSS、JS） |
| `themes/fluid/` | Fluid 主题 |
| `bin/hexo-publish.sh` | 一键发布：构建 → 双分支提交 → 推送 |
| `bin/build-books.sh` | 构建小书（VitePress）并拼进 `public/books/` |
| `public/` | 构建产物，不入库（`.gitignore` 已排除） |

小书源码在同级仓库 `../books`，构建后以 `/books/` 子路径挂到主站
（`https://billzong.github.io/books/`）。`/books/` 只能由主站仓库自己提供——
同账号下只有用户站点仓库能占根域名，其他仓库的 Pages 只能挂在 `/仓库名/` 子路径。

## 本地预览

```bash
npx hexo server
```

预览小书（需要同级存在 `../books` 仓库）：

```bash
cd ../books && npx vitepress dev docs
```

## 发布

```bash
./bin/hexo-publish.sh --push -m "feat: xxx"
```

常用参数：

| 参数 | 作用 |
| --- | --- |
| `--push` | 构建后推送 `master` + `dev` 到 origin |
| `--skip-master` | 只提交 `dev`（源码），不动部署分支 |
| `--skip-dev` | 只提交 `master`（产物） |
| `--skip-books` | 不构建小书，本次发布不含 `/books/` |
| `--dry-run` | 只演练流程，不 commit 不 push |
| `-m "msg"` | 指定 commit 信息（不给则自动生成时间戳） |

执行顺序（**顺序不能改**）：

1. `dev`：`hexo clean` + `hexo generate` → `public/`
2. `dev`：提交源码改动 → **必须早于切 `master`**，否则未提交改动会让 `git checkout master` 失败
3. `dev`：构建小书 → `public/books/` → **必须晚于 `hexo generate`**，后者会重建 `public/` 把产物冲掉
4. `master`：`cp -a public/. .` + 提交
5. 切回 `dev`

小书构建失败只警告、不阻断博客发布——博客是主站，稳定性优先。

小书产物有两道**硬门禁**（不通过就中止发布，不会产出任何会被公开的东西）：

| 门禁 | 拦什么 |
| --- | --- |
| 隔离检查 | 各本书互相污染：章节重名、跨书相对链接、目录漏登记 |
| 泄漏扫描 | 产物里出现本机路径、小书仓库地址、iCloud 路径 |

`public/books/` 每次都是全量重建（VitePress 资源文件名带内容哈希，内容一改文件名就变），
平铺到 master 前会先删掉上一版残留。否则旧 chunk 会跟着进提交，
等于把改版之前的历史内容继续挂在公网上。脚本还会检查并报告
「master 上有、但本次产物里没有」的文件。

## 已知问题

- `/img/favicon.png` 404：`themes/fluid/_config.yml` 里的二维码/头像配置指向了一个仓库中不存在的文件，
  需要替换成自己的二维码图片。
- 小书源码仓库是**私有**的，不对外公开链接。公开产物里不含仓库地址，也不含任何本机路径
  （构建时已逐项扫描校验）。新增小书时不要在正文、页脚或关于页里写源码仓库地址。
