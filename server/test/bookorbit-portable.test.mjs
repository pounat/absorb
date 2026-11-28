import {test} from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {createBookOrbitApp} from '../bookorbit.mjs';
const origin='https://client.example.invalid';
async function listen(handler){const s=http.createServer(handler);await new Promise(r=>s.listen(0,'127.0.0.1',r));return {s,url:`http://127.0.0.1:${s.address().port}`,close:()=>new Promise(r=>s.close(r))};}
test('BookOrbit selects two explicit URLs and never retargets existing cookie authority',async()=>{
 const receipts=[];
 const make=label=>async(req,res)=>{let raw='';for await(const chunk of req)raw+=chunk;receipts.push({label,path:req.url,body:raw,headers:req.headers});res.setHeader('Content-Type','application/json');const user={id:1,username:'reader',permissions:['book:read','book:download']};
 if(req.url==='/base/api/v1/auth/login'){const b=JSON.parse(raw);assert.equal(req.headers['content-length'],String(Buffer.byteLength(raw)));if(b.password==='bad'){res.statusCode=401;return res.end('{}');}return res.end(JSON.stringify({accessToken:`access-${label}`,refreshToken:'a'.repeat(64),user}));}
 if(req.url.endsWith('/auth/refresh'))return res.end(JSON.stringify({accessToken:`access-${label}`,refreshToken:'b'.repeat(64)}));
 if(req.url.endsWith('/auth/logout'))return res.end('{}');
 if(req.url.endsWith('/auth/me'))return res.end(JSON.stringify(user));
 if(req.url.endsWith('/books/12'))return res.end(JSON.stringify({id:12,title:label,files:[{id:71,format:'EPUB'}]}));
 if(req.url.endsWith('/books/files/71/download')){res.setHeader('Content-Type','application/epub+zip');return res.end(label);}
 res.statusCode=404;res.end('{}');};
 const a=await listen(make('A')),b=await listen(make('B'));
 const app=createBookOrbitApp({origins:[origin],allowedUpstreams:[a.url,b.url],allowHttp:true,secureCookie:false});const proxy=await listen(app);
 const routes=new Map();
 const request=(path,{cookie,body,route}={})=>fetch(proxy.url+(route??routes.get(cookie)??'/bookorbit')+'/api/v1'+path,{method:body?'POST':'GET',headers:{Origin:origin,...(cookie?{Cookie:cookie}:{}),...(body?{'Content-Type':'application/json'}:{})},...(body?{body:JSON.stringify(body)}:{})});
 try{
 assert.equal(receipts.length,0);
 const blank=await request('/auth/login',{body:{serverUrl:'',username:'reader',password:'pw'}});assert.equal(blank.status,400);assert.equal(receipts.length,0);
 const login=async url=>{const r=await request('/auth/login',{body:{serverUrl:url+'/base',username:'reader',password:'pw',sessionRouting:true}});assert.equal(r.status,200);const d=await r.json();assert.match(d.webSessionRoute,/^\/bookorbit\/sessions\/[A-Za-z0-9_-]{24}$/);const cookie=r.headers.get('set-cookie').split(';')[0];assert.ok(r.headers.get('set-cookie').includes('Path='+d.webSessionRoute));routes.set(cookie,d.webSessionRoute);return cookie;};
 const ca=await login(a.url),cb=await login(b.url);
 assert.equal((await request('/auth/me',{cookie:ca,route:routes.get(cb)})).status,401);
 assert.equal((await request('/auth/me',{cookie:ca,route:'/bookorbit'})).status,401);
 for(const [cookie,label] of [[ca,'A'],[cb,'B']]){assert.equal((await (await request('/books/12',{cookie})).json()).title,label);assert.equal(await (await request('/books/12/files/71/download',{cookie})).text(),label);assert.equal((await request('/auth/refresh',{cookie,body:{}})).status,200);}
 const bad=await request('/auth/login',{body:{serverUrl:b.url+'/base',username:'reader',password:'bad'}});assert.equal(bad.status,401);assert.equal(bad.headers.get('set-cookie'),null);
 assert.equal((await request('/auth/me')).status,401);
 assert.equal((await request('/auth/logout',{cookie:ca,body:{}})).status,200);
 assert.equal((await request('/auth/me',{cookie:ca})).status,401);
 assert.equal((await (await request('/books/12',{cookie:cb})).json()).title,'B');
 assert.equal((await request('/books/12/files/72/download',{cookie:cb})).status,404);
 assert.equal((await request('/auth/login',{body:{serverUrl:'https://169.254.169.254',username:'reader',password:'pw'}})).status,400);
 }finally{await app.dispose();await proxy.close();await a.close();await b.close();}
});
