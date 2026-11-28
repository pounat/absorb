import {test} from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {createApp} from '../app.mjs';
const origin='https://client.example.invalid';
async function serve(fn){const server=http.createServer(fn);await new Promise(r=>server.listen(0,'127.0.0.1',r));return {server,url:`http://127.0.0.1:${server.address().port}`,close:()=>new Promise(r=>server.close(r))};}
test('public session routes are not credentials and cannot select another cookie account',async()=>{
 const receipts=[];const upstream=await serve(async(req,res)=>{let raw='';for await(const c of req)raw+=c;receipts.push(req.url);res.setHeader('Content-Type','application/json');const user={id:'u1',username:'reader',accessToken:'synthetic-access',refreshToken:'synthetic-refresh',permissions:{}};if(req.url==='/login')return res.end(JSON.stringify({user}));if(req.url==='/api/me')return res.end(JSON.stringify(user));res.end('{}');});
 const app=createApp({origins:[origin],allowedUpstreams:[upstream.url],allowHttp:true,secureCookie:false});const proxy=await serve(app);
 try {const login=async()=>{const r=await fetch(proxy.url+'/login',{method:'POST',headers:{Origin:origin,'Content-Type':'application/json'},body:JSON.stringify({serverUrl:upstream.url,username:'reader',password:'pw',sessionRouting:true})});assert.equal(r.status,200);const d=await r.json();assert.match(d.webSessionRoute,/^\/sessions\/[A-Za-z0-9_-]{24}$/);assert.ok(r.headers.get('set-cookie').includes(`Path=${d.webSessionRoute}`));return {route:d.webSessionRoute,cookie:r.headers.get('set-cookie').split(';')[0]};};
 const a=await login(),b=await login();assert.notEqual(a.route,b.route);
 const get=(route,cookie)=>fetch(proxy.url+route+'/api/me',{headers:cookie?{Cookie:cookie}:{}});
 assert.equal((await get(a.route,a.cookie)).status,200);assert.equal((await get(a.route,b.cookie)).status,401);assert.equal((await get(a.route)).status,401);assert.equal((await get('',a.cookie)).status,401);assert.equal((await get(b.route,b.cookie)).status,200);
 }finally{await app.dispose();await proxy.close();await upstream.close();}
});
