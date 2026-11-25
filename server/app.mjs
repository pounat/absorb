import { randomBytes } from "node:crypto";
import { config, transport, selectUpstream } from "./upstream.mjs";
import { mediaAllowed, streamMedia } from "./media.mjs";
import { playbackManager } from "./playback.mjs";
import { authClient, credentials, envelopeDTO, userDTO } from "./auth.mjs";
import { Fault, json, readJSON, loginLimiter } from "./http.mjs";
import {
  sanitize,
  accessible,
  filterItems,
  readAllowed,
  readQuery,
  getJSON,
} from "./reads.mjs";
export function createApp(options) {
  const upstream = config(options);
  const sessions = new Map();
  let pendingLogins = 0;
  const admit = loginLimiter(options.loginLimit, options.now);
  const call = upstream ? transport(upstream) : null;
  const { refresh, authorized } = authClient(call);
  const playbacks = new Map();
  const now = options.now ?? Date.now;
  const policy = {
    absoluteMs: 7 * 86400000,
    idleMs: 86400000,
    maxSessions: 256,
    sweepMs: 60000,
    ...options.sessionPolicy,
  };
  for (const [key, value] of Object.entries(policy)) {
    if (!Number.isSafeInteger(value) || value <= 0 ||
      (key === "sweepMs" && value > 2147483647))
      throw new Error(`invalid sessionPolicy.${key}`);
  }
  const cookie = (value, maxAge) =>
    `absorb_web_session=${value}; Path=/; HttpOnly; SameSite=Strict; Max-Age=${maxAge}${options.secureCookie === false ? "" : "; Secure"}`;
  async function retire(id, session) {
    if (session.retiring) return session.retiring;
    session.revoked = true;
    session.retiring = (async () => {
      try {
        await session.playback.logout(session);
        const r = await session.call("/logout", {
          method: "POST", headers: { "x-refresh-token": session.refresh },
        });
        await r.body?.cancel();
      } catch {} finally {
        session.access = session.refresh = null;
        sessions.delete(id);
        if (![...sessions.values()].some(s => s.playbackKey === session.playbackKey))
          playbacks.delete(session.playbackKey);
      }
    })();
    return session.retiring;
  }
  const expired = (s) => s.revoked || now() - s.lastSeen >= policy.idleMs ||
    now() - s.createdAt >= policy.absoluteMs;
  function sweep() {
    for (const [id, session] of sessions)
      if (expired(session)) void retire(id, session);
  }
  const timer = setInterval(sweep, policy.sweepMs);
  timer.unref();
  const app = async (req, res) => {
    res.setHeader("Cache-Control", "private, no-store");
    res.setHeader("Referrer-Policy", "no-referrer");
    let id, session;
    const routeMatch = /^\/sessions\/([A-Za-z0-9_-]{24})(?=\/)/.exec(req.url);
    const route = routeMatch ? routeMatch[0] : '';
    if (route) req.url = req.url.slice(route.length);
    const setHeader = res.setHeader.bind(res);
    res.setHeader = (name,value) => setHeader(name,
      route && name.toLowerCase()==='set-cookie' && typeof value==='string'
        ? value.replace('Path=/;',`Path=${route};`) : value);
    if (route) {
      const end = res.end.bind(res);
      res.end = (chunk, ...args) => {
        if (typeof chunk === 'string' && String(res.getHeader('Content-Type')).includes('application/json')) {
          chunk = chunk.replace(/"contentUrl":"\/(api|public)\//g, `"contentUrl":"${route}/$1/`);
        }
        return end(chunk, ...args);
      };
    }
    // Buffered protected responses retain no authority across awaits. Check
    // immediately before the synchronous JSON send, with no intervening await.
    // Already-admitted media streams use their separate documented policy.
    const protectedJSON = (status, value) => {
      if (session.revoked) throw new Fault(401, "authentication_expired");
      return json(res, status, value);
    };
    try {
      const url = new URL(req.url, "http://bff.invalid");
      const path = url.pathname;
      if (req.method === "GET" && path === "/ping") {
        res.writeHead(200, { "Content-Type": "text/plain" });
        return res.end("pong");
      }
      if (req.method === "GET" && path === "/status") {
        // No arbitrary pre-auth probe: browser login selects and validates its target.
        if (!call) return json(res, 200, { app: "audiobookshelf", isInit: true, authMethods: ["local"] });
        const r = await call("/status");
        if (!r.ok) {
          await r.body?.cancel();
          throw new Fault(502, "upstream_unavailable");
        }
        const data = await r.json();
        return json(res, 200, {
          app: "audiobookshelf",
          serverVersion: data.serverVersion,
          isInit: data.isInit === true,
          authMethods: ["local"],
        });
      }
      sweep();
      let body;
      if (!["GET", "HEAD"].includes(req.method)) {
        if (!options.origins.includes(req.headers.origin))
          throw new Fault(403, "origin_denied");
        body = await readJSON(req);
      }
      if (req.method === "POST" && path === "/login") {
        if (
          !body ||
          typeof body.username !== "string" ||
          typeof body.password !== "string" ||
          !body.username ||
          !body.password ||
          body.username.length > 512 ||
          body.password.length > 4096
        )
          throw new Fault(400, "invalid_credentials");
        admit(req.socket.remoteAddress);
        if (sessions.size + pendingLogins >= policy.maxSessions)
          throw new Fault(503, "session_capacity");
        pendingLogins++;
        try {
          const selected = body.serverUrl === undefined && upstream ? upstream : selectUpstream(body.serverUrl, options);
          const selectedCall = transport(selected, { ...options, selected: body.serverUrl !== undefined });
          const key = selected.href.replace(/\/+$/, "");
          const response = await selectedCall("/login", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "x-return-tokens": "true",
            },
            body: JSON.stringify({
              username: body.username,
              password: body.password,
            }),
          });
          if (response.status !== 200) {
            await response.body?.cancel();
            return json(
              res,
              response.status === 401 ? 401 : response.status === 429 ? 429 : 502,
              {
                error:
                  response.status === 401
                    ? "authentication_failed"
                    : response.status === 429
                      ? "login_rate_limited"
                      : "upstream_unavailable",
              },
            );
          }
          const data = await response.json();
          const id = randomBytes(32).toString("base64url");
          const auth = credentials(data);
          if (!playbacks.has(key)) playbacks.set(key, playbackManager(authorized));
          const sessionRoute = body.sessionRouting === true ? '/sessions/' + randomBytes(18).toString('base64url') : '';
          sessions.set(id, { ...auth, route: sessionRoute, call: selectedCall, playbackKey: key, playback: playbacks.get(key), createdAt: now(), lastSeen: now() });
          res.setHeader("Set-Cookie", cookie(id, Math.ceil(policy.absoluteMs / 1000)).replace('Path=/;', `Path=${sessionRoute || '/'};`));
          return json(res, 200, {...envelopeDTO(data), ...(sessionRoute ? {webSessionRoute:sessionRoute} : {})});
        } finally {
          pendingLogins--;
        }
      }
      id = req.headers.cookie
        ?.split(";")
        .map((x) => x.trim())
        .find((x) => x.startsWith("absorb_web_session="))
        ?.slice(19);
      session = sessions.get(id);
      if (session && expired(session)) void retire(id, session);
      if (!session || session.revoked || (session.route ?? '') !== route) {
        if (id) res.setHeader("Set-Cookie", cookie("", 0));
        return json(res, 401, { error: "authentication_required" });
      }
      session.lastSeen = now();
      if (req.method === "POST" && path === "/auth/refresh")
        return protectedJSON(200, envelopeDTO(await refresh(session)));
      if (req.method === "POST" && path === "/logout") {
        const retiring = retire(id, session);
        res.setHeader("Set-Cookie", cookie("", 0));
        await retiring;
        return json(res, 200, { redirect_url: null });
      }
      if (["GET", "HEAD"].includes(req.method) && mediaAllowed.test(path))
        return await streamMedia(req, res, url, session, authorized, session.playback);
      const start = path.match(
        /^\/api\/items\/([A-Za-z0-9_-]+)\/play(?:\/([A-Za-z0-9_-]+))?$/,
      );
      if (req.method === "POST" && start)
        return protectedJSON(
          200,
          await session.playback.start(session, start[1], start[2], body),
        );
      const operation = path.match(
        /^\/api\/session\/([A-Za-z0-9_-]+)(?:\/(sync|close))?$/,
      );
      if (operation && req.method === "POST" && operation[2]) {
        await session.playback.mutate(session, operation[1], operation[2], body);
        res.writeHead(200, { "Content-Type": "text/plain" });
        return res.end("OK");
      }
      if (operation && req.method === "GET" && !operation[2])
        return protectedJSON(200, await session.playback.get(session, operation[1]));
      if (req.method === "GET" && path === "/api/me") {
        const r = await authorized(session, path);
        if (!r.ok) {
          await r.body?.cancel();
          throw new Fault(
            r.status >= 400 && r.status < 500 ? r.status : 502,
            "upstream_rejected",
          );
        }
        const data = await r.json();
        if (data.id !== session.userId)
          throw new Fault(502, "identity_mismatch");
        return protectedJSON(r.status, userDTO(data));
      }
      if (
        req.method === "GET" &&
        /^\/api\/(?:collections|libraries\/[A-Za-z0-9_-]+\/collections)$/.test(
          path,
        )
      )
        return protectedJSON(200, {
          results: [],
          collections: [],
          total: 0,
          limit: 0,
          page: 0,
        });
      if (
        req.method === "GET" &&
        !path.endsWith("/remove-from-continue-listening") &&
        readAllowed.test(path)
      ) {
        const entities = /^\/api\/(?:authors\/|series\/|libraries\/[A-Za-z0-9_-]+\/(?:search|personalized|authors|series|narrators)(?:\/|$))/.test(path) ||
          (url.searchParams.get("include") ?? "").split(",").includes("filterdata");
        const scope = await accessible(authorized, session, { entities });
        const library = path.match(/^\/api\/libraries\/([A-Za-z0-9_-]+)/);
        const item = path.match(/^\/api\/items\/([A-Za-z0-9_-]+)/);
        if (
          (library && !scope.libraries.has(library[1])) ||
          (item && !scope.ids.has(item[1]))
        )
          throw new Fault(403, "item_denied");
        const query = readQuery(url);
        const requestedLibrary = url.searchParams.get("library") ?? library?.[1];
        if (requestedLibrary && (!scope.libraries.has(requestedLibrary) ||
          (library && library[1] !== requestedLibrary)))
          throw new Fault(403, "item_denied");
        const author = path.match(/^\/api\/authors\/([A-Za-z0-9_-]+)$/);
        const series = path.match(/^\/api\/(?:series|libraries\/[A-Za-z0-9_-]+\/series)\/([A-Za-z0-9_-]+)$/);
        const entity = author ?? series;
        let allowed = new Set([...scope.ids].filter((id) =>
          !requestedLibrary || scope.itemLibraries.get(id) === requestedLibrary));
        if (entity) {
          const associated = (author ? scope.authors : scope.series).get(entity[1]);
          allowed = new Set([...(associated ?? [])].filter((id) =>
            !requestedLibrary || scope.itemLibraries.get(id) === requestedLibrary));
          if (!allowed.size) throw new Fault(403, "item_denied");
        }
        const data = await getJSON(authorized, session, path + query);
        if (entity && data.id !== entity[1]) throw new Fault(502, "identity_mismatch");
        const listKind = path.match(/^\/api\/libraries\/[A-Za-z0-9_-]+\/(authors|series)$/)?.[1];
        const safe = sanitize(filterItems(data, allowed, scope, series ? "series" : listKind ? `${listKind}-list` : undefined) ?? {});
        if (entity) for (const key of ["numBooks", "totalBooks", "numItems", "count", "total"])
          if (key in safe) safe[key] = allowed.size;
        return protectedJSON(200, safe);
      }
      return json(res, 404, { error: "unsupported_endpoint" });
    } catch (error) {
      if (session?.revoked) {
        void retire(id, session);
        if (!res.headersSent) res.setHeader("Set-Cookie", cookie("", 0));
      }
      if (res.headersSent) {
        res.destroy();
        return;
      }
      return json(res, error instanceof Fault ? error.status : 502, {
        error: error instanceof Fault ? error.code : "upstream_unavailable",
      });
    }
  };
  app.dispose = async () => {
    clearInterval(timer);
    await Promise.all([...sessions.values()].map((s) => s.retiring));
  };
  return app;
}
