import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {createBookOrbitApp} from '../bookorbit.mjs';
const listen=async f=>{const s=http.createServer(f);await new Promise(r=>s.listen(0,'127.0.0.1',r));return {s,url:`http://127.0.0.1:${s.address().port}`}};
test('publication entries require book/file/manifest/spine membership, are bounded and read-only',async t=>{
 const calls=[];const up=await listen((req,res)=>{calls.push(req.url);res.setHeader('Content-Type','application/json');
 if(req.url==='/api/v1/auth/login')return res.end(JSON.stringify({accessToken:'fixture',refreshToken:'a'.repeat(64),user:{id:1,username:'reader',permissions:['book_read']}}));
 if(req.url==='/api/v1/auth/logout')return res.end('{}');
 if(req.url==='/api/v1/books/12')return res.end(JSON.stringify({id:12,files:[{id:30,format:'epub'}]}));
 if(req.url==='/api/v1/epub/12/info?fileId=30')return res.end(JSON.stringify({spine:[{href:'EPUB/ch.xhtml'}],manifest:[{href:'EPUB/ch.xhtml',mediaType:'application/xhtml+xml',size:40},{href:'EPUB/secret.xhtml',mediaType:'application/xhtml+xml',size:20},{href:'EPUB/book.css',mediaType:'text/css',size:20},{href:'EPUB/huge.png',mediaType:'image/png',size:9000000},{href:'EPUB/run.js',mediaType:'text/javascript',size:20}]}));
 if(req.url==='/api/v1/epub/12/file/EPUB/ch.xhtml?fileId=30'){res.setHeader('Content-Type','application/xhtml+xml');return res.end('<html><body><p id="one">Text</p></body></html>');}
 res.statusCode=403;res.end('{}');});
 const app=createBookOrbitApp({allowedUpstreams:[up.url],allowHttp:true,origins:['https://fixture'],secureCookie:false});const bff=await listen(app);
 t.after(async()=>{await app.dispose();for(const x of [bff,up]){x.s.closeAllConnections();await new Promise(r=>x.s.close(r));}});
 let r=await fetch(bff.url+'/bookorbit/api/v1/auth/login',{method:'POST',headers:{Origin:'https://fixture','Content-Type':'application/json'},body:JSON.stringify({serverUrl:up.url,username:'reader',password:'synthetic'})});
 const headers={Cookie:r.headers.get('set-cookie').split(';')[0]};const base=bff.url+'/bookorbit/api/v1/epub/12/publication/30/';
 r=await fetch(base+'EPUB/ch.xhtml',{headers});assert.equal(r.status,200);assert.match(await r.text(),/Text/);assert.match(r.headers.get('content-security-policy'),/script-src 'none'/);assert.equal(r.headers.get('cache-control'),'private, no-store');
 for(const path of ['EPUB/secret.xhtml','EPUB/run.js','EPUB/huge.png','EPUB/unknown.png','EPUB/%252e%252e/secret']){r=await fetch(base+path,{headers});assert.equal(r.status,404,path);}
 r=await fetch(base.replace('/30/','/31/')+'EPUB/ch.xhtml',{headers});assert.equal(r.status,404);
 for(const path of ['EPUB/../EPUB/ch.xhtml','EPUB/%2e%2e/EPUB/ch.xhtml']){
   const status=await new Promise((resolve,reject)=>{http.get(bff.url,{path:'/bookorbit/api/v1/epub/12/publication/30/'+path,headers},r=>{r.resume();r.on('end',()=>resolve(r.statusCode));}).on('error',reject);});assert.equal(status,404,'raw traversal rejected before URL normalization');
 }
 r=await fetch(base+'EPUB/ch.xhtml');assert.equal(r.status,401);
 assert.equal(calls.filter(x=>x.includes('/download')).length,0);
});
