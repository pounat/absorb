import test from 'node:test';import assert from 'node:assert/strict';import http from 'node:http';import {createBookOrbitApp} from '../bookorbit.mjs';
const listen=async h=>{const s=http.createServer(h);await new Promise(r=>s.listen(0,'127.0.0.1',r));return {s,url:`http://127.0.0.1:${s.address().port}`}};
test('BookOrbit protected covers and book-scoped file ranges preserve permission and cookie boundaries',async t=>{
 const bytes=Buffer.from('Synthetic EPUB bytes');const receipts=[];let revoked=false;
 const up=await listen(async(req,res)=>{for await(const _ of req){};receipts.push(req.url);
 if(req.url==='/api/v1/auth/login'){res.setHeader('Content-Type','application/json');return res.end(JSON.stringify({accessToken:'SENTINEL-ACCESS',refreshToken:'d'.repeat(64),user:{id:1,username:'reader'}}))}
 if(req.url==='/api/v1/auth/logout')return res.end('{}');
 assert.equal(req.headers.authorization,'Bearer SENTINEL-ACCESS');
 if(req.url==='/api/v1/books/1'){res.setHeader('Content-Type','application/json');return res.end(JSON.stringify({id:1,title:'<Synthetic>',files:[{id:7,format:'epub'}]}))}
 if(req.url.startsWith('/api/v1/books/1/cover')){res.setHeader('Content-Type','image/png');res.setHeader('ETag','"qa"');if(req.headers['if-none-match']==='"qa"'){res.statusCode=304;return res.end()}return res.end('PNG')}
 if(req.url==='/api/v1/books/files/7/download'){if(revoked){res.statusCode=403;return res.end('{}');}res.setHeader('Content-Type','application/epub+zip');res.setHeader('Set-Cookie','native_secret=NEVER');res.setHeader('Accept-Ranges','bytes');if(req.headers.range==='bytes=0-3'){res.statusCode=206;res.setHeader('Content-Range',`bytes 0-3/${bytes.length}`);res.setHeader('Content-Length','4');return res.end(bytes.subarray(0,4))}if(req.headers.range){res.statusCode=416;res.setHeader('Content-Range',`bytes */${bytes.length}`);return res.end()}res.setHeader('Content-Length',bytes.length);return res.end(req.method==='HEAD'?'':bytes)}
 res.statusCode=404;res.end('{}');});
 const app=createBookOrbitApp({allowedUpstreams:[up.url],allowHttp:true,origins:['https://absorb.example.invalid'],secureCookie:false});const bff=await listen(app);t.after(async()=>{await app.dispose();bff.s.closeAllConnections();up.s.closeAllConnections();await Promise.all([new Promise(r=>bff.s.close(r)),new Promise(r=>up.s.close(r))])});
 let r=await fetch(bff.url+'/bookorbit/api/v1/auth/login',{method:'POST',headers:{Origin:'https://absorb.example.invalid','Content-Type':'application/json'},body:JSON.stringify({serverUrl:up.url,username:'reader',password:'Synthetic1'})});const Cookie=r.headers.get('set-cookie').split(';')[0];
 r=await fetch(bff.url+'/bookorbit/api/v1/books/1/access',{headers:{Cookie}});assert.equal(r.status,200);const html=await r.text();assert.ok(html.includes('&lt;Synthetic&gt;'));assert.ok(html.includes('/bookorbit/api/v1/books/1/files/7/download'));assert.ok(html.includes('Listen inside Absorb'));
 r=await fetch(bff.url+'/bookorbit/api/v1/books/1/cover?medium=ebook&t=v1',{headers:{Cookie}});assert.equal(r.status,200);assert.equal(await r.text(),'PNG');assert.equal(r.headers.get('cache-control'),'private, no-store');
 r=await fetch(bff.url+'/bookorbit/api/v1/books/1/cover',{headers:{Cookie,'If-None-Match':'"qa"'}});assert.equal(r.status,304);
 const url=bff.url+'/bookorbit/api/v1/books/1/files/7/download';r=await fetch(url,{headers:{Cookie,Range:'bytes=0-3'}});assert.equal(r.status,206);assert.equal(await r.text(),'Synt');assert.equal(r.headers.get('set-cookie'),null);assert.equal(r.headers.get('content-range'),`bytes 0-3/${bytes.length}`);
 r=await fetch(url,{method:'HEAD',headers:{Cookie}});assert.equal(r.status,200);assert.equal(r.headers.get('content-length'),String(bytes.length));assert.equal(await r.text(),'');
 r=await fetch(url,{headers:{Cookie,Range:'bytes=999-'}});assert.equal(r.status,416);
 r=await fetch(bff.url+'/bookorbit/api/v1/books/1/files/8/download',{headers:{Cookie}});assert.equal(r.status,404);assert.ok(!receipts.includes('/api/v1/books/files/8/download'));
 r=await fetch(bff.url+'/bookorbit/api/v1/books/2/cover',{headers:{Cookie}});assert.equal(r.status,404);
 const before=receipts.length;r=await fetch(url,{headers:{Cookie:'absorb_web_session=OTHER'}});assert.equal(r.status,401);assert.equal(receipts.length,before);
 r=await fetch(bff.url+'/bookorbit/api/v1/books/1/cover?url=http://attacker.invalid',{headers:{Cookie}});assert.equal(r.status,404);
 revoked=true;r=await fetch(url,{headers:{Cookie}});assert.equal(r.status,403);
 for(const route of ['/books/1/audio-progress','/admin/users','/tts']){r=await fetch(bff.url+'/bookorbit/api/v1'+route,{method:'POST',headers:{Cookie,Origin:'https://absorb.example.invalid','Content-Type':'application/json'},body:'{}'});assert.equal(r.status,404);}
});
