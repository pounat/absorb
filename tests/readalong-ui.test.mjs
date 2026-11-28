import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';
const read=p=>fs.readFileSync(new URL('../'+p,import.meta.url),'utf8');
test('BookOrbit web routes prepared EPUBs into a script-disabled in-app reader',()=>{assert.match(read('lib/widgets/ebook_router.dart'),/BookOrbitReadAlongView/);assert.match(read('web/index.html'),/readalong\.js/);assert.match(read('lib/widgets/bookorbit_readalong_web.dart'),/absolutePosition|player\.position/);});
