// SYNTHETIC upstream only. Real BFF listener; no installed ABS or real credentials.
import http from 'node:http';
import { createApp } from '../../server/app.mjs';

const calls = [];
const envelope = (rotated = false) => ({user: {
  id: 'synthetic-reader', username: 'synthetic', mediaProgress: [],
  accessToken: rotated ? 'synthetic-access-next' : 'synthetic-access',
  refreshToken: rotated ? 'synthetic-refresh-next' : 'synthetic-refresh',
}});
const upstream = http.createServer(async (req, res) => {
  let raw = '';
  for await (const chunk of req) raw += chunk;
  calls.push({path: req.url, method: req.method, body: raw ? JSON.parse(raw) : null,
    refreshToken: req.headers['x-refresh-token']});
  res.setHeader('Content-Type', 'application/json');
  if (req.url === '/login') return res.end(JSON.stringify(envelope()));
  if (req.url === '/auth/refresh') return res.end(JSON.stringify(envelope(true)));
  if (req.url === '/logout') return res.end('{}');
  if (req.url === '/api/me') return res.end(JSON.stringify(envelope().user));
  // Deliberate read failure, never an absent-progress 404.
  if (req.url === '/api/me/progress/synthetic-book') {
    return res.writeHead(503).end('{"error":"synthetic_read_failure"}');
  }
  if (req.url === '/api/libraries') return res.end('{"libraries":[{"id":"synthetic-lib"}]}');
  if (req.url.startsWith('/api/libraries/synthetic-lib/items')) {
    return res.end('{"results":[{"id":"synthetic-book","media":{}}],"total":1}');
  }
  if (req.url === '/api/items/synthetic-book/play') return res.end(JSON.stringify({
    id: 'synthetic-play', userId: 'synthetic-reader', libraryItemId: 'synthetic-book',
    duration: 100, audioTracks: [{index: 0, mimeType: 'audio/mpeg',
      contentUrl: '/public/session/synthetic-play/track/0'}],
  }));
  if (/^\/api\/session\/synthetic-play\/(sync|close)$/.test(req.url)) return res.end('OK');
  res.writeHead(404).end('{}');
});
await new Promise(resolve => upstream.listen(0, '127.0.0.1', resolve));
const port = Number(process.env.SYNTHETIC_BFF_PORT || 39871);
const origin = `http://127.0.0.1:${port}`;
const app = createApp({upstream: `http://127.0.0.1:${upstream.address().port}`,
  origins: ['https://synthetic.example'], secureCookie: false});
const bff = http.createServer((req, res) => {
  if (req.url === '/__synthetic_receipt') {
    res.setHeader('Content-Type', 'application/json');
    return res.end(JSON.stringify(calls));
  }
  return app(req, res);
});
await new Promise(resolve => bff.listen(port, '127.0.0.1', resolve));
console.log(`SYNTHETIC_BFF_READY=${origin}`);
async function shutdown() {
  app.dispose();
  bff.closeAllConnections(); upstream.closeAllConnections();
  await Promise.all([new Promise(resolve => bff.close(resolve)),
    new Promise(resolve => upstream.close(resolve))]);
}
process.once('SIGTERM', shutdown);
process.once('SIGINT', shutdown);
