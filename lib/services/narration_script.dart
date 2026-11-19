import 'read_along_script.dart';

/// JavaScript for read along on a narrated EPUB or sidecar `.smil`: the
/// sentence (or word, when `wordIndex >= 0`) the narration is on gets lit by
/// its element id or deterministic `abs-<tag>-<n>` anchor, and the reader is
/// told whether it is on the page in view so it can turn. Installed as
/// `window.__absorbMO`.
String narrationBootstrap(int argb, {bool eink = false}) {
  final r = (argb >> 16) & 0xFF, g = (argb >> 8) & 0xFF, b = argb & 0xFF;
  return '(function() {'
      'var MO = window.__absorbMO = window.__absorbMO || {};'
      "MO.color = '${cssHex(argb)}';"
      "MO.rgb = '$r, $g, $b';"
      "MO.eink = ${eink ? 'true' : 'false'};"
      '$_body'
      '})();';
}

const String _body = r'''
  MO.cur = MO.cur || null;
  MO.curWord = MO.curWord || null;
  MO.wordSpans = MO.wordSpans || null;
  MO.wordMode = MO.wordMode || false;

  MO.SYNC_BLOCKS = {
    p:1, h1:1, h2:1, h3:1, h4:1, h5:1, h6:1, li:1, dd:1, dt:1, td:1, th:1,
    figcaption:1, caption:1, blockquote:1, pre:1, address:1, summary:1,
    div:1, section:1, article:1, aside:1, header:1, footer:1, main:1, nav:1
  };
  MO.INLINE = {
    a:1, span:1, em:1, strong:1, i:1, b:1, u:1, small:1, sub:1, sup:1,
    code:1, q:1, cite:1, abbr:1, time:1, mark:1, s:1, ins:1, del:1,
    big:1, tt:1, font:1, label:1, bdi:1, bdo:1, ruby:1, rt:1, rp:1, wbr:1
  };
  MO.SKIP = {
    script:1, style:1, head:1, title:1, meta:1, link:1, svg:1, math:1, template:1
  };
  MO.WORD_RE = /[^\s\u2010-\u2015\u2212-]+/g;

  MO.normWord = function(tok) {
    var s = tok.replace(/[\u2019\u2018\u02bc]/g, "'").replace(/[\u201c\u201d]/g, '"');
    try { s = s.normalize('NFKD').replace(/[\u0300-\u036f]/g, ''); } catch (e) {}
    return s.toLowerCase().replace(/[^a-z0-9'\u00c0-\u024f\u0400-\u04ff\u3040-\u30ff\u4e00-\u9fff]+/g, '');
  };

  // Mirrors audiobooksync/epub.py `_DocumentWalker`: text belongs to the
  // innermost open block, a block gets an anchor on its first text run, and
  // counters increment even when the element already has an `id`.
  MO.ensureAnchors = function(doc) {
    if (!doc || !doc.body || doc.__absAnchored) return;
    doc.__absAnchored = true;
    var counters = {};
    var stack = [];
    function place() {
      for (var i = stack.length - 1; i >= 0; i--) {
        var f = stack[i];
        if (!f.isBlock) continue;
        if (!f.placed) {
          f.placed = true;
          counters[f.tag] = (counters[f.tag] || 0) + 1;
          if (!f.id) f.el.setAttribute('data-abs-anchor', 'abs-' + f.tag + '-' + counters[f.tag]);
        }
        return;
      }
    }
    function walk(node) {
      if (node.nodeType === 3 || node.nodeType === 4) {
        if (node.nodeValue) place();
        return;
      }
      if (node.nodeType !== 1) return;
      var tag = node.tagName ? node.tagName.toLowerCase() : '';
      if (MO.SKIP[tag]) return;
      if (tag === 'br') { place(); return; }
      var isBlock = !!MO.SYNC_BLOCKS[tag] && !MO.INLINE[tag];
      var id = (node.getAttribute && node.getAttribute('id') || '').trim();
      stack.push({ el: node, tag: tag, isBlock: isBlock, id: id, placed: false });
      for (var c = node.firstChild; c; c = c.nextSibling) walk(c);
      stack.pop();
    }
    walk(doc.body);
  };

  MO.css = function() {
    if (MO.eink) {
      return '.absorb-mo-on, .absorb-mo-w-on { text-decoration: underline;' +
        ' text-decoration-thickness: 2px; text-underline-offset: 3px; }';
    }
    return '.absorb-mo-on, .absorb-mo-on * { color: ' + MO.color + ' !important;' +
      ' transition: color 180ms ease; }' +
      '.absorb-mo-w-on, .absorb-mo-w-on * { color: ' + MO.color + ' !important;' +
      ' background-color: rgba(' + (MO.rgb || '100, 150, 255') + ', 0.16);' +
      ' border-radius: 3px; transition: color 120ms ease; }';
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
    var m = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(hex);
    if (m) {
      MO.rgb = parseInt(m[1], 16) + ', ' + parseInt(m[2], 16) + ', ' + parseInt(m[3], 16);
    }
    var vs = MO.views();
    for (var i = 0; i < vs.length; i++) {
      var doc = vs[i].contents && vs[i].contents.document;
      if (doc && doc.getElementById('absorbNarrationStyle')) MO.style(doc);
    }
  };

  // Judged against what is on screen, not the section's iframe, which holds
  // every page of the section side by side (or the whole scroll).
  MO.visible = function(el) {
    try {
      var rects = el.getClientRects();
      var rect = rects.length ? rects[0] : el.getBoundingClientRect();
      return MO.visibleRect(el.ownerDocument, rect);
    } catch (e) { return { v: true, dir: 0 }; }
  };

  MO.visibleRect = function(doc, rect) {
    var out = { v: true, dir: 0 };
    try {
      if (!rect || (rect.width === 0 && rect.height === 0)) return out;
      var fe = doc.defaultView.frameElement;
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
      if (!doc) continue;
      MO.ensureAnchors(doc);
      var el = doc.getElementById(id);
      if (!el && doc.body) {
        el = doc.body.querySelector('[data-abs-anchor="' + id.replace(/"/g, '\\"') + '"]');
      }
      if (el) return el;
    }
    return null;
  };

  MO.unwrapWords = function() {
    if (MO.curWord) {
      try { MO.curWord.classList.remove('absorb-mo-w-on'); } catch (e) {}
      MO.curWord = null;
    }
    if (MO.wordSpans && MO.wordSpans.length) {
      for (var i = 0; i < MO.wordSpans.length; i++) {
        var sp = MO.wordSpans[i];
        var p = sp && sp.parentNode;
        if (!p) continue;
        while (sp.firstChild) p.insertBefore(sp.firstChild, sp);
        p.removeChild(sp);
      }
      try { if (MO.cur) MO.cur.normalize(); } catch (e) {}
    }
    MO.wordSpans = null;
    MO.wordMode = false;
  };

  MO.wrapWords = function(el) {
    var doc = el.ownerDocument;
    var nodes = [];
    function collect(node) {
      if (node.nodeType === 3 || node.nodeType === 4) {
        if (node.nodeValue) nodes.push(node);
        return;
      }
      if (node.nodeType !== 1) return;
      var tag = node.tagName ? node.tagName.toLowerCase() : '';
      if (MO.SKIP[tag]) return;
      if (node !== el && MO.SYNC_BLOCKS[tag] && !MO.INLINE[tag]) return;
      for (var c = node.firstChild; c; c = c.nextSibling) collect(c);
    }
    collect(el);
    var spans = [];
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i], txt = n.nodeValue, parent = n.parentNode;
      if (!parent || !txt) continue;
      MO.WORD_RE.lastIndex = 0;
      var m, last = 0, frag = null;
      while ((m = MO.WORD_RE.exec(txt)) !== null) {
        if (!MO.normWord(m[0])) continue;
        if (!frag) frag = doc.createDocumentFragment();
        if (m.index > last) frag.appendChild(doc.createTextNode(txt.slice(last, m.index)));
        var sp = doc.createElement('span');
        sp.className = 'absorb-mo-w';
        sp.textContent = m[0];
        frag.appendChild(sp);
        spans.push(sp);
        last = m.index + m[0].length;
      }
      if (frag) {
        if (last < txt.length) frag.appendChild(doc.createTextNode(txt.slice(last)));
        parent.replaceChild(frag, n);
      }
    }
    return spans;
  };

  MO.clear = function() {
    MO.unwrapWords();
    if (MO.cur) {
      try { MO.cur.classList.remove('absorb-mo-on'); } catch (e) {}
      MO.cur = null;
    }
  };

  // 'on' when the sentence/word is on the page in view ('low' when that is
  // near the bottom of a scroll), 'before' or 'after' when it is on the page
  // next to it, 'far-before' or 'far-after' when it is further along the
  // section, 'missing' when its section isn't loaded.
  MO.show = function(href, id, wordIndex) {
    var el = MO.find(href, id);
    if (!el) { MO.clear(); return 'missing'; }
    var wantWords = typeof wordIndex === 'number' && wordIndex >= 0;
    if (MO.cur !== el || MO.wordMode !== wantWords) {
      MO.clear();
      MO.style(el.ownerDocument);
      MO.cur = el;
      MO.wordMode = wantWords;
      if (wantWords) {
        MO.wordSpans = MO.wrapWords(el);
      } else {
        el.classList.add('absorb-mo-on');
      }
    }
    var target = el;
    if (wantWords && MO.wordSpans && MO.wordSpans.length) {
      var idx = Math.max(0, Math.min(MO.wordSpans.length - 1, wordIndex));
      var w = MO.wordSpans[idx];
      if (MO.curWord !== w) {
        if (MO.curWord) {
          try { MO.curWord.classList.remove('absorb-mo-w-on'); } catch (e) {}
        }
        if (w) {
          w.classList.add('absorb-mo-w-on');
          target = w;
        }
        MO.curWord = w;
      } else if (w) {
        target = w;
      }
    }
    var vis = MO.visible(target);
    if (vis.low) return 'low';
    if (vis.far) return vis.dir < 0 ? 'far-before' : 'far-after';
    return vis.v ? 'on' : (vis.dir < 0 ? 'before' : 'after');
  };

  // Where the voice is inside the lit sentence, [frac] of the way through
  // its text, and whether that spot is on the page in view. A sentence that
  // runs onto the next page gets the turn once the voice reaches that part,
  // not when the next sentence starts over there.
  MO.heard = function(href, id, frac) {
    var el = MO.find(href, id);
    if (!el) return JSON.stringify({ held: false });
    var out = { held: true, visible: true, dir: 0, low: false };
    try {
      var doc = el.ownerDocument;
      var tw = doc.createTreeWalker(el, NodeFilter.SHOW_TEXT, null, false), nodes = [], total = 0, n;
      while (n = tw.nextNode()) { nodes.push(n); total += n.textContent.length; }
      if (!total) return JSON.stringify(out);
      var want = Math.max(0, Math.min(total - 1, Math.floor(total * frac)));
      var at = 0, node = nodes[0], off = 0;
      for (var i = 0; i < nodes.length; i++) {
        var len = nodes[i].textContent.length;
        if (want < at + len) { node = nodes[i]; off = want - at; break; }
        at += len;
      }
      var r = doc.createRange();
      r.setStart(node, off);
      r.setEnd(node, Math.min(node.textContent.length, off + 1));
      var vis = MO.visibleRect(doc, r.getBoundingClientRect());
      out.visible = vis.v;
      out.dir = vis.dir;
      out.low = !!vis.low;
    } catch (e) {}
    return JSON.stringify(out);
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
        var frag = (id && !/^abs-/.test(id)) ? '#' + id : '';
        rendition.display(items[i].href + frag);
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
      var doc = v.contents.document;
      MO.ensureAnchors(doc);
      out.href = v.section.href;
      var n = r.startContainer;
      while (n && n.nodeType !== 1) n = n.parentNode;
      for (var el = n; el && el.tagName && el.tagName.toLowerCase() !== 'body'; el = el.parentElement) {
        var aid = el.id || (el.getAttribute && el.getAttribute('data-abs-anchor'));
        if (aid) out.ids.push(aid);
      }
      var all = doc.body ? doc.body.querySelectorAll('[id], [data-abs-anchor]') : [];
      for (var j = 0; j < all.length && out.ids.length < 60; j++) {
        if (n && (n.compareDocumentPosition(all[j]) & 4)) {
          var jid = all[j].id || all[j].getAttribute('data-abs-anchor');
          if (jid) out.ids.push(jid);
        }
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
      MO.ensureAnchors(doc);
      var els = doc.body ? doc.body.querySelectorAll('[id], [data-abs-anchor]') : [];
      for (var j = 0; j < els.length && out.ids.length < 300; j++) {
        var vis = MO.visible(els[j]);
        if (vis.v) {
          if (!out.href) out.href = v.section.href;
          var eid = els[j].id || els[j].getAttribute('data-abs-anchor');
          if (v.section.href === out.href && eid) out.ids.push(eid);
        } else if (vis.dir > 0 && out.ids.length) {
          break;
        }
      }
    }
    return JSON.stringify(out);
  };
''';
