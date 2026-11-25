// Synthetic native 3.8 protocol fixtures; no real accounts or media.
import {test} from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {createBookOrbitApp} from '../bookorbit.mjs';
const origin='https://client.example.invalid';
const asset='aud_12345678-1234-4234-8234-123456789abc';
const revision='a'.repeat(64);
async function listen(handler){const s=http.createServer(handler);await new Promise(r=>s.listen(0,'127.0.0.1',r));return {s,url:`http://127.0.0.1:${s.address().port}`,close:()=>new Promise(r=>s.close(r))};}
test('selected BookOrbit accounts isolate same-ID audio, EPUB resources, CAS and listening after refresh/logout',async()=>{
 const receipts=[],states={A:null,B:null},narration={A:0,B:0};
 const make=label=>async(req,res)=>{
  let raw='';for await(const c of req)raw+=c;
  const body=raw?JSON.parse(raw):null,p=req.url.replace(/^\/base/,'');
  receipts.push({label,p,method:req.method,body});
  res.setHeader('Content-Type','application/json');const send=d=>res.end(JSON.stringify(d));
  if(body)assert.equal(req.headers['content-length'],String(Buffer.byteLength(raw)));
  if(p==='/api/v1/auth/login'){if(body.password==='bad'){res.statusCode=401;return send({});}return send({accessToken:`access-${label}`,refreshToken:'a'.repeat(64),user:{id:1,username:'reader',permissions:['book:read']}});}
  if(p==='/api/v1/auth/refresh')return send({accessToken:`access-${label}`,refreshToken:'b'.repeat(64)});
  if(p==='/api/v1/auth/logout')return send({});
  assert.equal(req.headers.authorization,`Bearer access-${label}`);
  if(p==='/api/v1/books/1')return send({id:1,title:label,files:[{id:7,format:'mp3'},{id:8,format:'epub'}]});
  if(p==='/api/v1/audiobooks/1/manifest')return send({bookId:1,revision,assets:[{assetId:asset,fileId:7,durationMs:30000}],totalDurationMs:30000,chapters:[]});
  if(p==='/api/v1/audiobooks/1/playback-state'){
   if(req.method==='PUT'){if(body.baseRevision!==(states[label]?.revision??0)){res.statusCode=409;return send({});}states[label]={...body,revision:body.baseRevision+1};}
   return send(states[label]);
  }
  if(p==='/api/v1/epub/1/media-overlay?fileId=8')return send({items:[{audioHref:'EPUB/audio/one.m4a',textHref:'EPUB/chapter.xhtml',clipBeginSeconds:0,clipEndSeconds:30}],resources:[{href:'EPUB/audio/one.m4a',mediaType:'audio/mp4'}],sections:[]});
  if(p===`/api/v1/audiobooks/1/assets/${asset}/content`||p==='/api/v1/epub/1/media-overlay/file/EPUB/audio/one.m4a?fileId=8'){
   res.setHeader('Content-Type','audio/mp4');res.setHeader('Set-Cookie','native=NEVER');
   if(req.headers['if-none-match']){res.statusCode=304;return res.end();}
   if(req.headers.range==='bytes=999-'){res.statusCode=416;res.setHeader('Content-Range','bytes */1');return res.end();}
   if(req.headers.range){res.statusCode=206;res.setHeader('Content-Range','bytes 0-0/1');}
   res.setHeader('Content-Length','1');return res.end(req.method==='HEAD'?'':label);
  }
  if(p==='/api/v1/reading-progress'){narration[label]=body.writes[0].narration.seconds;return send({});}
  if(p==='/api/v1/books/files/7/sessions'){res.statusCode=204;return res.end();}
  res.statusCode=404;send({});
 };
 const a=await listen(make('A')),b=await listen(make('B'));
 const app=createBookOrbitApp({origins:[origin],allowedUpstreams:[a.url,b.url],allowHttp:true,secureCookie:false}),proxy=await listen(app);
 const request=(account,path,{method='GET',body,headers={}}={})=>fetch(proxy.url+(account?.route??'/bookorbit')+'/api/v1'+path,{method,headers:{Origin:origin,...(account?{Cookie:account.cookie}:{}),...(body?{'Content-Type':'application/json'}:{}),...headers},...(body?{body:JSON.stringify(body)}:{})});
 try{
  const login=async url=>{const r=await request(null,'/auth/login',{method:'POST',body:{serverUrl:url+'/base',sessionRouting:true,username:'reader',password:'synthetic'}});assert.equal(r.status,200);const d=await r.json();assert.match(d.webSessionRoute,/^\/bookorbit\/sessions\/[A-Za-z0-9_-]{24}$/);assert.ok(r.headers.get('set-cookie').includes('Path='+d.webSessionRoute+';'));return {route:d.webSessionRoute,cookie:r.headers.get('set-cookie').split(';')[0]};};
  const ca=await login(a.url),cb=await login(b.url),media=`/audiobooks/1/assets/${asset}/content`;
  for(const [account,label] of [[ca,'A'],[cb,'B']]){
   assert.equal((await request(account,'/audiobooks/1/manifest')).status,200);
   assert.equal(await (await request(account,media,{headers:{Range:'bytes=0-0'}})).text(),label);
   assert.equal(await (await request(account,'/epub/1/media-overlay/file/EPUB/audio/one.m4a?fileId=8')).text(),label);
   assert.equal((await request(account,media,{method:'HEAD'})).headers.get('content-length'),'1');
   assert.equal((await request(account,media,{headers:{'If-None-Match':'fixture'}})).status,304);
   assert.equal((await request(account,media,{headers:{Range:'bytes=999-'}})).status,416);
   for(let baseRevision=0;baseRevision<3;baseRevision++){
    const r=await request(account,'/audiobooks/1/playback-state',{method:'PUT',body:{assetId:asset,positionMs:(baseRevision+1)*(label==='A'?1000:2000),capturedAt:new Date().toISOString(),operationId:'12345678-1234-4234-8234-123456789abc',baseRevision,manifestRevision:revision}});
    assert.equal(r.status,200);assert.equal((await r.json()).revision,baseRevision+1);
   }
   assert.equal((await request(account,'/books/1/narration-progress',{method:'PUT',body:{writes:[{fileId:8,kind:'narration',percentage:10,narration:{seconds:label==='A'?3:6,fragment:null,sectionIndex:0}}]}})).status,200);
   assert.equal((await request(account,'/books/1/files/7/sessions',{method:'POST',body:{sessionId:'12345678-1234-4234-8234-123456789abc',startedAt:'2026-01-01T00:00:00Z',endedAt:'2026-01-01T00:00:05Z',durationSeconds:5,sessionType:'listen',source:'web',clientName:'Absorb'}})).status,200);
   assert.equal((await request(account,'/auth/refresh',{method:'POST',body:{}})).status,200);
  }
  assert.deepEqual([states.A.positionMs,states.B.positionMs,narration.A,narration.B],[3000,6000,3,6]);
  const before=receipts.length;
  for(const account of [null,{...ca,route:cb.route},{...ca,route:'/bookorbit'}])assert.equal((await request(account,media)).status,401);
  assert.equal(receipts.length,before);
  assert.equal((await request(ca,'/epub/1/media-overlay/file/EPUB/chapter.xhtml?fileId=8')).status,404);
  const bad=await request(null,'/auth/login',{method:'POST',body:{serverUrl:b.url+'/base',username:'reader',password:'bad'}});assert.equal(bad.status,401);assert.equal(bad.headers.get('set-cookie'),null);
  const logout=await request(ca,'/auth/logout',{method:'POST',body:{}});assert.equal(logout.status,200);assert.ok(logout.headers.get('set-cookie').includes('Path='+ca.route+';'));assert.ok(logout.headers.get('set-cookie').includes('Max-Age=0'));
  assert.equal((await request(ca,media)).status,401);
  assert.equal(await (await request(cb,media)).text(),'B');
  assert.equal((await (await request(cb,'/audiobooks/1/playback-state')).json()).positionMs,6000);
  assert.ok(!receipts.some(r=>r.p.includes('download')));
 }finally{await app.dispose();await proxy.close();await a.close();await b.close();}
});
