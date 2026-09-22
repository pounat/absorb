// Usage: npm install opentype.js@1.3.4 (anywhere), then
//   node scripts/gen_speed_badges.js android/app/src/main/res/drawable 3.05 5.0
// Rates step by 0.05 from the first to the second argument.
// Regenerates the Android Auto speed badges (ic_speed_<rate>x.xml) from
// Roboto Bold. Fits the scale and offsets so the output matches the badges
// already in the repo: digit tops at y=8, bottom overshoot at y=81, 8 units
// of side padding, viewport height 89, 24dp tall.
const fs = require('fs');
const path = require('path');
const opentype = require('opentype.js');

const font = opentype.loadSync('C:/Flutter/bin/cache/artifacts/material_fonts/roboto-bold.ttf');
const outDir = process.argv[2];
const from = parseFloat(process.argv[3]);
const to = parseFloat(process.argv[4]);

function label(rate) {
  return rate.toFixed(2).replace(/0+$/, '').replace(/\.$/, '') + 'x';
}
function fileName(rate) {
  return 'ic_speed_' + label(rate).replace('.', '_') + '.xml';
}

// Calibrate on "3x": the existing file spans y 8..81 for the digit.
const probe = font.getPath('3x', 0, 0, 100, { kerning: true });
const pb = probe.getBoundingBox();
const scale = (81 - 8) / (pb.y2 - pb.y1);
const fontSize = 100 * scale;
const yShift = 8 - pb.y1 * scale;

function fmt(n) {
  const s = n.toFixed(1);
  return s.endsWith('.0') ? s.slice(0, -2) : s;
}

function render(rate) {
  const text = label(rate);
  const p = font.getPath(text, 0, 0, fontSize, { kerning: true });
  const bb = p.getBoundingBox();
  const xShift = 8 - bb.x1;
  const parts = [];
  let cx = null, cy = null, sx = null, sy = null;
  for (const c of p.commands) {
    if (c.type === 'M') { sx = c.x; sy = c.y; }
    if (c.type === 'L') {
      // opentype emits a zero-length line after every curve and a closing
      // line back to the start; the checked-in badges carry neither.
      const back = sx !== null && Math.abs(c.x - sx) < 0.01 && Math.abs(c.y - sy) < 0.01;
      const still = cx !== null && Math.abs(c.x - cx) < 0.01 && Math.abs(c.y - cy) < 0.01;
      if (still || back) { cx = c.x; cy = c.y; continue; }
    }
    if (c.type !== 'Z') { cx = c.x; cy = c.y; }
    if (c.type === 'M' || c.type === 'L') {
      parts.push(c.type + fmt(c.x + xShift) + ' ' + fmt(c.y + yShift));
    } else if (c.type === 'Q') {
      parts.push('Q' + fmt(c.x1 + xShift) + ' ' + fmt(c.y1 + yShift) + ' ' + fmt(c.x + xShift) + ' ' + fmt(c.y + yShift));
    } else if (c.type === 'C') {
      parts.push('C' + fmt(c.x1 + xShift) + ' ' + fmt(c.y1 + yShift) + ' ' + fmt(c.x2 + xShift) + ' ' + fmt(c.y2 + yShift) + ' ' + fmt(c.x + xShift) + ' ' + fmt(c.y + yShift));
    }
    // Z dropped, matching the checked-in badges; fills close implicitly.
  }
  const viewportWidth = Math.round(bb.x2 - bb.x1 + 16);
  const dp = (viewportWidth * 24 / 89).toFixed(1);
  return `<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="${dp}dp"
    android:height="24dp"
    android:viewportWidth="${viewportWidth}"
    android:viewportHeight="89">
  <path android:fillColor="@android:color/white"
      android:pathData="${parts.join('')}"/>
</vector>
`;
}

let n = 0;
for (let r = Math.round(from * 20); r <= Math.round(to * 20); r++) {
  const rate = r / 20;
  fs.writeFileSync(path.join(outDir, fileName(rate)), render(rate));
  n++;
}
console.log('wrote', n, 'badges to', outDir);
