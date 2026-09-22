/// The in-page script behind read along's coloring.
///
/// epub.js annotations are an SVG overlay drawn on top of the page, so they
/// can only ever box or underline text - they cannot repaint the words
/// themselves. This wraps the current sentence in one span per word and
/// drives everything after that with CSS classes, so the tint rolls from
/// word to word and fades in on a new sentence through ordinary CSS
/// transitions instead of repainting. The spans are unwrapped again when the
/// sentence moves on, so the page ends up exactly as it started.
library;

/// Six-digit hex for an ARGB value, for CSS.
String cssHex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Installs `window.__absorbRA` in the reader page. Safe to run more than
/// once; a second run just refreshes the color.
String readAlongBootstrap(int argb,
    {bool eink = false, int fgArgb = 0xFF000000, int bgArgb = 0xFFFFFFFF}) {
  final hex = cssHex(argb);
  final r = (argb >> 16) & 0xFF, g = (argb >> 8) & 0xFF, b = argb & 0xFF;
  return '(function() {'
      'var RA = window.__absorbRA = window.__absorbRA || {};'
      "RA.color = '$hex'; RA.rgb = '$r, $g, $b';"
      "RA.eink = ${eink ? 'true' : 'false'};"
      "RA.fg = '${cssHex(fgArgb)}'; RA.bg = '${cssHex(bgArgb)}';"
      '$_body'
      '})();';
}

