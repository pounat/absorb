import 'read_along_script.dart';

/// JavaScript for read along on a narrated EPUB: the sentence the narration
/// is on gets lit by its element id, word by word when asked, and the reader
/// is told whether it is on the page in view so it can turn. Installed as
/// `window.__absorbMO`.
String narrationBootstrap(int argb, {bool eink = false}) {
  return '(function() {'
      'var MO = window.__absorbMO = window.__absorbMO || {};'
      "MO.color = '${cssHex(argb)}';"
      "MO.eink = ${eink ? 'true' : 'false'};"
      '$_body'
      '})();';
}

const String _body = r'''
  MO.cur = MO.cur || null;
  MO.w = MO.w || null;

  MO.css = function() {
    if (MO.eink) {
      return '.absorb-mo-on { text-decoration: underline;' +
        ' text-decoration-thickness: 2px; text-underline-offset: 3px; }';
    }
    // Word by word dims the words still to come, as transcribed read along
    // does, so the full color reaches each word as it is read.
    var m = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(MO.color);
    var dim = m ? 'rgba(' + parseInt(m[1], 16) + ', ' + parseInt(m[2], 16) + ', ' +
      parseInt(m[3], 16) + ', 0.8)' : MO.color;
    return '.absorb-mo-on, .absorb-mo-on * { color: ' + MO.color + ' !important;' +
      ' transition: color 180ms ease; }' +
      '::highlight(absorb-mo-ahead) { color: ' + dim + '; }';
  };

  MO.style = function(doc) {
    try {
      var st = doc.getElementById('absorbNarrationStyle');
      if (!st) {
        st = doc.createElement('style');
        st.id = 'absorbNarrationStyle';
        (doc.head || doc.documentElement).appendChild(st);
      }
      st.textContent = MO.css();
    } catch (e) {}
  };

  MO.views = function() {
    try { return rendition.manager.views.all() || []; } catch (e) { return []; }
  };

  MO.same = function(a, b) {
    a = (a || '').split('#')[0];
    b = (b || '').split('#')[0];
    if (!a || !b) return false;
    if (a === b) return true;
    if (a.length > b.length) return a.slice(-b.length - 1) === '/' + b;
    return b.slice(-a.length - 1) === '/' + a;
  };

  MO.setColor = function(hex) {
    MO.color = hex;
    var vs = MO.views();
    for (var i = 0; i < vs.length; i++) {
      var doc = vs[i].contents && vs[i].contents.document;
      if (doc && doc.getElementById('absorbNarrationStyle')) MO.style(doc);
    }
  };

  // Judged against what is on screen, not the section's iframe, which holds
  // every page of the section side by side (or the whole scroll).
  MO.visible = function(el) {
    var out = { v: true, dir: 0 };
    try {
      var rects = el.getClientRects();
      var rect = rects.length ? rects[0] : el.getBoundingClientRect();
      if (!rect || (rect.width === 0 && rect.height === 0)) return out;
      var fe = el.ownerDocument.defaultView.frameElement;
      var fr = fe ? fe.getBoundingClientRect() : { left: 0, top: 0 };
      var flow = '';
      try { flow = (rendition.settings && rendition.settings.flow) || ''; } catch (e0) {}
      if (flow.indexOf('scrolled') === -1) {
        var x = fr.left + (rect.left + rect.right) / 2;
        out.v = x >= 0 && x < window.innerWidth;
        out.dir = x < 0 ? -1 : (x >= window.innerWidth ? 1 : 0);
        out.far = x < -window.innerWidth || x >= window.innerWidth * 2;
      } else {
        var y = fr.top + (rect.top + rect.bottom) / 2;
        out.v = y >= 0 && y < window.innerHeight;
        out.dir = y < 0 ? -1 : (y >= window.innerHeight ? 1 : 0);
        out.low = out.v && y > window.innerHeight * 0.7;
      }
    } catch (e) {}
    return out;
  };

  MO.find = function(href, id) {
    var vs = MO.views();
    for (var i = 0; i < vs.length; i++) {
      var v = vs[i];
      if (!v.section || !MO.same(v.section.href, href)) continue;
      var doc = v.contents && v.contents.document;
      var el = doc ? doc.getElementById(id) : null;
      if (el) return el;
    }
    return null;
  };

  MO.clear = function() {
    MO.unhear();
    if (MO.cur) {
      try { MO.cur.classList.remove('absorb-mo-on'); } catch (e) {}
      MO.cur = null;
    }
  };

  // The words of a sentence: where each one ends in the page, and where it
  // starts in the sentence's text with the spaces between counted once, which
  // is what the sentence's time is shared out by.
  MO.wordsOf = function(el) {
    var tw = el.ownerDocument.createTreeWalker(el, NodeFilter.SHOW_TEXT, null, false);
    var nodes = [], text = '', n;
    while ((n = tw.nextNode())) {
      nodes.push({ node: n, start: text.length });
      text += n.data;
    }
    var words = [], re = /\S+/g, m, at = 0, k = 0;
    while ((m = re.exec(text))) {
      var end = m.index + m[0].length;
      while (k + 1 < nodes.length && nodes[k + 1].start < end) k++;
      words.push({ at: at, node: nodes[k].node, off: end - nodes[k].start });
      at += m[0].length + 1;
    }
    return { words: words, total: Math.max(1, at - 1) };
  };

  // Word by word: [share] is how much of the lit sentence has been read, and
  // the words after the one it has reached are dimmed. The narration only
  // times sentences, so a word's time is its share of the sentence's text.
  // The dimming is a CSS highlight laid over the text, never markup put into
  // it, so CFIs into the page stay right. Without CSS highlights the
  // sentence is lit whole.
  MO.hear = function(share) {
    var el = MO.cur;
    if (!el || !(share >= 0)) { MO.unhear(); return; }
    try {
      var w = MO.w;
      if (!w || w.el !== el) {
        MO.unhear();
        var win = el.ownerDocument.defaultView;
        if (!win || !win.CSS || !win.CSS.highlights || typeof win.Highlight !== 'function') return;
        w = MO.wordsOf(el);
        if (!w.words.length) return;
        w.el = el;
        w.win = win;
        w.i = -1;
        MO.w = w;
      }
      var words = w.words, t = share * w.total, lo = 0, hi = words.length - 1;
      while (lo < hi) {
        var mid = (lo + hi + 1) >> 1;
        if (words[mid].at <= t) lo = mid; else hi = mid - 1;
      }
      if (lo === w.i) return;
      w.i = lo;
      var last = words[words.length - 1], r = el.ownerDocument.createRange();
      r.setStart(words[lo].node, words[lo].off);
      r.setEnd(last.node, last.off);
      // Set anew for each word rather than moving the range it has, so the
      // repaint doesn't hang on the engine noticing a range change.
      w.win.CSS.highlights.set('absorb-mo-ahead', new w.win.Highlight(r));
    } catch (e) {
      MO.unhear();
    }
  };

  MO.unhear = function() {
    if (!MO.w) return;
    try { MO.w.win.CSS.highlights.delete('absorb-mo-ahead'); } catch (e) {}
    MO.w = null;
  };

  // 'on' when the sentence is on the page in view ('low' when that is near
  // the bottom of a scroll), 'before' or 'after' when it is on the page next
  // to it, 'far-before' or 'far-after' when it is further along the section,
  // 'missing' when its section isn't loaded.
  MO.show = function(href, id, share) {
    var el = MO.find(href, id);
    if (!el) { MO.clear(); return 'missing'; }
    if (MO.cur !== el) {
      MO.clear();
      MO.style(el.ownerDocument);
      el.classList.add('absorb-mo-on');
      MO.cur = el;
    }
    MO.hear(share);
    var vis = MO.visible(el);
    if (vis.low) return 'low';
    if (vis.far) return vis.dir < 0 ? 'far-before' : 'far-after';
    return vis.v ? 'on' : (vis.dir < 0 ? 'before' : 'after');
  };

  // Where the sentence is, the same way, without lighting it.
  MO.where = function(href, id) {
    var el = MO.find(href, id);
    if (!el) return 'missing';
    var vis = MO.visible(el);
    return vis.v ? 'on' : (vis.dir < 0 ? 'before' : 'after');
  };

  // Scroll mode: glide the lit sentence up to a quarter of the way down
  // the screen, rather than jumping a whole screen at a time.
  MO.reveal = function(href, id) {
    var el = MO.find(href, id);
    var c = null;
    try { c = rendition.manager && rendition.manager.container; } catch (e0) {}
    if (!el || !c) return false;
    try {
      var fe = el.ownerDocument.defaultView.frameElement;
      var fr = fe ? fe.getBoundingClientRect() : { top: 0 };
      var r = el.getBoundingClientRect();
      var y = fr.top + r.top;
      c.scrollTo({ top: c.scrollTop + y - window.innerHeight * 0.25, behavior: 'smooth' });
      return true;
    } catch (e) {
      return false;
    }
  };

  MO.go = function(href, id) {
    var items = [];
    try { items = book.spine.spineItems || []; } catch (e) {}
    for (var i = 0; i < items.length; i++) {
      if (MO.same(items[i].href, href)) {
        rendition.display(items[i].href + (id ? '#' + id : ''));
        return true;
      }
    }
    return false;
  };

  // The ids around a selection (its own element and those it sits in), then
  // the ones after it, with their section: where "play from here" starts.
  MO.idsAt = function(cfi) {
    var out = { href: '', ids: [] };
    var vs = MO.views();
    for (var i = 0; i < vs.length; i++) {
      var v = vs[i];
      var r = null;
      try { r = v.contents.range(cfi); } catch (e) {}
      if (!r || !v.section) continue;
      out.href = v.section.href;
      var n = r.startContainer;
      while (n && n.nodeType !== 1) n = n.parentNode;
      for (var el = n; el && el.tagName && el.tagName.toLowerCase() !== 'body'; el = el.parentElement) {
        if (el.id) out.ids.push(el.id);
      }
      var doc = v.contents.document;
      var all = doc.body ? doc.body.querySelectorAll('[id]') : [];
      for (var j = 0; j < all.length && out.ids.length < 60; j++) {
        if (n && (n.compareDocumentPosition(all[j]) & 4)) out.ids.push(all[j].id);
      }
      break;
    }
    return JSON.stringify(out);
  };

  // The ids on the page in view, in reading order, with their section: where
  // read along starts the narration when the book isn't playing yet.
  MO.onPage = function() {
    var out = { href: '', ids: [] };
    var vs = MO.views();
    for (var i = 0; i < vs.length && out.ids.length < 300; i++) {
      var v = vs[i];
      var doc = v.contents && v.contents.document;
      if (!doc || !v.section) continue;
      var els = doc.body ? doc.body.querySelectorAll('[id]') : [];
      for (var j = 0; j < els.length && out.ids.length < 300; j++) {
        var vis = MO.visible(els[j]);
        if (vis.v) {
          if (!out.href) out.href = v.section.href;
          if (v.section.href === out.href) out.ids.push(els[j].id);
        } else if (vis.dir > 0 && out.ids.length) {
          break;
        }
      }
    }
    return JSON.stringify(out);
  };
''';
