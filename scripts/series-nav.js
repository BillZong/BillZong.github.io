'use strict';

// 在每篇属于某个系列的文章底部，注入"系列内导航"：
//   - 系列名 + 当前 N / M 进度
//   - 整个系列目录（按 series_order 排序）
//   - 上一节 / 下一节快捷链接
//
// 触发条件：front-matter 同时有 `series` 和 `series_order` 字段
// 不依赖 hexo-generator-collection，不改主题 partial，不改 _config。
//
// hexo 6 渲染时序坑点：
//   1. `init()` 阶段 load source → process 每篇 post
//      → 每篇 post 触发 `before_post_render` → 渲染 → `after_post_render`
//   2. `before_generate` 触发（晚于所有 post 渲染）
//   3. 写盘
// 所以 `before_generate` 阶段建索引来不及，post 早已渲染完。
// 改用 lazy build：第一次进入 `before_post_render` 时检查索引，没建就建。
// `after_generate` 触发时一定已 build 完毕（generate 是单 process 内最后阶段）。

let seriesIndex = null; // Map<seriesName, Array<{title, permalink, order, source}>>

function buildIndex(hexo) {
  const model = hexo.model('Post');
  if (!model) return new Map();
  const allPosts = typeof model.toArray === 'function' ? model.toArray() : Array.from(model);
  const idx = new Map();
  for (const p of allPosts) {
    if (!p.series || p.series_order == null) continue;
    if (p.layout && p.layout !== 'post') continue;
    if (!idx.has(p.series)) idx.set(p.series, []);
    idx.get(p.series).push({
      title: p.title,
      // 用 path 转成绝对绝对路径：post.path 是 hexo 内部路径（如 "post/xxx.html"），
      // 转成 "/post/xxx.html" 形式，避免相对路径在不同页面位置错乱。
      // 不用 post.permalink（绝对 URL 含 site.url）—— 本地预览会跳外网。
      permalink: (p.path && p.path.startsWith('post/')) ? `/${p.path}` : (p.path || (p.abbrlink ? `/post/${p.abbrlink}.html` : '#')),
      order: Number(p.series_order),
      source: p.source,
    });
  }
  for (const arr of idx.values()) arr.sort((a, b) => a.order - b.order);
  return idx;
}

function buildNavHtml(seriesName, siblings, idx) {
  const total = siblings.length;
  const cur = idx + 1;
  const prev = idx > 0 ? siblings[idx - 1] : null;
  const next = idx < siblings.length - 1 ? siblings[idx + 1] : null;

  const listItems = siblings
    .map((p, i) => {
      const isCur = i === idx;
      const cls = isCur ? 'series-nav__item series-nav__item--current' : 'series-nav__item';
      const num = String(i + 1).padStart(2, '0');
      return `<li class="${cls}"><span class="series-nav__num">${num}</span><a href="${p.permalink}">${p.title}</a></li>`;
    })
    .join('');

  const prevLink = prev
    ? `<a class="series-nav__pager-link" href="${prev.permalink}" rel="prev"><i class="iconfont icon-arrowleft"></i><span class="series-nav__pager-title">${prev.title}</span></a>`
    : '<span class="series-nav__pager-disabled">已是本系列首篇</span>';
  const nextLink = next
    ? `<a class="series-nav__pager-link" href="${next.permalink}" rel="next"><span class="series-nav__pager-title">${next.title}</span><i class="iconfont icon-arrowright"></i></a>`
    : '<span class="series-nav__pager-disabled">已是本系列末篇</span>';

  return `
<style>
  .series-nav{margin:2.5rem 0 1rem;padding:1.25rem 1.5rem;border:1px solid rgba(0,0,0,.08);border-radius:8px;background:rgba(0,0,0,.02);font-size:.95rem;line-height:1.6}
  .series-nav__head{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:.75rem;padding-bottom:.5rem;border-bottom:1px dashed rgba(0,0,0,.12)}
  .series-nav__series{font-weight:600;color:var(--theme-color,#3da5f5)}
  .series-nav__pos{color:#888;font-size:.85em}
  .series-nav__list{list-style:none;padding:0;margin:.5rem 0 1rem;display:grid;grid-template-columns:1fr;gap:.35rem}
  .series-nav__item{display:flex;gap:.5rem;align-items:baseline;padding:.2rem 0;color:#555}
  .series-nav__item a{color:#555;text-decoration:none;flex:1}
  .series-nav__item a:hover{color:var(--theme-color,#3da5f5)}
  .series-nav__num{color:#bbb;font-variant-numeric:tabular-nums;font-size:.85em;min-width:1.75em}
  .series-nav__item--current{font-weight:600;color:var(--theme-color,#3da5f5)}
  .series-nav__item--current a{color:var(--theme-color,#3da5f5);pointer-events:none}
  .series-nav__pager{display:flex;justify-content:space-between;gap:1rem;padding-top:.75rem;border-top:1px dashed rgba(0,0,0,.12);font-size:.9rem}
  .series-nav__pager-link{display:flex;align-items:center;gap:.35rem;color:#555;text-decoration:none;max-width:48%;text-align:inherit}
  .series-nav__pager-link:hover{color:var(--theme-color,#3da5f5)}
  .series-nav__pager-title{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
  .series-nav__pager-disabled{color:#bbb;font-size:.85em}
  @media(max-width:600px){.series-nav__pager-title{max-width:12em}}
</style>
<nav class="series-nav" aria-label="系列导航">
  <div class="series-nav__head">
    <span class="series-nav__series">📚 ${seriesName}</span>
    <span class="series-nav__pos">第 ${cur} / ${total} 节</span>
  </div>
  <ol class="series-nav__list">${listItems}</ol>
  <div class="series-nav__pager">
    <span class="series-nav__pager-cell series-nav__pager-cell--prev">${prevLink}</span>
    <span class="series-nav__pager-cell series-nav__pager-cell--next">${nextLink}</span>
  </div>
</nav>
`.trim();
}

hexo.extend.filter.register('before_post_render', function (data) {
  if (data.layout !== 'post' || !data.series || data.series_order == null) return data;

  if (!seriesIndex) seriesIndex = buildIndex(hexo);

  const siblings = seriesIndex.get(data.series);
  if (!siblings || siblings.length < 2) return data;

  // identity: source 路径（最稳）
  let idx = -1;
  if (data.source) {
    idx = siblings.findIndex((s) => s.source === data.source);
  }
  // fallback: title
  if (idx < 0) {
    idx = siblings.findIndex((s) => s.title === data.title);
  }
  if (idx < 0) return data;

  const nav = buildNavHtml(data.series, siblings, idx);
  data.content = (data.content || '').replace(/\s*$/, '') + '\n\n' + nav + '\n';
  return data;
});

// 重置缓存：每个 hexo command 进程独立
hexo.extend.filter.register('after_generate', function () {
  seriesIndex = null;
});
