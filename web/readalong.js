/* Trusted host only. Publisher markup never receives script execution. */
(() => {
  'use strict';
  const tags=new Set('p div span section article aside header footer main h1 h2 h3 h4 h5 h6 em strong b i u s small sub sup blockquote pre code br hr ol ul li dl dt dd figure figcaption table thead tbody tfoot tr td th caption img a'.split(' '));
  const styles=new Set('color background-color font-size font-style font-weight font-family text-align text-indent text-decoration line-height margin margin-top margin-bottom margin-left margin-right padding border border-bottom display white-space'.split(' '));
  const safePath=p=>typeof p==='string'&&p.length<=2048&&p.split('/').every(s=>s&&s!=='.'&&s!=='..'&&/^[a-zA-Z0-9_ .()-]+$/.test(s));
  const families=Object.freeze({serif:'Georgia,serif',sans:'Arial,Helvetica,sans-serif',system:'system-ui,sans-serif'});
  const palettes=Object.freeze({dark:['dark','#101114','#e2e6ec','#253e5b','#f2f6fc'],sepia:['light','#f4ecd8','#382b1f','#d8c49c','#21190f'],light:['light','#ffffff','#202124','#dbeafe','#142c4c']});
  function normalize(value) {
    const p=value&&typeof value==='object'?value:{};
    const number=(v,f,min,max)=>typeof v==='number'&&Number.isFinite(v)?Math.min(max,Math.max(min,v)):f;
    return {size:number(p.size,20,14,36),spacing:number(p.spacing,1.75,1.2,2.2),family:typeof p.family==='string'&&Object.hasOwn(families,p.family)?p.family:'serif',theme:typeof p.theme==='string'&&Object.hasOwn(palettes,p.theme)?p.theme:'dark'};
  }
  function appearanceCSS(p) {
    const [scheme,bg,fg,highlight,highlightText]=palettes[p.theme];
    return `:root{color-scheme:${scheme}}html,body{background:${bg}!important;color:${fg}!important}body{box-sizing:border-box;max-width:48rem;margin:0 auto!important;padding:24px 22px 45vh!important;overflow-wrap:anywhere;font-size:${p.size}px!important}body,body *{font-family:${families[p.family]}!important;line-height:${p.spacing}!important;color:${fg}!important}body *{background-color:transparent!important}body :is(p,div,span,section,article,aside,header,footer,main,li,blockquote,td,th,dd,dt,pre,code,a){font-size:inherit!important}h1{font-size:2em!important}h2{font-size:1.5em!important}h3{font-size:1.17em!important}h4{font-size:1em!important}h5,small,figcaption,caption{font-size:.85em!important}h6{font-size:.75em!important}img{max-width:100%;height:auto}[data-readalong-active],[data-readalong-active] *{background:${highlight}!important;color:${highlightText}!important;border-radius:4px;box-shadow:0 0 0 3px ${highlight}}`;
  }
  function create(frame,base,info) {
    const baseURL=new URL(base,location.href);
    if(baseURL.origin!==location.origin||!/^\/bookorbit\/(?:sessions\/[a-zA-Z0-9_-]+\/)?api\/v1\/epub\/[1-9]\d*\/publication\/[1-9]\d*\/$/.test(baseURL.pathname))throw Error('Invalid publication owner');
    if(frame.getAttribute('sandbox')!=='allow-same-origin')throw Error('Reader requires a script-disabled sandbox');
    const spine=new Set(info.spine.map(s=>s.href));
    const members=new Map(info.manifest.filter(m=>safePath(m.href)).map(m=>[m.href,m.mediaType]));
    let disposed=false,epoch=0,docHref=null,requested=null,active=null,block=null,manualUntil=0,abort=null,loading=null;
    let appearance=normalize(null),trustedStyle=null;
    function setAppearance(value) {
      if(disposed)return;
      appearance=normalize(value);
      const doc=frame.contentDocument,win=frame.contentWindow;
      if(!trustedStyle||trustedStyle.ownerDocument!==doc||!doc?.body)return;
      // Preserve the first visible publication block, even paused or Follow off.
      const blocks='p,li,blockquote,h1,h2,h3,h4,h5,h6,pre,figcaption,td,th,div';
      const visible=[...doc.body.querySelectorAll(blocks)].find(el=>{
        const rect=el.getBoundingClientRect();
        return rect.bottom>0&&rect.top<frame.clientHeight&&!el.querySelector(blocks);
      });
      const top=visible?.getBoundingClientRect().top,scroll=win.scrollY;
      trustedStyle.textContent=appearanceCSS(appearance);
      if(visible)win.scrollTo({top:scroll+visible.getBoundingClientRect().top-top,behavior:'instant'});
    }
    function resource(value,href,type) {
      if(typeof value!=='string'||/[\\%]/.test(value))return null;
      const u=new URL(value,new URL(href,baseURL));
      if(u.origin!==baseURL.origin||!u.pathname.startsWith(baseURL.pathname)||u.search||u.hash)return null;
      const path=decodeURIComponent(u.pathname.slice(baseURL.pathname.length));
      return safePath(path)&&type(members.get(path))?u.href:null;
    }
    function sanitize(text,href) {
      // Template contents are inert: parsing malicious <img> cannot send a request.
      const source=document.createElement('template');source.innerHTML=text;
      const clean=document.implementation.createHTMLDocument('Read Along');
      const csp=clean.createElement('meta');csp.httpEquiv='Content-Security-Policy';
      const scope=baseURL.href;
      csp.content=`default-src 'none'; script-src 'none'; connect-src 'none'; object-src 'none'; frame-src 'none'; media-src 'none'; form-action 'none'; base-uri 'none'; img-src ${scope}; font-src ${scope}; style-src 'unsafe-inline' ${scope}`;
      clean.head.append(csp);
      const meta=clean.createElement('meta');meta.name='referrer';meta.content='no-referrer';clean.head.append(meta);
      for(const link of source.content.querySelectorAll('link[rel="stylesheet"]')) {
        const url=resource(link.getAttribute('href'),href,t=>t==='text/css');
        if(url){const el=clean.createElement('link');el.rel='stylesheet';el.href=url;clean.head.append(el);}
      }
      function copy(node,parent) {
        if(node.nodeType===Node.TEXT_NODE){parent.append(clean.createTextNode(node.textContent));return;}
        if(node.nodeType!==Node.ELEMENT_NODE)return;
        const tag=node.localName.toLowerCase();
        if(!tags.has(tag)) {
          if(['html','body','head'].includes(tag))for(const child of node.childNodes)copy(child,parent);
          return;
        }
        const el=clean.createElement(tag);
        for(const name of ['id','class','lang','dir','title','alt','colspan','rowspan'])if(node.hasAttribute(name))el.setAttribute(name,node.getAttribute(name));
        for(const prop of styles){const value=node.style?.getPropertyValue(prop);if(value&&!/url\s*\(|@|expression|[\\<>]/i.test(value))el.style.setProperty(prop,value);}
        if(tag==='img'){const url=resource(node.getAttribute('src'),href,t=>/^image\/(png|jpeg|gif|webp)$/.test(t));if(url)el.src=url;}
        if(tag==='a'){const dest=node.getAttribute('href');if(dest?.startsWith('#'))el.setAttribute('href',dest);}
        parent.append(el);for(const child of node.childNodes)copy(child,el);
      }
      for(const child of source.content.childNodes)copy(child,clean.body);
      const theme=clean.createElement('style');theme.textContent=appearanceCSS(appearance);clean.head.append(theme);
      return '<!doctype html>'+clean.documentElement.outerHTML;
    }
    function highlight() {
      if(disposed||!requested||docHref!==requested.href)return;
      const doc=frame.contentDocument;if(!doc?.body)return;
      const next=requested.fragment?doc.getElementById(requested.fragment):null;
      if(active!==next){active?.removeAttribute('data-readalong-active');active=next;active?.setAttribute('data-readalong-active','');}
      const nextBlock=next?.closest('p,li,blockquote,h1,h2,h3,div')??next;
      if(requested.follow&&nextBlock&&block!==nextBlock&&performance.now()>manualUntil){
        block=nextBlock;const rect=nextBlock.getBoundingClientRect();
        if(rect.top<30||rect.bottom>frame.clientHeight-50)nextBlock.scrollIntoView({block:'center',behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'instant':'smooth'});
      }
    }
    async function show(href,fragment,follow) {
      if(disposed)return;
      if(!safePath(href)||!spine.has(href)||!['application/xhtml+xml','text/html'].includes(members.get(href)))throw Error('Not a publication spine item');
      requested={href,fragment,follow};
      if(docHref===href){highlight();return;}
      if(loading?.href===href)return loading.promise;
      const current=++epoch;abort?.abort();abort=new AbortController();
      const promise=(async()=>{
        try {
          const r=await fetch(new URL(href,baseURL),{credentials:'same-origin',cache:'no-store',signal:abort.signal});
          if(!r.ok)throw Error(r.status===401?'Sign in again to read this book.':'This chapter could not be loaded.');
          const raw=await r.text();if(raw.length>8*1024*1024)throw Error('Chapter exceeds reader limit.');
          if(disposed||current!==epoch)return;
          await new Promise(resolve=>{frame.onload=()=>{
            if(!disposed&&current===epoch){docHref=href;active=block=null;const doc=frame.contentDocument;
              trustedStyle=doc.head.lastElementChild;setAppearance(appearance);
              doc.addEventListener('click',e=>{e.preventDefault();const a=e.target.closest?.('a');if(a?.hash)doc.getElementById(decodeURIComponent(a.hash.slice(1)))?.scrollIntoView();},true);
              for(const event of ['wheel','touchstart','pointerdown','keydown'])doc.addEventListener(event,()=>{manualUntil=performance.now()+5000;},{passive:true});
              highlight();
            }resolve();};frame.srcdoc=sanitize(raw,href);});
        }catch(e){if(disposed||current!==epoch||e.name==='AbortError')return;docHref=null;frame.srcdoc='';throw e;}
        finally{if(current===epoch)loading=null;}
      })();loading={href,promise};return promise;
    }
    return {show,setAppearance,dispose(){disposed=true;epoch++;abort?.abort();frame.onload=null;frame.srcdoc='';requested=active=block=trustedStyle=null;}};
  }
  window.AbsorbReadAlong=Object.freeze({create});
})();
