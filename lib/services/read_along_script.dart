/// The in-page script behind read along's coloring.
///
/// epub.js annotations are an SVG overlay drawn on top of the page, so they
/// can only ever box or underline text - they cannot repaint the words
/// themselves. This paints the real glyphs instead: the CSS Custom Highlight
/// API where the WebView has it (no DOM changes at all), and wrapping the
/// range in spans on older WebViews (iOS below 17.2), unwrapped again on every
/// move so the page ends up exactly as it started.
library;

/// Six-digit hex for an ARGB value, for CSS.
String cssHex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Installs `window.__absorbRA` in the reader page. Safe to run more than
/// once; a second run just refreshes the color.
String readAlongBootstrap(int argb) {
  final hex = cssHex(argb);
  final r = (argb >> 16) & 0xFF, g = (argb >> 8) & 0xFF, b = argb & 0xFF;
  return '''
(function() {
  var RA = window.__absorbRA = window.__absorbRA || {};
  RA.color = '$hex';
  RA.dimRgba = 'rgba($r, $g, $b, 0.8)';
  RA.cur = null;

  RA.css = function() {
    var mix = 'color-mix(in srgb, ' + RA.color + ' 55%, currentColor)';
    return '::highlight(absorbRaWord) { color: ' + RA.color + '; }' +
      '::highlight(absorbRaDim) { color: ' + RA.dimRgba + '; }' +
      '.absorb-ra-word { color: ' + RA.color + ' !important; }' +
      '.absorb-ra-dim { color: ' + RA.dimRgba + ' !important; }' +
      '@supports (color: color-mix(in srgb, red 50%, blue)) {' +
      '  ::highlight(absorbRaDim) { color: ' + mix + '; }' +
      '  .absorb-ra-dim { color: ' + mix + ' !important; }' +
      '}';
  };

  RA.style = function(doc) {
    try {
      if (!doc) return;
      var st = doc.getElementById('absorbReadAlongStyle');
      if (!st) {
        st = doc.createElement('style');
        st.id = 'absorbReadAlongStyle';
        (doc.head || doc.documentElement).appendChild(st);
      }
      st.textContent = RA.css();
    } catch (e) {}
  };

  RA.docs = function() {
    var out = [];
    try {
      var contents = (typeof rendition.getContents === 'function') ? rendition.getContents() : [];
      for (var i = 0; i < contents.length; i++) {
        if (contents[i] && contents[i].document) out.push(contents[i]);
      }
    } catch (e) {}
    return out;
  };

  RA.setColor = function(hex) {
    RA.color = hex;
    RA.dimRgba = hex;
    var m = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})\$/i.exec(hex);
    if (m) {
      RA.dimRgba = 'rgba(' + parseInt(m[1], 16) + ', ' + parseInt(m[2], 16) +
        ', ' + parseInt(m[3], 16) + ', 0.8)';
    }
    var cs = RA.docs();
    for (var i = 0; i < cs.length; i++) RA.style(cs[i].document);
  };

  // Char offset -> text node map for a page document. Rebuilt after any span
  // wrapping, since that splits text nodes; the raw text never changes, so
  // offsets stay valid across rebuilds.
  RA.nodeMap = function(doc) {
    var tw = doc.createTreeWalker(doc.body || doc, NodeFilter.SHOW_TEXT, null, false);
    var nodes = [], raw = '', node;
    while (node = tw.nextNode()) {
      nodes.push({ node: node, start: raw.length, len: node.textContent.length });
      raw += node.textContent;
    }
    return { nodes: nodes, raw: raw };
  };

  RA.locateOffset = function(map, off) {
    for (var i = 0; i < map.nodes.length; i++) {
      var e = map.nodes[i];
      if (off < e.start + e.len) return { node: e.node, offset: off - e.start };
    }
    var last = map.nodes[map.nodes.length - 1];
    return last ? { node: last.node, offset: last.len } : null;
  };

  RA.range = function(doc, map, a, b) {
    var sp = RA.locateOffset(map, a), ep = RA.locateOffset(map, b);
    if (!sp || !ep) return null;
    var r = doc.createRange();
    r.setStart(sp.node, sp.offset);
    r.setEnd(ep.node, ep.offset);
    return r;
  };

  RA.useHighlights = function(doc) {
    var win = doc && doc.defaultView;
    return !!(win && win.CSS && win.CSS.highlights && win.Highlight);
  };

  RA.unwrap = function(doc) {
    try {
      var els = doc.querySelectorAll('span.absorb-ra');
      for (var i = 0; i < els.length; i++) {
        var el = els[i], p = el.parentNode;
        if (!p) continue;
        while (el.firstChild) p.insertBefore(el.firstChild, el);
        p.removeChild(el);
      }
      if (els.length) (doc.body || doc).normalize();
    } catch (e) {}
  };

  RA.wrap = function(doc, map, a, b, cls) {
    if (b <= a) return;
    for (var i = 0; i < map.nodes.length; i++) {
      var e = map.nodes[i];
      var s0 = Math.max(a, e.start), e0 = Math.min(b, e.start + e.len);
      if (e0 <= s0) continue;
      var node = e.node;
      if (!node.parentNode) continue;
      var local = s0 - e.start, localEnd = e0 - e.start;
      var target = node;
      if (local > 0) target = target.splitText(local);
      if (localEnd - local < target.textContent.length) target.splitText(localEnd - local);
      var span = doc.createElement('span');
      span.className = cls + ' absorb-ra';
      target.parentNode.insertBefore(span, target);
      span.appendChild(target);
    }
  };

  /// Paint the current sentence, with [wordIndex] (page word, -1 for none)
  /// carrying the full color and the rest of the sentence dimmed.
  RA.paint = function(wordIndex) {
    var st = RA.cur;
    if (!st) return;
    var doc = st.doc;
    var word = (wordIndex >= 0 && st.words.length)
      ? st.words[Math.min(wordIndex, st.words.length - 1)] : null;
    if (RA.useHighlights(doc)) {
      var win = doc.defaultView, reg = win.CSS.highlights;
      var map = st.map || (st.map = RA.nodeMap(doc));
      reg.delete('absorbRaWord');
      reg.delete('absorbRaDim');
      var sentence = RA.range(doc, map, st.sStart, st.sEnd);
      if (!sentence) return;
      if (word) {
        var wr = RA.range(doc, map, word[0], word[1]);
        var dim = new win.Highlight(sentence);
        dim.priority = 1;
        reg.set('absorbRaDim', dim);
        if (wr) {
          var hi = new win.Highlight(wr);
          hi.priority = 2;
          reg.set('absorbRaWord', hi);
        }
      } else {
        var whole = new win.Highlight(sentence);
        whole.priority = 2;
        reg.set('absorbRaWord', whole);
      }
      return;
    }
    RA.unwrap(doc);
    var m2 = st.map = RA.nodeMap(doc);
    if (word) {
      RA.wrap(doc, m2, st.sStart, word[0], 'absorb-ra-dim');
      m2 = st.map = RA.nodeMap(doc);
      RA.wrap(doc, m2, word[0], word[1], 'absorb-ra-word');
      m2 = st.map = RA.nodeMap(doc);
      RA.wrap(doc, m2, word[1], st.sEnd, 'absorb-ra-dim');
    } else {
      RA.wrap(doc, m2, st.sStart, st.sEnd, 'absorb-ra-word');
    }
    st.map = null;
  };

  RA.location = function() {
    if (RA.loc) return RA.loc;
    try { RA.loc = rendition.currentLocation(); } catch (e) { RA.loc = null; }
    return RA.loc;
  };

  /// Whether [range] sits on the page currently on screen, and its CFI so the
  /// caller can turn to it when it doesn't.
  RA.visibleAt = function(range) {
    var out = { v: true };
    try {
      var cfi = RA.cur.contents.cfiFromRange(range);
      if (!cfi) return out;
      out.cfi = cfi;
      var loc = RA.location();
      if (!loc || !loc.start || !loc.end) return out;
      var cmp = new ePub.CFI();
      out.v = cmp.compare(cfi, loc.start.cfi) >= 0 &&
              cmp.compare(cfi, loc.end.cfi) <= 0;
    } catch (e) {}
    return out;
  };

  // held:false means the anchor is gone (the page turned into another
  // section) and the caller should locate the sentence again. visible:false
  // means this word is on the next page - following word by word, that is
  // where the page should turn, not at the end of the sentence.
  RA.word = function(i) {
    if (!RA.cur) return JSON.stringify({ held: false });
    if (RA.cur.painted !== i) {
      RA.cur.painted = i;
      RA.paint(i);
    }
    var out = { held: true, visible: true };
    try {
      var st = RA.cur;
      var w = (i >= 0 && st.words.length)
        ? st.words[Math.min(i, st.words.length - 1)] : null;
      if (w) {
        var map = st.map || (st.map = RA.nodeMap(st.doc));
        var r = RA.range(st.doc, map, w[0], w[1]);
        if (r) {
          var vis = RA.visibleAt(r);
          out.visible = vis.v;
          if (vis.cfi) out.cfi = vis.cfi;
        }
      }
    } catch (e) {}
    return JSON.stringify(out);
  };

  RA.clearDoc = function(doc) {
    if (!doc) return;
    try {
      if (RA.useHighlights(doc)) {
        doc.defaultView.CSS.highlights.delete('absorbRaWord');
        doc.defaultView.CSS.highlights.delete('absorbRaDim');
      }
    } catch (e) {}
    RA.unwrap(doc);
  };

  RA.clear = function() {
    var cs = RA.docs();
    for (var i = 0; i < cs.length; i++) RA.clearDoc(cs[i].document);
    RA.cur = null;
  };

  RA.start = function() {
    var cs = RA.docs();
    for (var i = 0; i < cs.length; i++) RA.style(cs[i].document);
    if (!RA.hooked) {
      RA.hooked = true;
      try {
        rendition.hooks.content.register(function(c) { RA.style(c.document); });
      } catch (e) {}
      try {
        // A page turn drops the old document; the follow mark goes with it.
        // The location is cached here because working it out costs real time
        // and the word check runs several times a second.
        rendition.on('relocated', function(loc) {
          RA.loc = loc || null;
          if (RA.cur && RA.docs().indexOf(RA.cur.contents) === -1) RA.cur = null;
        });
      } catch (e) {}
    }
  };

  RA.stop = function() {
    RA.clear();
    var cs = RA.docs();
    for (var i = 0; i < cs.length; i++) {
      try {
        var st = cs[i].document.getElementById('absorbReadAlongStyle');
        if (st && st.parentNode) st.parentNode.removeChild(st);
      } catch (e) {}
    }
  };

  /// Find [needle] in the rendered pages, snap it out to sentence bounds, and
  /// paint it. Returns whether it was found, whether it sits on the visible
  /// page, and how many words the matched span holds.
  RA.locate = function(needle, wordMode, minOffset) {
    var out = { found: false };
    try {
      var cs = RA.docs();
      for (var i = 0; i < cs.length; i++) {
        var c = cs[i], doc = c.document;
        var map = RA.nodeMap(doc);
        var raw = map.raw;
        var lower = raw.toLowerCase();
        var normChars = [], idx = [], prevSpace = true;
        for (var k = 0; k < lower.length; k++) {
          var ch = lower[k];
          if (/\\s/.test(ch)) {
            if (!prevSpace) { normChars.push(' '); idx.push(k); }
            prevSpace = true;
          } else { normChars.push(ch); idx.push(k); prevSpace = false; }
        }
        var hay = normChars.join('');
        var q = needle.toLowerCase().replace(/\\s+/g, ' ').trim();
        // A phrase can occur more than once on a page ("he said", a repeated
        // refrain). Narration only moves forward, so prefer the first
        // occurrence at or after where the last sentence was, and fall back to
        // the first one anywhere when there is nothing ahead.
        var pos = -1;
        if (typeof minOffset === 'number' && minOffset >= 0) {
          for (var sp = 0; sp < idx.length; sp++) {
            if (idx[sp] >= minOffset) { pos = hay.indexOf(q, sp); break; }
          }
        }
        if (pos === -1) pos = hay.indexOf(q);
        if (pos === -1) continue;
        var rs = idx[pos], reEnd = idx[pos + q.length - 1] + 1;
        // Snap the span to full sentence boundaries: Whisper segments cut
        // wherever they like, and mid-sentence spans read as glitches. A whole
        // sentence is also stable - consecutive segments inside one sentence
        // resolve to the same range, so the coloring holds still.
        var sStart = rs;
        for (var bk = rs - 1; bk >= 0 && rs - bk < 400; bk--) {
          var cb = raw[bk];
          if (cb === '.' || cb === '!' || cb === '?' || cb === '\\n') { sStart = bk + 1; break; }
          if (bk === 0) sStart = 0;
        }
        while (sStart < rs && /\\s/.test(raw[sStart])) sStart++;
        // End at the FIRST sentence terminator after the needle's start, so
        // the span is always exactly one sentence - even when an older cached
        // line covers several.
        var sEnd = reEnd;
        for (var f = rs; f < raw.length && f - rs < 400; f++) {
          var cf = raw[f];
          if (cf === '.' || cf === '!' || cf === '?') {
            var j2 = f + 1;
            while (j2 < raw.length && (raw[j2] === '"' || raw[j2] === "'" || raw[j2] === '”' || raw[j2] === '’')) j2++;
            sEnd = j2; break;
          }
          if (cf === '\\n') { sEnd = f; break; }
        }
        if (sEnd <= sStart) sEnd = reEnd;
        var words = [], wre = /\\S+/g, sub = raw.slice(rs, reEnd), wm;
        while ((wm = wre.exec(sub))) words.push([rs + wm.index, rs + wm.index + wm[0].length]);
        out.found = true;
        out.words = words.length;
        out.visible = true;
        out.at = sStart;
        out.sentence = raw.slice(sStart, Math.min(sEnd, sStart + 90)).replace(/\\s+/g, ' ');
        // Work the CFI out before painting: on the span fallback, painting
        // splits text nodes, and a CFI taken from that DOM would not survive
        // the unwrap.
        try {
          var r = RA.range(doc, map, sStart, sEnd);
          var cfi = r ? c.cfiFromRange(r) : null;
          out.cfi = cfi || '';
          var loc = RA.location();
          if (cfi && loc && loc.start && loc.end) {
            var cmp = new ePub.CFI();
            out.visible = cmp.compare(cfi, loc.start.cfi) >= 0 && cmp.compare(cfi, loc.end.cfi) <= 0;
          }
        } catch (e1) {}
        if (RA.cur && RA.cur.doc !== doc) RA.clearDoc(RA.cur.doc);
        RA.style(doc);
        RA.cur = { doc: doc, contents: c, sStart: sStart, sEnd: sEnd, words: words, map: map, painted: -2 };
        var first = (wordMode && words.length) ? 0 : -1;
        RA.paint(first);
        RA.cur.painted = first;
        break;
      }
    } catch (e) { out.err = String(e); }
    return JSON.stringify(out);
  };
})();
''';
}