const String _body = r'''
  RA.cur = null;

  // Block elements: a sentence never runs past one of these, so a scene
  // divider or a heading between two sentences can't glue them together.
  RA.BLOCKS = 'p,div,h1,h2,h3,h4,h5,h6,li,blockquote,pre,td,th,dd,dt,' +
    'figcaption,section,article,aside,header,footer,tr,hr,table,figure';

  // The word's glyphs are painted from two background layers clipped to the
  // text: the dim color underneath, the full color on top. The top layer
  // grows from the left as the narration reaches the word, so the color
  // rolls through it, and stays once the word is read. The text color itself
  // is transparent so the layers show; the "in" state keeps it at the page
  // color for a frame so a fresh sentence fades into the dim tone instead
  // of snapping.
  RA.css = function() {
    var c = RA.color, rgb = RA.rgb;
    var dim = 'rgba(' + rgb + ', 0.8)';
    // E-ink shows a colored roll as a grey smear, and every repaint costs a
    // flash, so the sentence gets one underline and nothing else changes.
    // Bold is out too: it reflows the line and the whole paragraph redraws.
    if (RA.eink) {
      return '' +
        '.absorb-ra-w, .absorb-ra-s { text-decoration: underline;' +
        ' text-decoration-thickness: 2px; text-underline-offset: 3px; }';
    }
    return '' +
      '.absorb-ra-w { color: transparent !important;' +
      ' background-image: linear-gradient(' + c + ', ' + c + '),' +
      ' linear-gradient(' + dim + ', ' + dim + ');' +
      ' background-size: 0% 100%, 100% 100%; background-repeat: no-repeat;' +
      ' background-position: 0 0, 0 0;' +
      ' -webkit-background-clip: text; background-clip: text;' +
      ' box-decoration-break: clone; -webkit-box-decoration-break: clone;' +
      ' transition: background-size 220ms ease-out, color 180ms ease; }' +
      '.absorb-ra-w.absorb-ra-on, .absorb-ra-w.absorb-ra-done {' +
      ' background-size: 100% 100%, 100% 100%; }' +
      '.absorb-ra-s { color: ' + c + ' !important;' +
      ' transition: color 180ms ease; }' +
      '.absorb-ra-w.absorb-ra-in, .absorb-ra-s.absorb-ra-in {' +
      ' color: inherit !important; }';
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
    var m = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(hex);
    if (m) {
      RA.rgb = parseInt(m[1], 16) + ', ' + parseInt(m[2], 16) + ', ' + parseInt(m[3], 16);
    }
    var cs = RA.docs();
    for (var i = 0; i < cs.length; i++) RA.style(cs[i].document);
  };

  // Char offset -> text node map for a page document. A virtual newline is
  // put into the raw text wherever the block element changes, so sentence
  // bounds stop at paragraph edges; those newlines belong to no node. The
  // raw text never changes when spans are added, so offsets stay valid
  // across rebuilds.
  RA.nodeMap = function(doc) {
    var tw = doc.createTreeWalker(doc.body || doc, NodeFilter.SHOW_TEXT, null, false);
    var nodes = [], raw = '', node, prevBlock = null;
    while (node = tw.nextNode()) {
      var pe = node.parentElement;
      if (pe) {
        var tag = pe.tagName ? pe.tagName.toLowerCase() : '';
        if (tag === 'script' || tag === 'style') continue;
      }
      var block = null;
      try { block = pe ? pe.closest(RA.BLOCKS) : null; } catch (e) {}
      if (raw.length && block !== prevBlock) raw += '\n';
      prevBlock = block;
      nodes.push({ node: node, start: raw.length, len: node.textContent.length });
      raw += node.textContent;
    }
    return { nodes: nodes, raw: raw };
  };

  RA.locateOffset = function(map, off) {
    for (var i = 0; i < map.nodes.length; i++) {
      var e = map.nodes[i];
      if (off < e.start) return { node: e.node, offset: 0 };
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

  RA.unwrapSpans = function(spans) {
    var parents = [];
    for (var i = 0; i < spans.length; i++) {
      var el = spans[i], p = el.parentNode;
      if (!p) continue;
      while (el.firstChild) p.insertBefore(el.firstChild, el);
      p.removeChild(el);
      if (parents.indexOf(p) === -1) parents.push(p);
    }
    for (var k = 0; k < parents.length; k++) {
      try { parents[k].normalize(); } catch (e) {}
    }
  };

  RA.unwrap = function(doc) {
    try {
      var els = doc.querySelectorAll('span.absorb-ra');
      var list = [];
      for (var i = 0; i < els.length; i++) list.push(els[i]);
      RA.unwrapSpans(list);
    } catch (e) {}
  };

  // Wrap [a, b) of the raw text in spans of class [cls]. Works from the last
  // text node backwards, so the offsets of anything earlier in the same node
  // stay valid without rebuilding the map - splitText keeps the head of the
  // node in place.
  RA.wrap = function(doc, map, a, b, cls) {
    var made = [];
    if (b <= a) return made;
    for (var i = map.nodes.length - 1; i >= 0; i--) {
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
      span.className = cls + ' absorb-ra absorb-ra-in';
      target.parentNode.insertBefore(span, target);
      span.appendChild(target);
      made.push(span);
    }
    return made.reverse();
  };

  RA.setState = function(spans, cls) {
    for (var i = 0; i < spans.length; i++) {
      var el = spans[i];
      el.classList.remove('absorb-ra-on');
      el.classList.remove('absorb-ra-done');
      if (cls) el.classList.add(cls);
    }
  };

  /// Paint [wordIndex] (needle word, -1 for none) as the word being heard:
  /// earlier words in the sentence settle to full color, the current one
  /// fills, the rest stay dimmed.
  RA.paint = function(wordIndex) {
    var st = RA.cur;
    if (!st || !st.spans) return;
    if (!st.words.length) return;
    var j = wordIndex >= 0 ? Math.min(wordIndex + st.first, st.spans.length - 1) : -1;
    for (var k = 0; k < st.spans.length; k++) {
      RA.setState(st.spans[k], k < j ? 'absorb-ra-done' : (k === j ? 'absorb-ra-on' : null));
    }
  };

  // A sentence ends at . ! or ? only when what follows (after any closing
  // quotes or brackets) is whitespace or the end of the block - so "£8.99",
  // "e.g." and "U.S." stay inside one sentence.
  RA.isTerm = function(raw, i) {
    var ch = raw[i];
    if (ch !== '.' && ch !== '!' && ch !== '?') return false;
    var j = i + 1;
    while (j < raw.length && '"\'”’)]'.indexOf(raw[j]) !== -1) j++;
    return j >= raw.length || /\s/.test(raw[j]);
  };

  /// Whether [el] is on the page currently on screen, judged by where it
  /// sits in the iframe's viewport rather than by CFI arithmetic - the spans
  /// change the DOM under epub.js's own location CFIs, so those two never
  /// quite agree. dir is -1 when it lies before the page, 1 after. Paginated
  /// flow lays pages out sideways, scrolled flow downwards; whichever axis
  /// the page actually overflows on decides.
  RA.visibleEl = function(el) {
    var out = { v: true, dir: 0 };
    try {
      if (!el) return out;
      var doc = el.ownerDocument, win = doc.defaultView;
      var rect = el.getBoundingClientRect();
      if (!rect || (rect.width === 0 && rect.height === 0)) return out;
      // The section's iframe holds every page of the section side by side
      // (or the whole scroll), so a rect inside it says nothing on its own.
      // Offset by where the iframe sits in the reader page and judge
      // against the reader's viewport, which is what is actually on screen.
      var fe = win.frameElement;
      var fr = fe ? fe.getBoundingClientRect() : { left: 0, top: 0 };
      var W = window.innerWidth, H = window.innerHeight;
      var flow = '';
      try { flow = (rendition.settings && rendition.settings.flow) || ''; } catch (e0) {}
      var sideways = flow.indexOf('scrolled') === -1;
      if (sideways) {
        var mid = fr.left + (rect.left + rect.right) / 2;
        out.v = mid >= 0 && mid < W;
        out.dir = mid < 0 ? -1 : (mid >= W ? 1 : 0);
        out.x = Math.round(mid); out.w = W;
      } else {
        var midY = fr.top + (rect.top + rect.bottom) / 2;
        out.v = midY >= 0 && midY < H;
        out.dir = midY < 0 ? -1 : (midY >= H ? 1 : 0);
        out.x = Math.round(midY); out.w = H;
      }
    } catch (e) {}
    return out;
  };

  /// A CFI for the DOM as it is right now, spans included. It is only ever
  /// handed straight back to rendition.display(), which resolves it against
  /// the same DOM, so the spans being in the path is what makes it right.
  RA.cfiFor = function(c, firstEl, lastEl) {
    try {
      var r = firstEl.ownerDocument.createRange();
      r.setStartBefore(firstEl);
      r.setEndAfter(lastEl || firstEl);
      return c.cfiFromRange(r) || '';
    } catch (e) { return ''; }
  };

  // held:false means the anchor is gone (the page turned into another
  // section) and the caller should locate the sentence again. visible:false
  // means this word is on another page, dir says which way.
  RA.word = function(i) {
    if (!RA.cur) return JSON.stringify({ held: false });
    if (RA.cur.painted !== i) {
      RA.cur.painted = i;
      RA.paint(i);
    }
    var out = { held: true, visible: true, dir: 0 };
    try {
      var st = RA.cur;
      var j = (i >= 0 && st.spans.length) ? Math.min(i + st.first, st.spans.length - 1) : -1;
      var group = j >= 0 ? st.spans[j] : null;
      if (group && group.length) {
        if (!group[0].isConnected) return JSON.stringify({ held: false });
        var vis = RA.visibleEl(group[0]);
        out.visible = vis.v;
        out.dir = vis.dir;
        out.x = vis.x; out.w = vis.w;
        if (!vis.v) out.cfi = RA.cfiFor(st.contents, group[0], group[group.length - 1]);
      }
    } catch (e) {}
    return JSON.stringify(out);
  };

  RA.clearDoc = function(doc) {
    if (!doc) return;
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
  /// page (and which way it lies otherwise), and how many words the matched
  /// span holds.
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
          if (/\s/.test(ch)) {
            if (!prevSpace) { normChars.push(' '); idx.push(k); }
            prevSpace = true;
          } else { normChars.push(ch); idx.push(k); prevSpace = false; }
        }
        var hay = normChars.join('');
        var q = needle.toLowerCase().replace(/\s+/g, ' ').trim();
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
        // resolve to the same range, so the coloring holds still. A paragraph
        // edge (virtual newline) is always a boundary.
        var sStart = rs;
        for (var bk = rs - 1; bk >= 0 && rs - bk < 400; bk--) {
          if (raw[bk] === '\n' || RA.isTerm(raw, bk)) { sStart = bk + 1; break; }
          if (bk === 0) sStart = 0;
        }
        while (sStart < rs && (/\s/.test(raw[sStart]) || '"\'”’)]'.indexOf(raw[sStart]) !== -1)) sStart++;
        // End at the FIRST sentence terminator after the needle's start, so
        // the span is always exactly one sentence - even when an older cached
        // line covers several.
        var sEnd = reEnd;
        for (var f = rs; f < raw.length && f - rs < 400; f++) {
          if (RA.isTerm(raw, f)) {
            var j2 = f + 1;
            while (j2 < raw.length && '"\'”’)]'.indexOf(raw[j2]) !== -1) j2++;
            sEnd = j2; break;
          }
          if (raw[f] === '\n') { sEnd = f; break; }
        }
        if (sEnd <= sStart) sEnd = reEnd;
        // Every word of the sentence gets a span; the needle's words are the
        // ones the narration walks, starting at [first].
        var words = [], wre = /\S+/g, sub = raw.slice(sStart, sEnd), wm;
        while ((wm = wre.exec(sub))) words.push([sStart + wm.index, sStart + wm.index + wm[0].length]);
        var first = 0, count = 0;
        for (var wi = 0; wi < words.length; wi++) {
          if (words[wi][1] <= rs) first = wi + 1;
          if (words[wi][0] < reEnd && words[wi][1] > rs) count++;
        }
        if (first >= words.length) first = Math.max(0, words.length - 1);
        if (count <= 0) count = Math.max(1, words.length - first);
        out.found = true;
        out.words = count;
        out.visible = true;
        out.dir = 0;
        out.at = sStart;
        out.si = c.sectionIndex;
        out.sentence = raw.slice(sStart, Math.min(sEnd, sStart + 90)).replace(/\s+/g, ' ');
        // The old sentence only goes once the new one is found, so a miss
        // leaves the last sentence lit. Unwrapping merges text nodes, so the
        // map is rebuilt before wrapping; the raw text and every offset in
        // it are unchanged.
        if (RA.cur) {
          RA.clearDoc(RA.cur.doc);
          RA.cur = null;
          map = RA.nodeMap(doc);
        }
        RA.style(doc);
        var spans = [];
        if (wordMode && words.length) {
          for (var wk = words.length - 1; wk >= 0; wk--) {
            spans[wk] = RA.wrap(doc, map, words[wk][0], words[wk][1], 'absorb-ra-w');
          }
        } else {
          spans = [RA.wrap(doc, map, sStart, sEnd, 'absorb-ra-s')];
          words = [[sStart, sEnd]];
          first = 0;
        }
        RA.cur = { doc: doc, contents: c, sStart: sStart, sEnd: sEnd, words: words,
                   first: first, spans: spans, painted: -2 };
        // Where the sentence sits is judged from the spans themselves, now
        // that they are in the page.
        try {
          var flat = [];
          for (var fa = 0; fa < spans.length; fa++) {
            for (var fb = 0; fb < spans[fa].length; fb++) flat.push(spans[fa][fb]);
          }
          if (flat.length) {
            var vis = RA.visibleEl(flat[0]);
            out.visible = vis.v;
            out.dir = vis.dir;
            out.cfi = vis.v ? '' : RA.cfiFor(c, flat[0], flat[flat.length - 1]);
          }
        } catch (e1) {}
        var start = (wordMode && count) ? 0 : -1;
        RA.paint(start);
        RA.cur.painted = start;
        // The spans arrive in their "in" state (page color); dropping it on
        // the next frame lets the tint fade in rather than snap.
        // Scheduled on the reader page, never on the book's own frame: the
        // book sits in a sandboxed iframe with scripting off, and WebKit on
        // newer iOS does not run frame callbacks for such a document. The
        // spans then kept the page color for good - pages turned, nothing
        // was ever tinted. The timer covers a frame callback that is paused.
        var fresh = spans;
        var dropped = false;
        var dropIn = function() {
          if (dropped) return;
          dropped = true;
          for (var a = 0; a < fresh.length; a++) {
            for (var b2 = 0; b2 < fresh[a].length; b2++) fresh[a][b2].classList.remove('absorb-ra-in');
          }
        };
        try { window.requestAnimationFrame(dropIn); } catch (e2) {}
        setTimeout(dropIn, 60);
        break;
      }
    } catch (e) { out.err = String(e); }
    return JSON.stringify(out);
  };
''';
