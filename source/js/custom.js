/**
 * 目录面板交互修正
 *
 * 背景:
 *   tocbot 的 updateTocScroll 会执行 `toc.scrollTop = activeItem.offsetTop`,
 *   即把当前章节顶到目录面板顶部。它挂在 document 的 scroll 事件上,
 *   所以"点击目录跳转"触发的平滑滚动也会命中, 表现为:
 *   点目录后目录面板自己又刷了一下, 被点的条目被顶到面板最上方。
 *
 * 期望交互:
 *   1. 点击目录 → 只滚动左侧内容区到对应段落, 目录面板保持原位不动;
 *   2. 手动滚动内容区 → 目录面板照常跟随当前章节(保持原效果)。
 *
 * 实现:
 *   接管 #toc-body 自身的 scrollTop 属性写入, 在"点击目录引起的滚动"期间丢弃
 *   tocbot 的写入, 滚动停止后再把面板位置还原。tocbot 的激活高亮是独立逻辑,
 *   不受影响, 因此高亮仍会正确落在被点条目上。
 */
(function () {
  'use strict';

  var IDLE_MS = 220; // 内容区滚动停止多久后解除锁定

  function setup() {
    var tocBody = document.getElementById('toc-body');
    if (!tocBody || tocBody.dataset.tocLockInstalled === '1') {
      return;
    }
    tocBody.dataset.tocLockInstalled = '1';

    // 找到原生 scrollTop 描述符(通常在 Element.prototype 上)
    var native = null;
    for (var proto = tocBody; proto; proto = Object.getPrototypeOf(proto)) {
      var desc = Object.getOwnPropertyDescriptor(proto, 'scrollTop');
      if (desc && desc.get && desc.set) {
        native = desc;
        break;
      }
    }
    if (!native) {
      return;
    }

    var locked = false; // 锁定期间丢弃 tocbot 对面板的滚动写入
    var savedTop = 0; // 点击目录时面板的位置, 滚动结束后还原
    var timer = null;

    Object.defineProperty(tocBody, 'scrollTop', {
      configurable: true,
      get: function () {
        return native.get.call(this);
      },
      set: function (value) {
        if (locked) {
          return;
        }
        native.set.call(this, value);
      }
    });

    function release() {
      clearTimeout(timer);
      timer = setTimeout(function () {
        if (!locked) {
          return;
        }
        locked = false;
        // 兜底: 期间浏览器可能因聚焦把面板滚了一下, 还原到点击前的位置
        if (tocBody.scrollTop !== savedTop) {
          native.set.call(tocBody, savedTop);
        }
      }, IDLE_MS);
    }

    // 内容区滚动: 仅在点击导航期间续期, 普通手动滚动不受影响
    window.addEventListener(
      'scroll',
      function () {
        if (locked) {
          release();
        }
      },
      { passive: true }
    );

    // 点击目录: 锁住面板, 让内容区滚过去, 面板保持原位
    tocBody.addEventListener(
      'click',
      function (event) {
        var target = event.target;
        if (!target || typeof target.closest !== 'function') {
          return;
        }
        // 折叠/展开按钮不是导航
        if (target.closest('.toc-toggle')) {
          return;
        }
        var link = target.closest('a');
        if (!link || !tocBody.contains(link)) {
          return;
        }
        var href = link.getAttribute('href') || '';
        if (href.charAt(0) !== '#') {
          return;
        }
        locked = true;
        savedTop = tocBody.scrollTop;
        release();
      },
      true
    );
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setup);
  } else {
    setup();
  }
})();
