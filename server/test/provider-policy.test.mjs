import {test} from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {createProviderApp} from '../providers.mjs';
async function serve(fn){const s=http.createServer(fn);await new Promise(r=>s.listen(0,'127.0.0.1',r));return {s,url:`http://127.0.0.1:${s.address().port}`,close:()=>new Promise(r=>s.close(r))};}
test('both providers reject redirect credentials and mixed DNS using the shared strict transport',async()=>{
 let sinkCalls=0,sourceCalls=0;
 const sink=await serve((req,res)=>{sinkCalls++;res.end('{}');});
 const source=await serve((req,res)=>{sourceCalls++;res.writeHead(307,{Location:sink.url+'/login'});res.end();});
 const origin='https://client.example.invalid';
 const app=createProviderApp({origins:[origin],allowedUpstreams:[source.url],allowHttp:true,resolve:async()=>[{address:'8.8.8.8',family:4},{address:'127.0.0.1',family:4}]});const proxy=await serve(app);
 try{
  for(const path of ['/login','/bookorbit/api/v1/auth/login']){
   const login=serverUrl=>fetch(proxy.url+path,{method:'POST',headers:{Origin:origin,'Content-Type':'application/json'},body:JSON.stringify({serverUrl,username:'reader',password:'synthetic-password',sessionRouting:true})});
   assert.equal((await login(source.url)).status,502);
   assert.equal((await login('https://catalog.example.invalid')).status,502);
   assert.equal((await login('http://catalog.example.invalid')).status,400);
  }
  assert.equal(sourceCalls,2);assert.equal(sinkCalls,0);
 }finally{await app.dispose();await proxy.close();await source.close();await sink.close();}
});
test('startup, health and login options have no upstream destination or implicit connection',async()=>{
 const app=createProviderApp({origins:['https://client.example.invalid']});const proxy=await serve(app);
 try{
  for(const path of ['/ping','/status','/bookorbit/api/v1/auth/login-options'])assert.equal((await fetch(proxy.url+path)).status,200);
  for(const path of ['/login','/bookorbit/api/v1/auth/login'])assert.equal((await fetch(proxy.url+path,{method:'POST',headers:{Origin:'https://client.example.invalid','Content-Type':'application/json'},body:JSON.stringify({username:'reader',password:'synthetic-password'})})).status,400);
 }finally{await app.dispose();await proxy.close();}
});
