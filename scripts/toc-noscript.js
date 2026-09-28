'use strict';

// Inject a <noscript> static TOC fallback into the right-sidebar TOC.
//
// Fluid theme populates #toc-body client-side via tocbot.js. When JS is disabled
// (rare but happens: reader-mode browsers, screen readers, crawler previews),
// the right sidebar shows an empty "目录" box. This filter walks every <h2>/<h3>
// in the rendered post HTML and emits a flat, clickable list inside <noscript>
// right after the empty <div id="toc-body"></div>.
//
// Hook point: after_render:html  -- runs on the FULL page HTML (post + layout),
// so we can see the toc-body <div> that the Fluid ejs layout emits.
// Only acts on pages that have both the toc-body div AND at least 1 h2/h3.

const HEADING_RE = /<h([23])\s+id="([^"]+)"[^>]*>([\s\S]*?)<\/h\1>/g;
const TAG_RE = /<[^>]+>/g;
const TOC_BODY_RE = /<div\s+class="toc-body"\s+id="toc-body"><\/div>/;

function stripTags(html) {
  return String(html || '')
    .replace(TAG_RE, '')
    .replace(/&quot;/g, '"')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&#39;/g, "'")
    .trim();
}

function buildNoscriptHtml(html) {
  const headings = [];
  let m;
  HEADING_RE.lastIndex = 0;
  while ((m = HEADING_RE.exec(html)) !== null) {
    headings.push({ level: Number(m[1]), id: m[2], text: stripTags(m[3]) });
  }
  if (headings.length === 0) return null;

  const items = headings.map((h) => {
    const indent = h.level === 3 ? ' class="toc-noscript__sub"' : '';
    const safeText = h.text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
    return `<li${indent}><a href="#${h.id}">${safeText}</a></li>`;
  }).join('');

  return (
    '<noscript>' +
    '<div class="toc-noscript" role="navigation" aria-label="目录 (无 JS 兜底)">' +
    '<p class="toc-noscript__head">目录 (静态版)</p>' +
    `<ul class="toc-noscript__list">${items}</ul>` +
    '</div>' +
    '</noscript>'
  );
}

// after_post_render: post.content (markdown HTML, no layout yet) -- no toc-body here
// after_render:html : full page HTML (post + layout) -- toc-body lives here
hexo.extend.filter.register('after_render:html', function (html, data) {
  if (typeof html !== 'string') return html;
  if (!TOC_BODY_RE.test(html)) return html;
  const fallback = buildNoscriptHtml(html);
  if (!fallback) return html;
  return html.replace(TOC_BODY_RE, (match) => match + '\n' + fallback);
});
