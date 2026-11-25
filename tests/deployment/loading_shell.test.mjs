import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';
const html = readFileSync(new URL('../../web/index.html', import.meta.url), 'utf8');
test('the production CSP authorizes exactly the current inline loader', () => {
  const conf = readFileSync(new URL('../../deploy/nginx/web.conf', import.meta.url), 'utf8');
  const hash = createHash('sha256').update(html.match(/<script>([\s\S]*?)<\/script>/)[1]).digest('base64');
  assert(conf.includes("'sha256-" + hash + "'"));
  assert(!/script-src[^;]*'unsafe-inline'/.test(conf));
});
function boot() {
  const handlers = new Map(), timers = new Map(), classes = new Set();
  const label = {textContent: 'Loading Absorb'}, help = {textContent: ''};
  const shell = {classList: {add: x => classes.add(x)}, querySelector: s => s === '.absorb-loading-label' ? label : s === '.absorb-loading-help p' ? help : {addEventListener() {}}, remove() {this.removed = true;}};
  class HTMLScriptElement {constructor(src) {this.src = src;}}
  const window = {location: {href: 'https://example.test/absorb/', origin: 'https://example.test', reload() {}}, setTimeout: f => {timers.set(1, f); return 1;}, clearTimeout: id => timers.delete(id), addEventListener: (n, f) => handlers.set(n, f), removeEventListener: n => handlers.delete(n)};
  vm.runInNewContext(html.match(/<script>([\s\S]*?)<\/script>/)[1], {window, document: {getElementById: () => shell, baseURI: window.location.href}, URL, HTMLScriptElement});
  return {shell, classes, label, help, slow: () => {for (const f of timers.values()) f();}, fail: src => handlers.get('error')?.({target: new HTMLScriptElement(src)}), frame: () => handlers.get('flutter-first-frame')(), timers};
}
test('unrelated scripts cannot replace loading with a failure', () => {
  const b = boot(); b.fail('https://example.test/absorb/optional.js');
  assert(!b.classes.has('is-stalled')); b.slow(); assert(b.classes.has('is-slow'));
});
test('required script failures show bounded recovery and cancel the slow timer', () => {
  for (const file of ['flutter_bootstrap.js', 'main.dart.js', 'canvaskit/canvaskit.js', 'canvaskit/skwasm.js']) {
    const b = boot(); b.fail('https://example.test/absorb/' + file + '?private-query');
    assert(b.classes.has('is-stalled')); assert.equal(b.timers.size, 0);
    assert.match(b.help.textContent, /required app script failed/i);
    assert(!b.help.textContent.includes('private-query')); assert.match(b.help.textContent, /Reload/);
  }
});
test('foreign scripts and paths outside the app are ignored', () => {
  for (const url of ['https://other.test/absorb/main.dart.js', 'https://example.test/main.dart.js']) {
    const b = boot(); b.fail(url); assert(!b.classes.has('is-stalled'));
  }
});
test('first frame after slow startup removes the shell and listeners', () => {
  const b = boot(); b.slow(); b.frame(); assert(b.shell.removed);
  assert.equal(b.timers.size, 0); b.fail('https://example.test/absorb/main.dart.js');
  assert(!b.classes.has('is-stalled'));
});
test('reduced motion keeps a static loading indicator', () => {
  assert.match(html, /@media \(prefers-reduced-motion: reduce\)[\s\S]*?\.absorb-loading-spinner \{ animation: none;/);
});
test('a slow startup remains loading, not an invented server failure', () => {
  const b = boot(); b.slow();
  assert(b.classes.has('is-slow')); assert(!b.classes.has('is-stalled'));
  assert.match(b.label.textContent, /still loading/i);
});
