import test from 'node:test';import assert from 'node:assert/strict';import http from 'node:http';import {createBookOrbitApp} from '../bookorbit.mjs';
const listen=async h=>{const s=http.createServer(h);await new Promise(r=>s.listen(0,'127.0.0.1',r));return {s,url:`http://127.0.0.1:${s.address().port}`}};
test('playback JSON is fenced after logout and malformed native progress cannot dispatch writes',async t=>{
 let release,entered;const held=new Promise(r=>release=r);const started=new Promise(r=>entered=r);let writes=0;
 const up=await listen(async(req,res)=>{let raw='';for await(const c of req)raw+=c;res.setHeader('Content-Type','application/json');
 if(req.url==='/api/v1/auth/login')return res.end(JSON.stringify({accessToken:'QA',refreshToken:'d'.repeat(64),user:{id:1,username:'reader'}}));
 if(req.url==='/api/v1/auth/logout')return res.end('{}');
 if(req.url==='/api/v1/books/1')return res.end(JSON.stringify({id:1,files:[{id:7,format:'epub'}]}));
 if(req.url==='/api/v1/audiobooks/1/manifest'){entered();await held;return res.end(JSON.stringify({assets:[],title:'LATE DTO MUST NOT ESCAPE'}))}
 if(req.method==='PUT')writes++;return res.end('{}');});
 const app=createBookOrbitApp({allowedUpstreams:[up.url],allowHttp:true,origins:['https://absorb.example.invalid'],secureCookie:false});const bff=await listen(app);t.after(async()=>{release();await app.dispose();for(const x of [bff,up]){x.s.closeAllConnections();x.s.close()}});
 let r=await fetch(bff.url+'/bookorbit/api/v1/auth/login',{method:'POST',headers:{Origin:'https://absorb.example.invalid','Content-Type':'application/json'},body:JSON.stringify({serverUrl:up.url,username:'reader',password:'Synthetic1'})});const Cookie=r.headers.get('set-cookie').split(';')[0];const base=bff.url+'/bookorbit/api/v1';const headers={Cookie,Origin:'https://absorb.example.invalid','Content-Type':'application/json'};
 for(const body of [{writes:[]},{writes:[{fileId:7,kind:'narration',percentage:5,narration:{seconds:-1,fragment:null,sectionIndex:null}}]},{writes:[{fileId:9,kind:'narration',percentage:5,narration:{seconds:2,fragment:null,sectionIndex:null}}]}]){r=await fetch(base+'/books/1/narration-progress',{method:'PUT',headers,body:JSON.stringify(body)});assert.ok([400,404].includes(r.status))}assert.equal(writes,0);
 const pending=fetch(base+'/audiobooks/1/manifest',{headers:{Cookie}});await started;
 r=await fetch(base+'/auth/logout',{method:'POST',headers,body:'{}'});assert.equal(r.status,200);release();r=await pending;assert.equal(r.status,401);assert.ok(!(await r.text()).includes('LATE DTO'));
 r=await fetch(base+'/audiobooks/1/manifest',{headers:{Cookie}});assert.equal(r.status,401);
});
test('narrated EPUB exposes only native playlist audio members with book/file ownership',async t=>{
 const calls=[];const up=await listen(async(req,res)=>{for await(const _ of req){};calls.push(req.url);res.setHeader('Content-Type','application/json');
 if(req.url==='/api/v1/auth/login')return res.end(JSON.stringify({accessToken:'QA',refreshToken:'d'.repeat(64),user:{id:1,username:'reader'}}));
 if(req.url==='/api/v1/auth/logout')return res.end('{}');
 if(req.url==='/api/v1/books/2')return res.end(JSON.stringify({id:2,files:[{id:8,format:'epub',role:'primary'}]}));
 if(req.url==='/api/v1/epub/2/media-overlay?fileId=8')return res.end(JSON.stringify({items:[{audioHref:'EPUB/audio/one.m4a',textHref:'EPUB/chapter.xhtml',clipBeginSeconds:0,clipEndSeconds:30}],resources:[{href:'EPUB/audio/one.m4a',mediaType:'audio/mp4'}],sections:[]}));
 if(req.url==='/api/v1/epub/2/media-overlay/file/EPUB/audio/one.m4a?fileId=8'){res.setHeader('Content-Type','audio/mp4');return res.end('QA audio')}
 res.statusCode=404;res.end('{}');});
 const app=createBookOrbitApp({allowedUpstreams:[up.url],allowHttp:true,origins:['https://absorb.example.invalid'],secureCookie:false});const bff=await listen(app);t.after(async()=>{await app.dispose();for(const x of [bff,up]){x.s.closeAllConnections();x.s.close()}});
 let r=await fetch(bff.url+'/bookorbit/api/v1/auth/login',{method:'POST',headers:{Origin:'https://absorb.example.invalid','Content-Type':'application/json'},body:JSON.stringify({serverUrl:up.url,username:'reader',password:'Synthetic1'})});const Cookie=r.headers.get('set-cookie').split(';')[0];
 const base=bff.url+'/bookorbit/api/v1';r=await fetch(base+'/epub/2/media-overlay?fileId=8',{headers:{Cookie}});assert.equal(r.status,200,'native narrated playlist must be admitted');assert.equal((await r.json()).items[0].audioHref,'EPUB/audio/one.m4a');
 r=await fetch(base+'/epub/2/media-overlay/file/EPUB/audio/one.m4a?fileId=8',{headers:{Cookie}});assert.equal(r.status,200);assert.equal(await r.text(),'QA audio');
 for(const tail of ['EPUB/chapter.xhtml?fileId=8','EPUB/audio/one.m4a?fileId=9','EPUB/audio/one.m4a?fileId=8&url=http://evil.invalid']){r=await fetch(base+'/epub/2/media-overlay/file/'+tail,{headers:{Cookie}});assert.ok([400,404].includes(r.status))}
 assert.ok(!calls.some(p=>p.includes('/download')));
});
test('native audiobook manifest and scoped asset stream are playable without download permission',async t=>{
 const calls=[];let allowed=true;
 const up=await listen(async(req,res)=>{for await(const _ of req){};calls.push(req.url);res.setHeader('Content-Type','application/json');
 if(req.url==='/api/v1/auth/login')return res.end(JSON.stringify({accessToken:'QA',refreshToken:'d'.repeat(64),user:{id:1,username:'reader'}}));
 if(req.url==='/api/v1/auth/logout')return res.end('{}');
 if(req.url==='/api/v1/books/1'){if(!allowed){res.statusCode=403;return res.end('{}')}return res.end(JSON.stringify({id:1,files:[{id:7,format:'m4b',role:'primary'}]}))}
 if(req.url==='/api/v1/audiobooks/1/manifest')return res.end(JSON.stringify({bookId:1,revision:'qa',assets:[{assetId:'aud_12345678-1234-4234-8234-123456789abc',fileId:7,durationMs:30000}],totalDurationMs:30000,chapters:[]}));
 if(req.url.startsWith('/api/v1/audiobooks/1/assets/aud_12345678-1234-4234-8234-123456789abc/content')){res.statusCode=206;res.setHeader('Content-Type','audio/mp4');res.setHeader('Content-Range','bytes 0-3/20');return res.end('QA!!')}
 res.statusCode=404;res.end('{}');});
 const app=createBookOrbitApp({allowedUpstreams:[up.url],allowHttp:true,origins:['https://absorb.example.invalid'],secureCookie:false});const bff=await listen(app);t.after(async()=>{await app.dispose();bff.s.closeAllConnections();up.s.closeAllConnections();bff.s.close();up.s.close()});
 let r=await fetch(bff.url+'/bookorbit/api/v1/auth/login',{method:'POST',headers:{Origin:'https://absorb.example.invalid','Content-Type':'application/json'},body:JSON.stringify({serverUrl:up.url,username:'reader',password:'Synthetic1'})});const Cookie=r.headers.get('set-cookie').split(';')[0];
 const base=bff.url+'/bookorbit/api/v1';r=await fetch(base+'/audiobooks/1/manifest',{headers:{Cookie}});assert.equal(r.status,200,'normal audiobook manifest must be admitted');assert.equal((await r.json()).assets[0].fileId,7);
 r=await fetch(base+'/audiobooks/1/assets/aud_12345678-1234-4234-8234-123456789abc/content',{headers:{Cookie,Range:'bytes=0-3'}});assert.equal(r.status,206);assert.equal(await r.text(),'QA!!');assert.equal(r.headers.get('cache-control'),'private, no-store');assert.equal(r.headers.get('content-disposition'),null);
 allowed=false;r=await fetch(base+'/audiobooks/1/manifest',{headers:{Cookie}});assert.equal(r.status,403);
 const before=calls.length;r=await fetch(base+'/audiobooks/1/assets/evil/content',{headers:{Cookie}});assert.equal(r.status,404);assert.equal(calls.length,before);
});
