import {createApp} from './app.mjs';
import {createBookOrbitApp} from './bookorbit.mjs';

// One origin, independent provider authorities, one shared destination policy.
// There is no default destination; each login must carry its Server URL.
export function createProviderApp(options) {
  const abs=createApp({...options,upstream:undefined});
  const bookorbit=createBookOrbitApp({...options,upstream:undefined});
  const app=(req,res)=>req.url.startsWith('/bookorbit/')?bookorbit(req,res):abs(req,res);
  app.dispose=async()=>{await Promise.all([abs.dispose(),bookorbit.dispose()]);};
  return app;
}
