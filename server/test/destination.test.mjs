import test from 'node:test';
import assert from 'node:assert/strict';
import { selectUpstream, publicAddress } from '../destination.mjs';
import { transport } from '../upstream.mjs';
import http from 'node:http';
test('typed URL policy rejects ambiguous authorities, unsafe syntax and nonpublic destinations', () => {
  for (const value of ['', 'ftp://shelf.example.test', 'https://u:p@shelf.example.test', 'https://shelf.example.test/?q=1', 'https://shelf.example.test/#x', 'https://shelf.example.test/%2e', 'https://shelf.example.test/../abs', 'https://shelf.example.test\\x', 'http://shelf.example.test', 'https://127.1', 'https://2130706433', 'https://0x7f000001', 'https://10.0.0.1', 'https://169.254.169.254', 'https://[::1]', 'https://[::ffff:127.0.0.1]', 'https://[::ffff:a9fe:a9fe]', 'https://[fc00::1]', 'https://[fe80::1]', 'https://[ff02::1]']) {
    assert.throws(() => selectUpstream(value, {}), undefined, value);
  }
  assert.equal(selectUpstream('https://shelf.example.test/base///', {}).href, 'https://shelf.example.test/base');
  assert.throws(() => selectUpstream('http://shelf.example.test', {allowHttp: true}));
  assert.throws(() => selectUpstream('http://shelf.example.test', {allowedUpstreams: ['http://shelf.example.test']}));
  assert.throws(() => selectUpstream('https://127.0.0.1', {allowedUpstreams: ['https://127.0.0.1:8443']}));
});
test('public address policy excludes special IPv4 and IPv6 ranges', () => {
  for (const value of ['https://134744072', 'https://010.010.010.010', 'https:8.8.8.8', 'https://8.8.8.8\u0000']) assert.throws(()=>selectUpstream(value,{}));
  for (const ip of ['0.0.0.0','100.64.0.1','192.0.2.1','192.88.99.1','198.18.0.1','198.51.100.1','203.0.113.1','224.0.0.1','255.255.255.255','::ffff:808:808','64:ff9b::808:808','2001:db8::1','2002::1','3fff::1']) assert.equal(publicAddress(ip), false, ip);
  assert.equal(publicAddress('8.8.8.8'), true);
  assert.equal(publicAddress('2606:4700::1111'), true);
});
test('explicit operator policy still cannot grant metadata and link-local destinations', async () => {
  for (const ip of ['169.254.169.254', '100.100.100.200', 'fd00:ec2::254', '::ffff:a9fe:a9fe', 'fe80::1']) {
    const host = ip.includes(':') ? `[${ip}]` : ip;
    const url = `https://${host}`;
    const call = transport(new URL(url), {selected:true, allowedUpstreams:[url]});
    await assert.rejects(call('/login'), /upstream_destination_denied/);
  }
});
test('upstream JSON is bounded without buffering arbitrary response bytes', async t => {
  const server = http.createServer((_req,res) => { res.writeHead(200); res.end('"' + 'x'.repeat(8 * 1024 * 1024) + '"'); });
  await new Promise(r=>server.listen(0,'127.0.0.1',r));
  t.after(()=>{server.closeAllConnections();server.close();});
  const response = await transport(new URL(`http://127.0.0.1:${server.address().port}`))('/login');
  await assert.rejects(response.json(), /upstream_json_too_large/);
});
test('DNS rejects mixed public/private answers before transmitting credentials', async () => {
  const call = transport(new URL('https://shelf.example.test'), {selected: true, resolve: async () => [{address: '8.8.8.8', family: 4}, {address: '127.0.0.1', family: 4}]});
  await assert.rejects(call('/login', {method:'POST', body:'synthetic'}), /upstream_destination_denied/);
});
test('DNS is pinned for the session and redirects never transmit credentials to their target', async t => {
  let resolutions = 0, received = 0;
  const server = http.createServer((req,res) => { received++; res.writeHead(302, {Location:'http://169.254.169.254/'}); res.end(); });
  await new Promise(r => server.listen(0,'127.0.0.1',r));
  t.after(() => {server.closeAllConnections(); server.close();});
  const url = `http://shelf.example.test:${server.address().port}`;
  const call = transport(new URL(url), {selected:true, allowedUpstreams:[url], allowHttp:true, resolve: async () => {
    resolutions++; return [{address: resolutions === 1 ? '127.0.0.1' : '169.254.169.254', family:4}];
  }});
  for (let i=0;i<2;i++) await assert.rejects(call('/login',{method:'POST',body:'synthetic'}), /upstream_redirect_denied/);
  assert.equal(resolutions,1); assert.equal(received,2);
});
