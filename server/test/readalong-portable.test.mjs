// Synthetic native protocol only; no real users, books or credentials.
import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {createBookOrbitApp} from '../bookorbit.mjs';
const origin='https://app.example.invalid';
async function listen(f){const s=http.createServer(f);await new Promise(r=>s.listen(0,'127.0.0.1',r));return {s,url:`http://127.0.0.1:${s.address().port}`};}
test('scoped same-ID publication isolation, exact membership, bounded bytes and logout retirement',async t=>{
 let release,entered; const ready=new Promise(r=>entered=r);const receipts=[];
 const make=label=>async(req,res)=>{
  let raw='';for await(const chunk of req)raw+=chunk;receipts.push([label,req.method,req.url]);
  res.setHeader('Content-Type','application/json');const send=d=>res.end(JSON.stringify(d));
  if(req.url==='/api/v1/auth/login')return send({accessToken:'synthetic-'+label,refreshToken:'a'.repeat(64),user:{id:1,username:'reader',permissions:[]}});
  if(req.url==='/api/v1/auth/logout')return send({});
  assert.equal(req.headers.authorization,'Bearer synthetic-'+label);
  if(req.url==='/api/v1/books/1')return send({id:1,files:[{id:8,format:'epub'}]});
  if(req.url==='/api/v1/epub/1/info?fileId=8')return send({spine:[{href:'EPUB/ch.xhtml'},{href:'EPUB/held.xhtml'}],manifest:[{href:'EPUB/ch.xhtml',mediaType:'application/xhtml+xml',size:10},{href:'EPUB/held.xhtml',mediaType:'application/xhtml+xml',size:10},{href:'EPUB/huge.png',mediaType:'image/png',size:10}]});
  if(req.url==='/api/v1/epub/1/file/EPUB/ch.xhtml?fileId=8')return res.end('<p>'+label+'</p>');
  if(req.url==='/api/v1/epub/1/file/EPUB/huge.png?fileId=8')return res.end(Buffer.alloc(8*1024*1024+1));
  if(req.url==='/api/v1/epub/1/file/EPUB/held.xhtml?fileId=8'){res.write('<p>');entered();await new Promise(r=>release=r);return res.end(label+'</p>');}
  res.statusCode=404;send({});
 };
 const a=await listen(make('A')),b=await listen(make('B'));
 const app=createBookOrbitApp({origins:[origin],allowedUpstreams:[a.url,b.url],allowHttp:true,secureCookie:false});const proxy=await listen(app);
 t.after(async()=>{release?.();await app.dispose();for(const {s} of [proxy,a,b]){s.closeAllConnections();await new Promise(r=>s.close(r));}});
 const login=async upstream=>{const r=await fetch(proxy.url+'/bookorbit/api/v1/auth/login',{method:'POST',headers:{Origin:origin,'Content-Type':'application/json'},body:JSON.stringify({serverUrl:upstream,sessionRouting:true,username:'reader',password:'synthetic'})});assert.equal(r.status,200);return {route:(await r.json()).webSessionRoute,cookie:r.headers.get('set-cookie').split(';')[0]};};
 const ca=await login(a.url),cb=await login(b.url);
 const request=(c,path,init={})=>fetch(proxy.url+c.route+'/api/v1'+path,{...init,headers:{Cookie:c.cookie,...init.headers}});
 const root='/epub/1/publication/8/EPUB/';
 for(const [c,label] of [[ca,'A'],[cb,'B']]){const r=await request(c,root+'ch.xhtml');assert.equal(r.status,200);assert.equal(await r.text(),'<p>'+label+'</p>');assert.equal((await request(c,root+'ch.xhtml',{method:'HEAD'})).status,200);}
 for(const path of ['ch.xhtml?fileId=8&fileId=8','%252e%252e/ch.xhtml','missing.xhtml'])assert.equal((await request(ca,root+path)).status,404);
 assert.equal((await request({...ca,route:cb.route},root+'ch.xhtml')).status,401);
 assert.equal((await request(ca,root+'huge.png')).status,502);
 const pending=request(ca,root+'held.xhtml');await ready;
 assert.equal((await request(ca,'/auth/logout',{method:'POST',headers:{Origin:origin,'Content-Type':'application/json'},body:'{}'})).status,200);release();
 const retired=await pending;assert.equal(retired.status,401);assert.ok(!(await retired.text()).includes('<p>'));
 assert.equal(await (await request(cb,root+'ch.xhtml')).text(),'<p>B</p>');
 assert.ok(receipts.every(([,method,path])=>method==='GET'||path.endsWith('/auth/login')||path.endsWith('/auth/logout')));
 assert.ok(!receipts.some(([, ,path])=>/download|progress|sessions/.test(path)));
});
