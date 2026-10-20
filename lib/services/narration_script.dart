import 'read_along_script.dart';

/// JavaScript for read along on a narrated EPUB: the sentence the narration
/// is on gets lit by its element id, and the reader is told whether it is on
/// the page in view so it can turn. Installed as `window.__absorbMO`.
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

  MO.css = function() {
    if (MO.eink) {
      return '.absorb-mo-on { text-decoration: underline;' +
        ' text-decoration-thickness: 2px; text-underline-offset: 3px; }';
    }
    return '.absorb-mo-on, .absorb-mo-on * { color: ' + MO.color + ' !important;' +
      ' transition: color 180ms ease; }';
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
    if (MO.cur) {
      try { MO.cur.classList.remove('absorb-mo-on'); } catch (e) {}
      MO.cur = null;
    }
  };

  // 'on' when the sentence is on the page in view ('low' when that is near
  // the bottom of a scroll), 'before' or 'after' when it is on another page
  // of the loaded section, 'missing' when its section isn't loaded.
  MO.show = function(href, id) {
    var el = MO.find(href, id);
    if (!el) { MO.clear(); return 'missing'; }
    if (MO.cur !== el) {
      MO.clear();
      MO.style(el.ownerDocument);
      el.classList.add('absorb-mo-on');
      MO.cur = el;
    }
    var vis = MO.visible(el);
    if (vis.low) return 'low';
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
