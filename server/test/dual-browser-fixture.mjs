// Synthetic four-server protocol fixture; no real accounts or content.
import http from 'node:http';
import https from 'node:https';
import fs from 'node:fs';
import path from 'node:path';
import {createProviderApp} from '../providers.mjs';
const root=path.resolve('build/web'), receipts=[], servers=[];
const wav=Buffer.alloc(44+8000*2*45);
wav.write('RIFF',0);wav.writeUInt32LE(wav.length-8,4);wav.write('WAVEfmt ',8);wav.writeUInt32LE(16,16);wav.writeUInt16LE(1,20);wav.writeUInt16LE(1,22);wav.writeUInt32LE(8000,24);wav.writeUInt32LE(16000,28);wav.writeUInt16LE(2,32);wav.writeUInt16LE(16,34);wav.write('data',36);wav.writeUInt32LE(wav.length-44,40);
for(let i=0;i<8000*45;i++)wav.writeInt16LE(Math.round(Math.sin(i*2*Math.PI*220/8000)*1000),44+i*2);
for(const provider of ['ABS','BookOrbit'])for(const label of ['A','B']){
 let position=label==='A'?0:2;
 const title=`${provider} synthetic ${label}`;
 const user=provider==='ABS'?{id:'reader',username:'reader',accessToken:`synthetic-access-${label}`,refreshToken:`synthetic-refresh-${label}`,permissions:{accessAllLibraries:true},librariesAccessible:[]}:{id:7,username:'reader',permissions:['read_books','download_books'],isSuperuser:false,settings:{}};
 const item={id:'item',libraryId:'lib',mediaType:'book',media:{metadata:{title,authors:[],narrators:[]},duration:45,numTracks:1,tracks:[{index:0,duration:45,mimeType:'audio/wav',metadata:{filename:'synthetic.wav'},contentUrl:'/public/session/shared-session/track/0'}],audioFiles:[{index:0,duration:45,mimeType:'audio/wav',ino:'file',metadata:{filename:'synthetic.wav'}}],chapters:[{id:0,start:0,end:45,title:'Synthetic chapter'}]}};
 const server=http.createServer(async(req,res)=>{
  let raw='';for await(const c of req)raw+=c;
  const body=raw?JSON.parse(raw):{};
  const p=req.url.split('?')[0].replace(/^\/base/,'');
  receipts.push({provider,label,path:p,method:req.method,correctLogin:body.username==='reader'&&body.password==='synthetic-password',position:body.currentTime??null});
  res.setHeader('Content-Type','application/json');
  const send=data=>res.end(JSON.stringify(data));
  if(p==='/login'||p==='/api/v1/auth/login'){
   if(body.username!=='reader'||body.password!=='synthetic-password'){res.statusCode=401;return send({});}
   return send(provider==='ABS'?{user,userDefaultLibraryId:'lib',serverSettings:{version:'2.36.0'}}:{accessToken:`synthetic-access-${label}`,refreshToken:'c'.repeat(64),user});
  }
  if(provider==='ABS'){
   if(p==='/ping')return res.end('pong');
   if(p==='/status')return send({serverVersion:'2.36.0'});
   if(p==='/auth/refresh')return send({user});
   if(p==='/api/me')return send(user);
   if(p==='/api/libraries')return send({libraries:[{id:'lib',name:title,mediaType:'book',displayOrder:0}]});
   if(p==='/api/libraries/lib/items')return send({results:[item],total:1,limit:100,page:0});
   if(p==='/api/libraries/lib/personalized')return send([]);
   if(p==='/api/items/item')return send(item);
   if(p==='/api/me/progress/item')return send({currentTime:position,duration:45,progress:position/45,isFinished:false});
   if(p==='/api/items/item/play')return send({id:'shared-session',userId:'reader',libraryItemId:'item',duration:45,currentTime:position,audioTracks:[{index:0,duration:45,mimeType:'audio/wav',contentUrl:'/public/session/shared-session/track/0'}],chapters:[],libraryItem:item});
   if(p==='/api/session/shared-session')return send({id:'shared-session',userId:'reader',libraryItemId:'item'});
   if(p==='/api/session/shared-session/sync'){position=body.currentTime;return send({});}
   if(p==='/api/session/shared-session/close'||p==='/logout')return send({});
   if(p==='/public/session/shared-session/track/0'){
    res.setHeader('Content-Type','audio/wav');res.setHeader('Accept-Ranges','bytes');
    const match=/bytes=(\d+)-(\d*)/.exec(req.headers.range||'');const start=match?Number(match[1]):0,end=match&&match[2]?Math.min(Number(match[2]),wav.length-1):wav.length-1;
    res.statusCode=match?206:200;if(match)res.setHeader('Content-Range',`bytes ${start}-${end}/${wav.length}`);res.setHeader('Content-Length',end-start+1);return res.end(req.method==='HEAD'?'':wav.subarray(start,end+1));
   }
  }else{
   if(p==='/api/v1/auth/me')return send(user);
   if(p==='/api/v1/auth/refresh')return send({accessToken:`synthetic-access-${label}`,refreshToken:'d'.repeat(64)});
   if(p==='/api/v1/auth/logout')return send({});
   if(p==='/api/v1/app-info')return send({version:'3.8.0',features:[]});
   if(p==='/api/v1/libraries')return send([{id:1,name:title,type:'books',displayOrder:0}]);
   if(p==='/api/v1/libraries/1/stats')return send({totalBooks:1,formatCounts:{epub:1},totalSizeBytes:512});
   if(p==='/api/v1/libraries/1/books')return send({items:[{id:12,title,authors:['Synthetic author'],formats:['epub'],hasCover:false}],total:1,page:0,size:20});
   if(p==='/api/v1/books/12')return send({id:12,title,authors:['Synthetic author'],files:[{id:71,format:'epub'}]});
   if(p==='/api/v1/books/files/71/download'){res.setHeader('Content-Type','application/epub+zip');return res.end(title);}
  }
  res.statusCode=404;send({});
 });
 await new Promise(r=>server.listen(0,'127.0.0.1',r));servers.push({server,provider,label,url:`http://127.0.0.1:${server.address().port}/base`});
}
let app;
const server=https.createServer({key:fs.readFileSync(process.argv[2]),cert:fs.readFileSync(process.argv[3])},(req,res)=>{
 if(req.url==='/synthetic-receipts'){res.setHeader('Content-Type','application/json');return res.end(JSON.stringify(receipts));}
 if(!req.url.startsWith('/absorb/'))return app(req,res);
 const policy=fs.readFileSync('deploy/nginx/web.conf','utf8').match(/add_header Content-Security-Policy "([^"]+)"/)[1];res.setHeader('Content-Security-Policy',policy);res.setHeader('Cache-Control','no-store');
 const name=path.resolve(root,'.'+req.url.split('?')[0].replace(/^\/absorb/,'').replace(/\/$/,'/index.html'));
 if(!name.startsWith(root+'/')){res.statusCode=404;return res.end();}
 res.setHeader('Content-Type',({'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.ttf':'font/ttf','.otf':'font/otf'})[path.extname(name)]??'application/octet-stream');
 fs.createReadStream(name).on('error',()=>{res.statusCode=404;res.end();}).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));const origin=`https://localhost:${server.address().port}`;
app=createProviderApp({origins:[origin],allowedUpstreams:servers.map(s=>s.url),allowHttp:true});
console.log(JSON.stringify({origin,servers:servers.map(({server,...s})=>s)}));
process.on('SIGTERM',async()=>{await app.dispose();for(const s of [server,...servers.map(s=>s.server)]){s.closeAllConnections();s.close();}});
