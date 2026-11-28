// Synthetic upstream + real portable provider listener; loopback only.
import http from 'node:http';
import {createProviderApp} from '../../server/providers.mjs';
const calls=[];
async function listen(handler) {
  const server=http.createServer(handler);
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  return server;
}
const upstream=await listen(async(req,res)=>{
  let raw=''; for await(const chunk of req) raw+=chunk;
  calls.push({path:req.url,body:raw});
  res.setHeader('Content-Type','application/json');
  const user={id:'synthetic-reader',username:'synthetic',permissions:{},
    accessToken:'synthetic-access',refreshToken:'synthetic-refresh'};
  if(req.url==='/api/me') return res.end(JSON.stringify(user));
  if(req.url==='/api/v1/auth/login') return res.end(JSON.stringify({
    accessToken:'synthetic-access',refreshToken:'a'.repeat(64),
    user:{id:1,username:'synthetic',permissions:['book:read']}}));
  if(req.url==='/api/v1/auth/me') return res.end(JSON.stringify({id:1,username:'synthetic',permissions:['book:read']}));
  if(req.url==='/api/v1/auth/refresh') return res.end(JSON.stringify({accessToken:'synthetic-access',refreshToken:'b'.repeat(64)}));
  res.end(JSON.stringify({user}));
});
const upstreamUrl=`http://127.0.0.1:${upstream.address().port}`;
const app=createProviderApp({origins:['https://synthetic.example'],
  allowedUpstreams:[upstreamUrl],allowHttp:true,secureCookie:false});
const server=await listen((req,res)=>{
  if(req.url==='/__synthetic_receipt') {res.setHeader('Content-Type','application/json');return res.end(JSON.stringify(calls));}
  return app(req,res);
});
console.log(JSON.stringify({url:`http://127.0.0.1:${server.address().port}`,upstreamUrl}));
async function shutdown(){
  await app.dispose(); server.closeAllConnections(); upstream.closeAllConnections();
  await Promise.all([new Promise(r=>server.close(r)),new Promise(r=>upstream.close(r))]);
}
process.once('SIGTERM',shutdown);
process.once('SIGINT',shutdown);
