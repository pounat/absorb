import {randomBytes} from 'node:crypto';
import {Readable} from 'node:stream';
import {pipeline} from 'node:stream/promises';
import {config, transport, selectUpstream} from './upstream.mjs';
import {Fault, json, readJSON, loginLimiter} from './http.mjs';

const prefix='/bookorbit/api/v1';
const userDTO = d => Object.fromEntries(['id','username','permissions','isSuperuser','isDefaultPassword','provisioningMethod','authenticationMethod'].filter(k=>k in d).map(k=>[k,d[k]]));
const safeDTO = d => Array.isArray(d) ? d.map(safeDTO) : d && typeof d==='object' ? Object.fromEntries(Object.entries(d).filter(([k])=>!/token|password|secret|path|folder|url|cookie|headers/i.test(k)).map(([k,v])=>[k,safeDTO(v)])) : d;

// Each cookie authority owns an immutable, policy-validated destination.
export function createBookOrbitApp(options) {
  config({...options,upstream:undefined});
  const selectedCall = value => {
    const send=transport(selectUpstream(value,options),{...options,selected:true});
    // BookOrbit 3.8 requires bounded Content-Length JSON, not chunked bodies.
    return (path,init={})=>send(path,typeof init.body==='string'?{...init,headers:{...init.headers,'Content-Length':String(Buffer.byteLength(init.body))}}:init);
  };
  const sessions=new Map();
  const now=options.now??Date.now;
  const admit=loginLimiter(options.loginLimit,now);
  const absoluteMs=7*86400000,idleMs=86400000;
  let pending=0;
  const cookie=(id,age)=>`absorb_bookorbit_session=${id}; Path=/bookorbit; HttpOnly; SameSite=Strict; Max-Age=${age}${options.secureCookie===false?'':'; Secure'}`;
  const expired=s=>s.revoked || now()-s.createdAt>=absoluteMs || now()-s.lastSeen>=idleMs;
  function tokens(d) {
    if(typeof d.accessToken!=='string'||!d.accessToken||d.accessToken.length>16384||typeof d.refreshToken!=='string'||!/^[a-f0-9]{64}$/.test(d.refreshToken)) throw new Fault(502,'invalid_auth_response');
    return {access:d.accessToken,refresh:d.refreshToken};
  }
  async function requestJSON(call,path,init={}) {
    const r=await call('/api/v1'+path,init);
    if(!r.ok){await r.body?.cancel();throw new Fault([401,403,404,409,412,429].includes(r.status)?r.status:502,'upstream_rejected');}
    if(r.status===204){await r.body?.cancel();return null;}
    return r.json();
  }
  async function retire(id,s) {
    if(s.retiring)return s.retiring;
    s.revoked=true;
    s.retiring=(async()=>{
      try {await s.rotating;await requestJSON(s.call,'/auth/logout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({refreshToken:s.refresh})});}catch{}finally{s.access=s.refresh=null;sessions.delete(id);}
    })();return s.retiring;
  }
  async function rotate(s) {
    if(!s.rotating) s.rotating=(async()=>{
      const d=await requestJSON(s.call,'/auth/refresh',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({refreshToken:s.refresh})});
      Object.assign(s,tokens(d));
    })().finally(()=>{s.rotating=null;});
    return s.rotating;
  }
  const sweep=()=>{for(const [id,s] of sessions)if(expired(s))void retire(id,s);};
  const timer=setInterval(sweep,60000);timer.unref();
  const app = async (req,res) => {
    res.setHeader('Cache-Control','private, no-store');
    res.setHeader('Referrer-Policy','no-referrer');
    let session,id;
    const routeMatch=/^\/bookorbit\/sessions\/[A-Za-z0-9_-]{24}(?=\/)/.exec(req.url);
    const route=routeMatch?.[0]??'';
    if(route)req.url='/bookorbit'+req.url.slice(route.length);
    const scopedCookie=(id,age)=>cookie(id,age).replace('Path=/bookorbit;',`Path=${route||'/bookorbit'};`);
    const upstreamJSON=(...args)=>requestJSON(session.call,...args);
    const call=(...args)=>session.call(...args);
    const protectedJSON=(status,d)=>{if(expired(session))throw new Fault(401,'authentication_expired');return json(res,status,d);};
    try {
      const rawPath=req.url.split('?')[0];
      // URL normalizes dot segments, so reject raw publication traversal first.
      if(rawPath.includes('/publication/') && (/%|\\/.test(rawPath)||rawPath.split('/').some(s=>s==='.'||s==='..')))throw new Fault(404,'resource_not_found');
      const url=new URL(req.url,'http://bff.invalid');
      if(!url.pathname.startsWith(prefix+'/')||/%|\\/.test(url.pathname))return json(res,404,{error:'unsupported_endpoint'});
      const path=url.pathname.slice(prefix.length);
      if(req.method==='GET' && path==='/auth/login-options' && !url.search) {
        return json(res,200,{passwordLoginEnabled:true,oidcProviders:[]});
      }
      sweep();
      let body;
      if(!['GET','HEAD'].includes(req.method)) {
        if(!options.origins.includes(req.headers.origin))throw new Fault(403,'origin_denied');
        body=await readJSON(req);
      }
      if(req.method==='POST'&&path==='/auth/login'&&!url.search) {
        if(!body||Object.keys(body).some(k=>!['serverUrl','sessionRouting','username','password'].includes(k))||typeof body.username!=='string'||!body.username||body.username.length>512||typeof body.password!=='string'||!body.password||body.password.length>4096)throw new Fault(400,'invalid_credentials');
        session={call:selectedCall(body.serverUrl)};
        admit(req.socket.remoteAddress);
        if(sessions.size+pending>=128)throw new Fault(503,'session_capacity');
        pending++;
        try {
          const d=await upstreamJSON(path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({username:body.username,password:body.password,clientKind:'native',deviceLabel:'Absorb Web'})});
          const t=tokens(d);
          if(!Number.isSafeInteger(d.user?.id)||d.user.id<=0||typeof d.user.username!=='string')throw new Fault(502,'invalid_auth_response');
          const sid=randomBytes(32).toString('base64url');
          const sessionRoute=body.sessionRouting===true?'/bookorbit/sessions/'+randomBytes(18).toString('base64url'):'';
          const s={...t,route:sessionRoute,call:session.call,userId:d.user.id,createdAt:now(),lastSeen:now()};
          if(d.user.isDefaultPassword===true){await retire(sid,s);throw new Fault(403,'password_change_required');}
          sessions.set(sid,s);
          res.setHeader('Set-Cookie',cookie(sid,absoluteMs/1000).replace('Path=/bookorbit;',`Path=${sessionRoute||'/bookorbit'};`));
          return json(res,200,{cookieAuthenticated:true,user:userDTO(d.user),...(sessionRoute?{webSessionRoute:sessionRoute}:{})});
        }finally{pending--;}
      }
      id=req.headers.cookie?.split(';').map(x=>x.trim()).find(x=>x.startsWith('absorb_bookorbit_session='))?.slice(25);
      session=sessions.get(id);
      if(!session||expired(session)||(session.route??'')!==route) {if(session&&expired(session))void retire(id,session);throw new Fault(401,'authentication_required');}
      session.lastSeen=now();
      if(req.method==='POST'&&path==='/auth/logout'&&!url.search){res.setHeader('Set-Cookie',scopedCookie('',0));await retire(id,session);return json(res,200,{});}
      if(req.method==='POST'&&path==='/auth/refresh'&&!url.search){await rotate(session);return protectedJSON(200,{cookieAuthenticated:true});}
      if(req.method==='GET'&&path==='/auth/me'&&!url.search){
        let d;
        try {d=await upstreamJSON(path,{headers:{Authorization:`Bearer ${session.access}`}});}catch(e){if(e.status!==401)throw e;await rotate(session);if(session.revoked)throw new Fault(401,'authentication_expired');d=await upstreamJSON(path,{headers:{Authorization:`Bearer ${session.access}`}});}
        if(d.id!==session.userId)throw new Fault(502,'identity_mismatch');
        return protectedJSON(200,userDTO(d));
      }
      const nativeGet=async target=>{
        if(expired(session))throw new Fault(401,'authentication_expired');
        try{return await upstreamJSON(target,{headers:{Authorization:`Bearer ${session.access}`}})}catch(e){
          if(e.status!==401)throw e;await rotate(session);if(expired(session))throw new Fault(401,'authentication_expired');
          return upstreamJSON(target,{headers:{Authorization:`Bearer ${session.access}`}});
        }
      };
      const audiobook=/^\/audiobooks\/([1-9]\d*)\/(manifest|playback-state)$/.exec(path);
      const narrationWrite=/^\/books\/([1-9]\d*)\/narration-progress$/.exec(path);
      const keys=(o,allowed)=>o&&typeof o==='object'&&!Array.isArray(o)&&Object.keys(o).every(k=>allowed.includes(k));
      const finite=(n,max)=>typeof n==='number'&&Number.isFinite(n)&&n>=0&&n<=max;
      const listenSession=/^\/books\/([1-9]\d*)\/files\/([1-9]\d*)\/sessions$/.exec(path);
      if(req.method==='POST'&&listenSession&&!url.search){
        if(!keys(body,['sessionId','startedAt','endedAt','durationSeconds','progressDelta','endProgress','sessionType','source','clientName'])||typeof body.sessionId!=='string'||!/^[a-f0-9-]{36}$/.test(body.sessionId)||body.sessionType!=='listen'||!Number.isSafeInteger(body.durationSeconds)||!finite(body.durationSeconds,86400)||typeof body.startedAt!=='string'||typeof body.endedAt!=='string'||body.startedAt.length>40||body.endedAt.length>40||!Number.isFinite(Date.parse(body.startedAt))||!Number.isFinite(Date.parse(body.endedAt))||Date.parse(body.endedAt)<Date.parse(body.startedAt)||body.durationSeconds*1000>Date.parse(body.endedAt)-Date.parse(body.startedAt)+1000||(body.progressDelta!==undefined&&(!Number.isFinite(body.progressDelta)||Math.abs(body.progressDelta)>100))||(body.endProgress!==undefined&&!finite(body.endProgress,100))||(body.source!==undefined&&body.source!=='web')||(body.clientName!==undefined&&body.clientName!=='Absorb'))throw new Fault(400,'invalid_listening_session');
        const detail=await nativeGet(`/books/${listenSession[1]}`);
        if(detail.id!==Number(listenSession[1])||!detail.files?.some(f=>f.id===Number(listenSession[2])))throw new Fault(404,'file_not_found');
        if(expired(session))throw new Fault(401,'authentication_expired');
        return protectedJSON(200,safeDTO(await upstreamJSON(`/books/files/${listenSession[2]}/sessions`,{method:'POST',headers:{Authorization:`Bearer ${session.access}`,'Content-Type':'application/json'},body:JSON.stringify(body)})));
      }
      if(req.method==='PUT'&&!url.search&&((audiobook&&audiobook[2]==='playback-state')||narrationWrite)){
        const bookId=(audiobook??narrationWrite)[1];
        if(!Number.isSafeInteger(Number(bookId)))throw new Fault(400,'invalid_book');
        const detail=await nativeGet(`/books/${bookId}`);
        if(detail.id!==Number(bookId)||!Array.isArray(detail.files))throw new Fault(502,'invalid_book_response');
        let target=path;
        if(audiobook){
          if(!keys(body,['assetId','positionMs','capturedAt','operationId','baseRevision','manifestRevision'])||typeof body.assetId!=='string'||!finite(body.positionMs,31536000000)||!Number.isSafeInteger(body.positionMs)||!Number.isSafeInteger(body.baseRevision)||body.baseRevision<0||typeof body.capturedAt!=='string'||body.capturedAt.length>40||!Number.isFinite(Date.parse(body.capturedAt))||typeof body.operationId!=='string'||!/^[0-9a-f-]{36}$/.test(body.operationId)||typeof body.manifestRevision!=='string'||!/^[a-f0-9]{64}$/.test(body.manifestRevision))throw new Fault(400,'invalid_playback_state');
          const manifest=await nativeGet(`/audiobooks/${bookId}/manifest`);
          if(!manifest.assets?.some(a=>a.assetId===body.assetId&&detail.files.some(f=>f.id===a.fileId)))throw new Fault(404,'asset_not_found');
        }else{
          if(!keys(body,['writes'])||!Array.isArray(body.writes)||body.writes.length!==1)throw new Fault(400,'invalid_narration_progress');
          const w=body.writes[0];const n=w?.narration;
          if(!keys(w,['fileId','kind','percentage','narration'])||w.kind!=='narration'||!finite(w.percentage,100)||!Number.isSafeInteger(w.fileId)||!keys(n,['seconds','fragment','sectionIndex'])||!finite(n.seconds,31536000)||(n.fragment!==null&&(typeof n.fragment!=='string'||n.fragment.length>2048))||(n.sectionIndex!==null&&(!Number.isSafeInteger(n.sectionIndex)||n.sectionIndex<0)))throw new Fault(400,'invalid_narration_progress');
          if(!detail.files.some(f=>f.id===w.fileId&&String(f.format).toLowerCase()==='epub'))throw new Fault(404,'file_not_found');
          target='/reading-progress';
        }
        if(expired(session))throw new Fault(401,'authentication_expired');
        const d=await upstreamJSON(target,{method:'PUT',headers:{Authorization:`Bearer ${session.access}`,'Content-Type':'application/json'},body:JSON.stringify(body)});
        return protectedJSON(200,safeDTO(d));
      }
      // Publication reads use the native EPUB reader route, never the download
      // permission or a ZIP supplied by the browser. Re-admit every dependency.
      const publication=/^\/epub\/([1-9]\d*)\/publication\/([1-9]\d*)\/(.+)$/.exec(path);
      if(['GET','HEAD'].includes(req.method)&&publication&&!url.search){
        const [,bookId,fileId,href]=publication;
        if(!Number.isSafeInteger(Number(bookId))||!Number.isSafeInteger(Number(fileId))||href.length>2048||href.split('/').some(s=>!s||s==='.'||s==='..'||!/^[a-zA-Z0-9_ .()-]+$/.test(s)))throw new Fault(404,'resource_not_found');
        const detail=await nativeGet(`/books/${bookId}`);
        if(detail.id!==Number(bookId)||!detail.files?.some(f=>f.id===Number(fileId)&&String(f.format).toLowerCase()==='epub'))throw new Fault(404,'file_not_found');
        const info=await nativeGet(`/epub/${bookId}/info?fileId=${fileId}`);
        const member=info.manifest?.find(m=>m.href===href);
        const types=['application/xhtml+xml','text/html','text/css','image/png','image/jpeg','image/gif','image/webp','font/woff','font/woff2','font/ttf','font/otf','application/font-woff','application/vnd.ms-opentype'];
        if(!member||!types.includes(member.mediaType)||!Number.isSafeInteger(member.size)||member.size<0||member.size>8*1024*1024||(['application/xhtml+xml','text/html'].includes(member.mediaType)&&!info.spine?.some(s=>s.href===href)))throw new Fault(404,'resource_not_found');
        const r=await call(`/api/v1/epub/${bookId}/file/${href}?fileId=${fileId}`,{headers:{Authorization:`Bearer ${session.access}`}});
        if(!r.ok){await r.body?.cancel();throw new Fault([401,403,404].includes(r.status)?r.status:502,'upstream_rejected');}
        // Buffer bounded publication entries so logout can revoke before bytes escape.
        const chunks=[];let size=0;
        for await(const chunk of r.body){size+=chunk.length;if(size>8*1024*1024)throw new Fault(502,'resource_too_large');chunks.push(chunk);}
        if(expired(session))throw new Fault(401,'authentication_expired');
        res.statusCode=200;res.setHeader('Content-Type',member.mediaType);res.setHeader('X-Content-Type-Options','nosniff');
        res.setHeader('Content-Security-Policy',"default-src 'none'; script-src 'none'; connect-src 'none'; object-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; sandbox");
        return res.end(req.method==='HEAD'?undefined:Buffer.concat(chunks));
      }
      const epub=/^\/epub\/([1-9]\d*)\/(media-overlay|info)(?:\/file\/(.+))?$/.exec(path);
      const epubQuery=epub&&/^\?fileId=[1-9]\d*$/.test(url.search);
      let epubStream=false;
      if(['GET','HEAD'].includes(req.method)&&epub&&epubQuery){
        const fileId=Number(url.searchParams.get('fileId'));
        const detail=await nativeGet(`/books/${epub[1]}`);
        if(!Number.isSafeInteger(fileId)||detail.id!==Number(epub[1])||!Array.isArray(detail.files)||!detail.files.some(f=>f.id===fileId&&String(f.format).toLowerCase()==='epub'))throw new Fault(404,'file_not_found');
        if(!epub[3])return protectedJSON(200,safeDTO(await nativeGet(path+url.search)));
        if(epub[2]!=='media-overlay'||epub[3].length>2048||epub[3].split('/').some(s=>!s||s==='.'||s==='..'||!/^[a-zA-Z0-9_ .()-]+$/.test(s)))throw new Fault(404,'resource_not_found');
        const playlist=await nativeGet(`/epub/${epub[1]}/media-overlay${url.search}`);
        if(!Array.isArray(playlist.resources)||!playlist.resources.some(r=>r.href===epub[3]&&typeof r.mediaType==='string'&&r.mediaType.startsWith('audio/')))throw new Fault(404,'resource_not_found');
        epubStream=true;
      }
      if(req.method==='GET'&&audiobook&&!url.search){
        const detail=await nativeGet(`/books/${audiobook[1]}`);
        if(detail.id!==Number(audiobook[1]))throw new Fault(502,'invalid_book_response');
        return protectedJSON(200,safeDTO(await nativeGet(path)));
      }
      const asset=/^\/audiobooks\/([1-9]\d*)\/assets\/(aud_[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})\/content$/.exec(path);
      const assetQuery=asset&&[...url.searchParams].every(([k,v])=>k==='v'&&/^[a-zA-Z0-9_-]{1,128}$/.test(v))&&[...url.searchParams].length<=1;
      if(['GET','HEAD'].includes(req.method)&&asset&&assetQuery){
        const detail=await nativeGet(`/books/${asset[1]}`);
        const manifest=await nativeGet(`/audiobooks/${asset[1]}/manifest`);
        if(detail.id!==Number(asset[1])||!Array.isArray(detail.files)||!Array.isArray(manifest.assets)||!manifest.assets.some(a=>a.assetId===asset[2]&&detail.files.some(f=>f.id===a.fileId)))throw new Fault(404,'asset_not_found');
      }
      const access=/^\/books\/([1-9]\d*)\/access$/.exec(path);
      if(req.method==='GET'&&access&&!url.search) {
        let d;
        const init={headers:{Authorization:`Bearer ${session.access}`}};
        try{d=await upstreamJSON(`/books/${access[1]}`,init);}catch(e){if(e.status!==401)throw e;await rotate(session);if(expired(session))throw new Fault(401,'authentication_expired');init.headers.Authorization=`Bearer ${session.access}`;d=await upstreamJSON(`/books/${access[1]}`,init);}
        if(d.id!==Number(access[1])||!Array.isArray(d.files))throw new Fault(502,'invalid_book_response');
        const escape=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
        const accessPrefix=(route||'/bookorbit')+'/api/v1';
        const links=d.files.filter(f=>Number.isSafeInteger(f.id)&&f.id>0).map(f=>`<li><a href="${accessPrefix}/books/${access[1]}/files/${f.id}/download">Download ${escape(f.format)} file</a></li>`).join('');
        const html=`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>BookOrbit files</title><h1>${escape(d.title)}</h1><p>Listen inside Absorb using the book's Absorb action. Prepared narrated EPUBs support in-app Read Along with native passage timing. Other formats are not an embedded reader. Downloads require your BookOrbit download permission.</p><img width="160" alt="Book cover" src="${accessPrefix}/books/${access[1]}/cover?medium=ebook"><ul>${links}</ul><p><a href="/absorb/">Return to Absorb</a></p></html>`;
        if(expired(session))throw new Fault(401,'authentication_expired');
        res.setHeader('Content-Type','text/html; charset=utf-8');res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('Content-Security-Policy',"default-src 'none'; img-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'");res.statusCode=200;return res.end(html);
      }
      // Only fixed native cover routes and a file proven to belong to this book.
      const cover=/^\/books\/([1-9]\d*)\/(cover|thumbnail)$/.exec(path);
      const file=/^\/books\/([1-9]\d*)\/files\/([1-9]\d*)\/(download)$/.exec(path);
      const validCoverQuery=cover && [...url.searchParams].every(([k,v])=>
        (k==='medium'&&['ebook','audio'].includes(v))||(k==='strict'&&v==='true')||(k==='t'&&v.length<=200)) &&
        [...new Set(url.searchParams.keys())].length===[...url.searchParams.keys()].length;
      if(['GET','HEAD'].includes(req.method)&&((cover&&validCoverQuery)||(file&&!url.search)||(asset&&assetQuery)||epubStream)) {
        if(file) {
          let detail;
          try {detail=await upstreamJSON(`/books/${file[1]}`,{headers:{Authorization:`Bearer ${session.access}`}});}
          catch(e){if(e.status!==401)throw e;await rotate(session);detail=await upstreamJSON(`/books/${file[1]}`,{headers:{Authorization:`Bearer ${session.access}`}});}
          if(detail.id!==Number(file[1])||!Array.isArray(detail.files)||!detail.files.some(f=>f.id===Number(file[2])))throw new Fault(404,'file_not_found');
        }
        if(expired(session))throw new Fault(401,'authentication_expired');
        const controller=new AbortController();
        const abort=()=>{if(!res.writableFinished)controller.abort();};res.once('close',abort);
        try {
          const headers={Authorization:`Bearer ${session.access}`};
          for(const k of ['range','if-range','if-none-match'])if(req.headers[k])headers[k]=req.headers[k];
          const target=file?`/books/files/${file[2]}/download`:path+url.search;
          let r=await call('/api/v1'+target,{method:req.method,headers,signal:controller.signal});
          if(r.status===401){await r.body?.cancel();await rotate(session);if(expired(session))throw new Fault(401,'authentication_expired');headers.Authorization=`Bearer ${session.access}`;r=await call('/api/v1'+target,{method:req.method,headers,signal:controller.signal});}
          if(![200,206,304,416].includes(r.status)){await r.body?.cancel();throw new Fault([401,403,404,429].includes(r.status)?r.status:502,'upstream_rejected');}
          if(expired(session)){await r.body?.cancel();throw new Fault(401,'authentication_expired');}
          res.statusCode=r.status;
          for(const k of ['content-type','content-length','content-range','accept-ranges','etag','last-modified']){const v=r.headers.get(k);if(v)res.setHeader(k,v);}
          res.setHeader('X-Content-Type-Options','nosniff');
          res.setHeader('Content-Security-Policy',"default-src 'none'; sandbox");
          if(file)res.setHeader('Content-Disposition','attachment');
          if(req.method==='HEAD'||[304,416].includes(r.status)){await r.body?.cancel();return res.end();}
          if(!r.body)return res.end();
          await pipeline(Readable.fromWeb(r.body),res);return;
        }finally{res.off('close',abort);}
      }
      const read = req.method==='GET' && /^(?:\/app-info|\/libraries(?:\/[1-9]\d*(?:\/stats)?)?|\/books\/[1-9]\d*(?:\/audio-progress|\/progress)?)$/.test(path);
      const query = req.method==='POST' && /^\/libraries\/[1-9]\d*\/books$/.test(path);
      if((read||query)&&!url.search) {
        if(query && (!body || typeof body!=='object' || Array.isArray(body) || Object.keys(body).some(k=>!['filter','sort','pagination','collapseSeries','q'].includes(k))))throw new Fault(400,'invalid_query');
        const init={method:req.method,headers:{Authorization:`Bearer ${session.access}`,'Content-Type':'application/json'},...(query?{body:JSON.stringify(body)}:{})};
        let d;
        try{d=await upstreamJSON(path,init);}catch(e){if(e.status!==401)throw e;await rotate(session);if(session.revoked)throw new Fault(401,'authentication_expired');init.headers.Authorization=`Bearer ${session.access}`;d=await upstreamJSON(path,init);}
        return protectedJSON(200,safeDTO(d));
      }
      return json(res,404,{error:'unsupported_endpoint'});
    } catch(e) {if(res.headersSent||res.destroyed){res.destroy();return;}return json(res,e instanceof Fault?e.status:502,{error:e instanceof Fault?e.code:'upstream_unavailable'});}
  };
  app.dispose=async()=>{clearInterval(timer);await Promise.all([...sessions].map(([id,s])=>retire(id,s)));};
  return app;
}
