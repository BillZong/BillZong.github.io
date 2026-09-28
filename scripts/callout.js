'use strict';

// Custom Hexo tags for long-form articles:
//   {% tldr %}...{% endtldr %}                       -- TL;DR box at the top of article
//   {% callout [type] [title] %}...{% endcallout %} -- per-section callout (key takeaway)
//
// Calling styles for callout:
//   {% callout type="info" title="key_takeaway" %}     -- key="value" style (use _ for space)
//   {% callout info key_takeaway %}                    -- positional (use _ for space)
//   {% callout info %}                                 -- no title
//
// `type` defaults to "info". Allowed: info | note | tip | warning.
// Underscores in titles become spaces (hexo splits args on whitespace).
// Body content is rendered as markdown before being embedded in HTML (same pattern
// as hexo's built-in blockquote tag).
// Emits pure HTML; classes styled by source/css/custom.css.

function escapeHtml(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function parseAttrArgs(rawArgs) {
  const out = { type: 'info', title: '' };
  if (!rawArgs || rawArgs.length === 0) return out;

  let keyValType = null;
  let keyValTitle = null;
  const positional = [];

  for (let i = 0; i < rawArgs.length; i++) {
    const a = rawArgs[i];
    const m = a.match(/^(\w+)\s*=\s*"?([^"]*?)"?$/);
    if (m) {
      if (m[1] === 'type' && m[2]) keyValType = m[2].toLowerCase();
      else if (m[1] === 'title' && m[2]) keyValTitle = m[2];
    } else {
      positional.push(a);
    }
  }

  if (positional.length > 0 && !keyValType) {
    out.type = positional[0].toLowerCase().replace(/[^a-z]/g, '');
  }
  if (positional.length > 1 && !keyValTitle) {
    out.title = positional.slice(1).join(' ');
  }

  if (keyValType) out.type = keyValType;
  if (keyValTitle) out.title = keyValTitle;

  out.title = out.title
    .replace(/^["']|["']$/g, '')
    .replace(/_/g, ' ')
    .trim();
  return out;
}

const CALLOUT_TYPES = {
  info:    { label: '要点',  icon: 'ℹ',  cls: 'callout--info' },
  note:    { label: '说明',  icon: '※',  cls: 'callout--note' },
  tip:     { label: '提示',  icon: '✓',  cls: 'callout--tip' },
  warning: { label: '注意',  icon: '⚠',  cls: 'callout--warning' },
};

// Body content is rendered as markdown, same pattern as hexo's built-in blockquote tag.
// `this` may or may not have `render` depending on call path; fall back to escaped content.
function renderBody(content) {
  if (!content) return '';
  // `this` is context.ctx (the Hexo instance) when invoked from post processing;
  // try it first. Fall back to global `hexo` for ad-hoc tag.render() calls.
  const render = (this && this.render) || hexo.render;
  if (!render || typeof render.renderSync !== 'function') {
    return escapeHtml(content);
  }
  try {
    return render.renderSync({ text: content, engine: 'markdown' });
  } catch (e) {
    return escapeHtml(content);
  }
}

hexo.extend.tag.register('tldr', function (args, content) {
  const body = renderBody.call(this, content);
  return (
    '\n<aside class="tldr" role="note" aria-label="TL;DR">\n' +
    '  <div class="tldr__head"><span class="tldr__label">TL;DR</span><span class="tldr__hint">30 秒读完本节</span></div>\n' +
    '  <div class="tldr__body">' + body + '</div>\n' +
    '</aside>\n'
  );
}, { ends: true });

hexo.extend.tag.register('callout', function (args, content) {
  const { type, title } = parseAttrArgs(args);
  const meta = CALLOUT_TYPES[type] || CALLOUT_TYPES.info;
  const body = renderBody.call(this, content);

  const titleHtml = title
    ? `<div class="callout__head"><span class="callout__icon">${meta.icon}</span><span class="callout__label">${escapeHtml(meta.label)}</span><span class="callout__title">${escapeHtml(title)}</span></div>`
    : `<div class="callout__head"><span class="callout__icon">${meta.icon}</span><span class="callout__label">${escapeHtml(meta.label)}</span></div>`;

  return (
    '\n<aside class="callout ' + meta.cls + '" role="note">\n  ' +
    titleHtml + '\n  <div class="callout__body">' + body + '</div>\n</aside>\n'
  );
}, { ends: true });
