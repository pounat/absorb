// Synthetic upstreams only. Run via the browser test, never as a deployment.
import http from 'node:http';
import https from 'node:https';
import fs from 'node:fs';
import path from 'node:path';
import { createApp } from '../app.mjs';
const root = path.resolve('build/web');
const receipts = [[], []];
const upstreams = [];
for (let i = 0; i < 2; i++) {
  const server = http.createServer(async (req, res) => {
    let raw = ''; for await (const c of req) raw += c;
    const body = raw ? JSON.parse(raw) : {};
    receipts[i].push({path:req.url, method:req.method, correctLogin: body.username === 'synthetic' && body.password === 'synthetic-password', correctToken: req.headers.authorization === `Bearer synthetic-access-${i}`});
    const user = {id:'reader', username:`reader-${i}`, accessToken:`synthetic-access-${i}`, refreshToken:`synthetic-refresh-${i}`, permissions:{accessAllLibraries:true}, librariesAccessible:[]};
    res.setHeader('Content-Type','application/json');
    const route = req.url.split('?')[0].replace(/^\/abs/,'');
    if (route === '/login' || route === '/auth/refresh') return res.end(JSON.stringify({user,userDefaultLibraryId:'lib',serverSettings:{version:'2.36.0'}}));
    if (route === '/api/me') return res.end(JSON.stringify(user));
    if (route === '/api/libraries') return res.end(JSON.stringify({libraries:[{id:'lib',name:`Synthetic ${i}`,mediaType:'book',displayOrder:0}]}));
    if (route === '/api/libraries/lib/items') return res.end(JSON.stringify({results:[{id:'item',libraryId:'lib',mediaType:'book',media:{metadata:{title:'Synthetic audio',authors:[]},duration:30}}],total:1,limit:100,page:0}));
    if (route === '/api/items/item') return res.end(JSON.stringify({id:'item',libraryId:'lib',mediaType:'book',media:{metadata:{title:'Synthetic audio'},duration:30}}));
    if (route === '/api/items/item/play') return res.end(JSON.stringify({id:'shared-session',userId:'reader',libraryItemId:'item',duration:30,audioTracks:[{index:0,mimeType:'audio/mpeg',contentUrl:'/public/session/shared-session/track/0'}]}));
    if (route === '/public/session/shared-session/track/0') {res.setHeader('Content-Type','audio/mpeg'); return res.end(`synthetic-media-${i}`);}
    if (route === '/api/me/progress/item') return res.end(JSON.stringify({id:'progress',libraryItemId:'item',currentTime:i,duration:30}));
    if (route === '/api/session/shared-session') return res.end(JSON.stringify({id:'shared-session',userId:'reader',libraryItemId:'item'}));
    if (route.startsWith('/api/session/') || route === '/logout') return res.end('{}');
    if (route === '/api/libraries/lib/personalized') return res.end('[]');
    res.statusCode=404; res.end('{}');
  });
  await new Promise(r => server.listen(0,'127.0.0.1',r));
  upstreams.push(server);
}
let app;
const server = https.createServer({key:fs.readFileSync(process.argv[2]),cert:fs.readFileSync(process.argv[3])},(req,res) => {
  const policy = fs.readFileSync('deploy/nginx/web.conf','utf8').match(/add_header Content-Security-Policy "([^"]+)"/)[1];
  res.setHeader('Content-Security-Policy',policy);
  res.setHeader('Referrer-Policy','no-referrer');
  if (req.url === '/') {res.writeHead(302,{Location:'/absorb/'});res.end();return;}
  if (req.url === '/synthetic-receipts') {res.setHeader('Content-Type','application/json');res.end(JSON.stringify(receipts));return;}
  if (/^\/(?:sessions\/|api\/|public\/|login$|logout$|auth\/|ping$|status$)/.test(req.url)) return app(req,res);
  const staticPath = req.url.split('?')[0].replace(/^\/absorb/, '') || '/';
  const name = path.resolve(root, '.' + decodeURIComponent(staticPath === '/' ? '/index.html' : staticPath));
  if (!name.startsWith(root + '/')) {res.writeHead(404);res.end();return;}
  const type = {'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.ttf':'font/ttf','.otf':'font/otf'}[path.extname(name)] ?? 'application/octet-stream';
  res.setHeader('Content-Type',type);
  fs.createReadStream(name).on('error',()=>{res.statusCode=404;res.end();}).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const origin = `https://localhost:${server.address().port}`;
const urls = upstreams.map(s=>`http://127.0.0.1:${s.address().port}/abs`);
app = createApp({origins:[origin],allowedUpstreams:urls,allowHttp:true});
console.log(JSON.stringify({origin,urls}));
process.on('SIGTERM',async()=>{await app.dispose();server.closeAllConnections();server.close();for(const s of upstreams){s.closeAllConnections();s.close();}});
