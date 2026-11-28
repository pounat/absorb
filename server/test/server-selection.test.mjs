import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { createApp } from '../app.mjs';
const origin = 'https://client.example.test';
async function listen(handler) {
  const server = http.createServer(handler);
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  return { url: `http://127.0.0.1:${server.address().port}`, close: async () => {
    server.closeAllConnections(); await new Promise(r => server.close(r));
  }};
}
test('typed base URLs select immutable isolated cookie sessions, including refresh and logout', async t => {
  const receipts = [[], []]; const servers = [];
  for (let i = 0; i < 2; i++) {
    servers.push(await listen(async (req, res) => {
      let body = ''; for await (const chunk of req) body += chunk;
      receipts[i].push({ path: req.url, authorization: req.headers.authorization, body });
      const user = { id: 'same-user', username: `reader-${i}`, accessToken: `synthetic-access-${i}`, refreshToken: `synthetic-refresh-${i}` };
      res.setHeader('Content-Type', 'application/json');
      if (req.url === '/abs/login' || req.url === '/abs/auth/refresh') res.end(JSON.stringify({user}));
      else if (req.url === '/abs/api/me') res.end(JSON.stringify(user));
      else if (req.url === '/abs/logout') res.end('{}');
      else { res.statusCode = 404; res.end('{}'); }
    }));
  }
  t.after(async () => { for (const s of servers) await s.close(); });
  const app = createApp({ origins: [origin], allowedUpstreams: servers.map(s => s.url), allowHttp: true });
  const bff = await listen(app);
  t.after(async () => { await app.dispose(); await bff.close(); for (const s of servers) await s.close(); });
  const request = (path, cookie, body) => fetch(bff.url + path, {
    method: body ? 'POST' : 'GET', headers: {Origin: origin, ...(cookie ? {Cookie: cookie} : {}), ...(body ? {'Content-Type': 'application/json'} : {})},
    ...(body ? {body: JSON.stringify(body)} : {})
  });
  const denied = await request('/login', null, {serverUrl:'https://169.254.169.254',username:'synthetic',password:'synthetic-password'});
  assert.equal(denied.status,400);
  assert.equal(receipts.flat().length,0);
  const cookies = [];
  for (const s of servers) {
    const r = await request('/login', null, {serverUrl: s.url + '/abs///', username: 'synthetic', password: 'synthetic-password'});
    assert.equal(r.status, 200); assert.match(r.headers.get('set-cookie'), /HttpOnly.*Secure/);
    cookies.push(r.headers.get('set-cookie').split(';')[0]);
    assert.equal((await r.json()).user.accessToken, 'browser-cookie');
  }
  for (let i = 0; i < 2; i++) {
    assert.equal((await (await request('/api/me', cookies[i])).json()).username, `reader-${i}`);
    assert.equal((await request('/auth/refresh', cookies[i], {})).status, 200);
    assert.equal((await request('/logout', cookies[i], {})).status, 200);
    assert.equal((await request('/api/me', cookies[i])).status, 401);
    assert.ok(receipts[i].some(r => r.path === '/abs/logout'));
    assert.ok(receipts[i].filter(r => r.authorization).every(r => r.authorization === `Bearer synthetic-access-${i}`));
    assert.ok(receipts[i].filter(r => r.path !== '/abs/login').every(r => !r.body.includes('synthetic-password')));
  }
});
