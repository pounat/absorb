import test from "node:test";
import assert from "node:assert/strict";
import http from "node:http";

const origin = "https://absorb.example.test";
const envelope = () => ({
  user: {
    id: "reader",
    username: "synthetic",
    accessToken: "PRIVATE_ACCESS",
    refreshToken: "PRIVATE_REFRESH",
    token: "PRIVATE_LEGACY",
    mediaProgress: [],
  },
  serverSettings: { version: "2.36.0" },
  userDefaultLibraryId: "lib",
});
async function listen(handler) {
  const server = http.createServer(handler);
  await new Promise((r) => server.listen(0, "127.0.0.1", r));
  return {
    url: `http://127.0.0.1:${server.address().port}`,
    close: () =>
      new Promise((r) => {
        server.closeAllConnections();
        server.close(r);
      }),
  };
}
async function setup(t, handler, options = {}) {
  const calls = [];
  const expandedItems = new Map();
  const upstream = await listen(async (req, res) => {
    // Model the pinned wire seam for legacy fixtures too: /items pages are
    // minified; expanded entity arrays exist only in the private batch read.
    const library = req.url.match(/^\/api\/libraries\/([A-Za-z0-9_-]+)\/items(?:\?|$)/)?.[1];
    if (library) {
      const end = res.end.bind(res);
      res.end = (raw) => {
        const data = JSON.parse(raw);
        for (const item of data.results ?? []) {
          expandedItems.set(item.id, { ...item, libraryId: item.libraryId ?? library,
            media: { ...item.media, metadata: item.media?.metadata ?? {} } });
          if (item.media?.metadata) {
            const metadata = { ...item.media.metadata };
            for (const [key, nameKey] of [["authors", "authorName"], ["series", "seriesName"], ["narrators", "narratorName"]]) {
              if (Array.isArray(metadata[key])) metadata[nameKey] = metadata[key].map((x) => typeof x === "string" ? x : x.name).join(", ");
              delete metadata[key];
            }
            item.media = { ...item.media, metadata };
          }
        }
        return end(JSON.stringify(data));
      };
    }
    let raw = "";
    for await (const c of req) raw += c;
    const body = raw ? JSON.parse(raw) : undefined;
    calls.push({
      path: req.url,
      method: req.method,
      headers: req.headers,
      body,
    });
    if (handler && (await handler(req, res, body))) return;
    if (req.url === "/api/items/batch/get" && req.method === "POST") {
      res.setHeader("Content-Type", "application/json");
      res.end(JSON.stringify({ libraryItems: body.libraryItemIds.map((id) => expandedItems.get(id)).filter(Boolean) }));
      return;
    }
    res.setHeader("Content-Type", "application/json");
    if (req.url === "/login" || req.url === "/auth/refresh")
      res.end(JSON.stringify(envelope()));
    else if (req.url === "/logout") res.end("{}");
    else if (req.url === "/api/me") res.end(JSON.stringify(envelope().user));
    else {
      res.statusCode = 404;
      res.end("{}");
    }
  });
  t.after(() => upstream.close());
  const { createApp } = await import("../app.mjs");
  const app = createApp({
      upstream: upstream.url,
      origins: [origin],
      secureCookie: false,
      ...options,
    });
  const bff = await listen(app);
  t.after(() => app.dispose());
  t.after(async () => {
    await bff.close();
    await upstream.close();
  });
  const request = (path, init = {}) =>
    fetch(bff.url + path, {
      ...init,
      headers: { Origin: origin, ...init.headers },
    });
  const login = async () => {
    const r = await request("/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: "synthetic",
        password: "SYNTHETIC_PASSWORD",
      }),
    });
    assert.equal(r.status, 200);
    return { cookie: r.headers.get("set-cookie").split(";")[0], response: r };
  };
  return { calls, request, login, url: bff.url };
}
test("synthetic login keeps real credentials private and cookie exclusively authenticates identity", async (t) => {
  const { request, login, calls } = await setup(t);
  const { cookie, response } = await login();
  assert.match(response.headers.get("set-cookie"), /HttpOnly/);
  assert.match(response.headers.get("set-cookie"), /SameSite=Strict/);
  assert.match(response.headers.get("set-cookie"), /Path=\//);
  const data = await response.json();
  assert.equal(data.user.accessToken, "browser-cookie");
  assert.equal(data.user.refreshToken, "browser-cookie");
  assert.equal(JSON.stringify(data).includes("PRIVATE"), false);
  assert.equal(calls[0].headers["x-return-tokens"], "true");
  assert.equal(
    (
      await request("/api/me", {
        headers: { Authorization: "Bearer PRIVATE_ACCESS" },
      })
    ).status,
    401,
  );
  const me = await request("/api/me?token=PRIVATE_ACCESS", {
    headers: { Cookie: cookie },
  });
  assert.equal(me.status, 200);
  assert.equal((await me.json()).accessToken, "browser-cookie");
  assert.equal(calls.at(-1).path, "/api/me");
  assert.equal(calls.at(-1).headers.authorization, "Bearer PRIVATE_ACCESS");
});
test("mutation boundary requires exact Origin, bounded JSON, valid credentials and bounded login admission", async (t) => {
  const { request, calls } = await setup(t, null, { loginLimit: 2 });
  for (const bad of [undefined, "https://evil.test", origin + "/"]) {
    const r = await request("/login", {
      method: "POST",
      headers: { Origin: bad ?? "", "Content-Type": "application/json" },
      body: "{}",
    });
    assert.equal(r.status, 403);
  }
  assert.equal(calls.length, 0);
  assert.equal(
    (await request("/login", { method: "POST", body: "{}" })).status,
    415,
  );
  assert.equal(
    (
      await request("/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: "x".repeat(65537),
      })
    ).status,
    413,
  );
  assert.equal(
    (
      await request("/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: "{",
      })
    ).status,
    400,
  );
  assert.equal(
    (
      await request("/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: "{}",
      })
    ).status,
    400,
  );
  for (let n = 0; n < 2; n++)
    assert.equal(
      (
        await request("/login", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: '{"username":"s","password":"p"}',
        })
      ).status,
      200,
    );
  assert.equal(
    (
      await request("/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: '{"username":"s","password":"p"}',
      })
    ).status,
    429,
  );
});
test("refresh is single-flight on definitive 401; logout revokes only this cookie and drops upstream cookies/errors", async (t) => {
  let refreshed = 0;
  const { request, login, calls } = await setup(t, async (req, res) => {
    if (req.url === "/auth/refresh") {
      refreshed++;
      await new Promise((r) => setTimeout(r, 30));
      res.setHeader("Set-Cookie", "upstream=SECRET");
      res.end(
        JSON.stringify({
          ...envelope(),
          user: {
            ...envelope().user,
            accessToken: "NEW_ACCESS",
            refreshToken: "NEW_REFRESH",
          },
        }),
      );
      return true;
    }
    if (
      req.url === "/api/me" &&
      req.headers.authorization === "Bearer PRIVATE_ACCESS"
    ) {
      res.statusCode = 401;
      res.end("SECRET ERROR");
      return true;
    }
  });
  const { cookie } = await login();
  const results = await Promise.all(
    Array.from({ length: 5 }, () =>
      request("/api/me", { headers: { Cookie: cookie } }),
    ),
  );
  assert.deepEqual(
    results.map((x) => x.status),
    [200, 200, 200, 200, 200],
  );
  assert.equal(refreshed, 1);
  const r = await request("/auth/refresh", {
    method: "POST",
    headers: { Cookie: cookie, "Content-Type": "application/json" },
    body: "{}",
  });
  assert.equal(r.status, 200);
  assert.equal(r.headers.get("set-cookie"), null);
  assert.equal(JSON.stringify(await r.json()).includes("NEW_ACCESS"), false);
  const out = await request("/logout", {
    method: "POST",
    headers: { Cookie: cookie, "Content-Type": "application/json" },
    body: "{}",
  });
  assert.equal(out.status, 200);
  assert.match(out.headers.get("set-cookie"), /Max-Age=0/);
  assert.equal(calls.at(-1).path, "/logout");
  assert.equal(calls.at(-1).headers["x-refresh-token"], "NEW_REFRESH");
  assert.equal(
    (await request("/api/me", { headers: { Cookie: cookie } })).status,
    401,
  );
});
test("reads enumerate every accessible page, filter nested metadata/counts, omit collections and deny mutating GETs", async (t) => {
  const { request, login, calls } = await setup(t, (req, res) => {
    let data;
    const u = new URL(req.url, "http://fixture");
    if (u.pathname === "/api/libraries")
      data = {
        libraries: [
          { id: "lib", name: "Synthetic", fullPath: "/private/path" },
        ],
      };
    if (u.pathname === "/api/libraries/lib/items")
      data = {
        results: [
          {
            id: u.searchParams.get("page") === "0" ? "bookA" : "bookB",
            media: { metadata: { title: "Allowed" } },
          },
        ],
        total: 2,
        limit: 1,
        page: Number(u.searchParams.get("page")),
      };
    if (u.pathname === "/api/libraries/lib/personalized")
      data = [
        {
          id: "recent",
          total: 3,
          entities: [
            { id: "bookA", media: { metadata: { title: "Allowed A" } } },
            { id: "hidden", media: { metadata: { title: "EXCLUDED" } } },
            {
              id: "bookB",
              media: {
                metadata: { title: "Allowed B" },
                tracks: [
                  {
                    metadata: { path: "/PRIVATE" },
                    contentUrl: "https://evil.test/?token=SECRET",
                  },
                ],
              },
            },
          ],
        },
        {
          id: "empty",
          entities: [
            { id: "hidden", media: { metadata: { title: "EXCLUDED" } } },
          ],
        },
      ];
    if (data) {
      res.end(JSON.stringify(data));
      return true;
    }
  });
  const { cookie } = await login();
  const auth = { headers: { Cookie: cookie } };
  const r = await request("/api/libraries/lib/personalized", auth);
  assert.equal(r.status, 200);
  const body = await r.json();
  assert.equal(body.length, 1);
  assert.equal(body[0].total, 2);
  assert.equal(body[0].entities.length, 2);
  assert.doesNotMatch(JSON.stringify(body), /EXCLUDED|PRIVATE|evil|SECRET/);
  assert.ok(calls.some((x) => x.path.includes("page=1")));
  const before = calls.length;
  const c = await request("/api/libraries/lib/collections", auth);
  assert.equal(c.status, 200);
  assert.deepEqual((await c.json()).results, []);
  assert.equal(calls.length, before);
  for (const path of [
    "/api/collections/id",
    "/api/me/progress/row/remove-from-continue-listening",
    "/api/users",
    "/api/items/bookA/scan",
    "/api/sessions/open",
  ])
    assert.equal((await request(path, auth)).status, 404);
  assert.equal(calls.length, before);
});
test("permission enumeration fails closed when pagination incomplete", async (t) => {
  const { request, login } = await setup(t, (req, res) => {
    if (req.url === "/api/libraries") {
      res.end('{"libraries":[{"id":"lib"}]}');
      return true;
    }
    if (req.url.startsWith("/api/libraries/lib/items")) {
      res.end('{"results":[],"total":2}');
      return true;
    }
  });
  const { cookie } = await login();
  assert.equal(
    (
      await request("/api/libraries/lib/search?q=test", {
        headers: { Cookie: cookie },
      })
    ).status,
    502,
  );
});
function catalog(req, res) {
  if (req.url === "/api/libraries") {
    res.end('{"libraries":[{"id":"lib"}]}');
    return true;
  }
  if (req.url.startsWith("/api/libraries/lib/items")) {
    res.end(
      '{"results":[{"id":"bookA","media":{}},{"id":"bookB","media":{}}],"total":2}',
    );
    return true;
  }
  return false;
}
test("playback binds ownership, serializes generations/sequences, strips client controls and closes old writer first", async (t) => {
  let n = 0;
  const { request, login, calls } = await setup(t, async (req, res, body) => {
    if (catalog(req, res)) return true;
    if (req.url.endsWith("/play")) {
      res.end(
        JSON.stringify({
          id: `play${++n}`,
          userId: "reader",
          libraryItemId: req.url.split("/")[3],
          duration: 1000,
          audioTracks: [
            {
              index: 4,
              mimeType: "audio/mpeg",
              contentUrl: `/public/session/play${n}/track/4`,
              metadata: { path: "/PRIVATE" },
            },
          ],
        }),
      );
      return true;
    }
    if (/\/api\/session\/play\d+\/(sync|close)$/.test(req.url)) {
      await new Promise((r) => setTimeout(r, 5));
      res.end("OK");
      return true;
    }
  });
  const { cookie } = await login();
  const send = (path, body) =>
    request(path, {
      method: "POST",
      headers: { Cookie: cookie, "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
  const start = await send("/api/items/bookA/play", {
    supportedMimeTypes: ["audio/mpeg"],
    forceDirectPlay: true,
    mediaPlayer: "exo-player",
    deviceInfo: { deviceId: "UNTRUSTED" },
    startOffset: 700,
  });
  assert.equal(start.status, 200);
  const a = await start.json();
  assert.ok(Number.isSafeInteger(a.webGeneration));
  assert.equal(a.audioTracks[0].contentUrl, "/public/session/play1/track/4");
  assert.equal(a.audioTracks[0].metadata, undefined);
  const sent = calls.find((x) => x.path.endsWith("/play")).body;
  assert.equal(sent.forceDirectPlay, false);
  assert.equal(sent.mediaPlayer, "html5");
  assert.notEqual(sent.deviceInfo.deviceId, "UNTRUSTED");
  assert.equal(sent.startOffset, undefined);
  const sync = {
    webGeneration: a.webGeneration,
    webSequence: 1,
    currentTime: 30,
    timeListened: 10,
    duration: 1000,
  };
  assert.equal((await send("/api/session/play1/sync", sync)).status, 200);
  assert.equal((await send("/api/session/play1/sync", sync)).status, 409);
  assert.equal(calls.filter((x) => x.path.endsWith("/sync")).length, 1);
  assert.equal(
    calls.find((x) => x.path.endsWith("/sync")).body.webGeneration,
    undefined,
  );
  const { cookie: other } = await login();
  assert.equal(
    (await request("/api/session/play1", { headers: { Cookie: other } }))
      .status,
    403,
  );
  const b = await (
    await send("/api/items/bookB/play", { supportedMimeTypes: ["audio/mpeg"] })
  ).json();
  assert.ok(b.webGeneration > a.webGeneration);
  const paths = calls.map((x) => x.path);
  assert.ok(
    paths.indexOf("/api/session/play1/close") <
      paths.indexOf("/api/items/bookB/play"),
  );
  assert.equal(
    (await send("/api/session/play1/close", { ...sync, webSequence: 2 }))
      .status,
    409,
  );
  assert.equal(
    (
      await send("/api/session/play2/sync", {
        ...sync,
        webGeneration: b.webGeneration,
        webSequence: 2,
        currentTime: -1,
      })
    ).status,
    400,
  );
  assert.equal(
    (
      await send("/api/session/play2/close", {
        ...sync,
        webGeneration: b.webGeneration,
        webSequence: 2,
      })
    ).status,
    200,
  );
});
test("ambiguous listening writes never retry or accept another increment; session 404 is visible", async (t) => {
  let syncs = 0;
  const { request, login } = await setup(t, (req, res) => {
    if (catalog(req, res)) return true;
    if (req.url.endsWith("/play")) {
      res.end(
        '{"id":"play","userId":"reader","libraryItemId":"bookA","duration":1000,"audioTracks":[]}',
      );
      return true;
    }
    if (req.url.endsWith("/sync")) {
      syncs++;
      res.statusCode = 503;
      res.end("PRIVATE upstream error");
      return true;
    }
  });
  const { cookie } = await login();
  const send = (path, body) =>
    request(path, {
      method: "POST",
      headers: { Cookie: cookie, "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
  const started = await (
    await send("/api/items/bookA/play", { supportedMimeTypes: ["audio/mpeg"] })
  ).json();
  const payload = {
    webGeneration: started.webGeneration,
    webSequence: 1,
    currentTime: 20,
    timeListened: 10,
  };
  assert.equal((await send("/api/session/play/sync", payload)).status, 502);
  assert.equal(
    (await send("/api/session/play/sync", { ...payload, webSequence: 2 }))
      .status,
    409,
  );
  assert.equal(syncs, 1);
});
test("authenticated media streams GET/HEAD ranges and validators without capability leaks; denies foreign sessions and redirects", async (t) => {
  const bytes = Buffer.from("SYNTHETIC_AUDIO");
  const { request, login, calls } = await setup(t, (req, res) => {
    if (catalog(req, res)) return true;
    if (req.url === "/api/items/bookA/play") {
      res.end(
        '{"id":"media","userId":"reader","libraryItemId":"bookA","duration":1000,"audioTracks":[{"index":3,"mimeType":"audio/mpeg","contentUrl":"/public/session/media/track/3"}]}',
      );
      return true;
    }
    if (
      req.url === "/public/session/media/track/3" ||
      req.url === "/api/items/bookA/file/123" ||
      req.url === "/api/items/bookA/cover"
    ) {
      res.setHeader("ETag", '"synthetic"');
      res.setHeader("Accept-Ranges", "bytes");
      res.setHeader("Content-Type", "audio/mpeg");
      res.setHeader("Set-Cookie", "UPSTREAM=SECRET");
      if (req.headers["if-none-match"]) {
        res.statusCode = 304;
        res.end();
        return true;
      }
      if (req.headers.range === "bytes=999-") {
        res.writeHead(416, { "Content-Range": `bytes */${bytes.length}` });
        res.end();
        return true;
      }
      if (req.headers.range) {
        res.writeHead(206, {
          "Content-Range": `bytes 0-2/${bytes.length}`,
          "Content-Length": 3,
        });
        res.end(bytes.subarray(0, 3));
        return true;
      }
      res.setHeader("Content-Length", bytes.length);
      res.end(req.method === "HEAD" ? undefined : bytes);
      return true;
    }
  });
  const { cookie } = await login();
  const init = { headers: { Cookie: cookie } };
  await request("/api/items/bookA/play", {
    method: "POST",
    headers: { Cookie: cookie, "Content-Type": "application/json" },
    body: '{"supportedMimeTypes":["audio/mpeg"]}',
  });
  assert.equal((await request("/public/session/media/track/3")).status, 401);
  const { cookie: other } = await login();
  assert.equal(
    (
      await request("/public/session/media/track/3", {
        headers: { Cookie: other },
      })
    ).status,
    403,
  );
  const full = await request("/public/session/media/track/3", init);
  assert.equal(full.status, 200);
  assert.deepEqual(Buffer.from(await full.arrayBuffer()), bytes);
  assert.equal(full.headers.get("set-cookie"), null);
  const range = await request("/api/items/bookA/file/123?token=ignored", {
    headers: { Cookie: cookie, Range: "bytes=0-2", "If-Range": '"synthetic"' },
  });
  assert.equal(range.status, 206);
  assert.equal(await range.text(), "SYN");
  assert.equal(range.headers.get("content-range"), `bytes 0-2/${bytes.length}`);
  assert.equal(calls.at(-1).headers["if-range"], '"synthetic"');
  const head = await request("/api/items/bookA/file/123", {
    method: "HEAD",
    ...init,
  });
  assert.equal(head.status, 200);
  assert.equal(head.headers.get("content-length"), String(bytes.length));
  assert.equal(await head.text(), "");
  assert.equal(
    (
      await request("/api/items/bookA/file/123", {
        headers: { Cookie: cookie, "If-None-Match": '"synthetic"' },
      })
    ).status,
    304,
  );
  assert.equal(
    (
      await request("/api/items/bookA/file/123", {
        headers: { Cookie: cookie, Range: "bytes=999-" },
      })
    ).status,
    416,
  );
  assert.equal((await request("/api/items/hidden/file/123", init)).status, 403);
});
test("fixed upstream configuration rejects unsafe authorities/base paths and serves public minimal health/status", async (t) => {
  const { createApp } = await import("../app.mjs");
  for (const upstream of [
    "file:///etc/passwd",
    "http://user:pass@localhost",
    "http://localhost/#x",
    "http://localhost/a/../b",
    "http://localhost/%2fsecret",
    "http://169.254.169.254",
    "http://[::ffff:169.254.1.1]",
    "http://[fe80::1]",
  ])
    assert.throws(() => createApp({ upstream, origins: [origin] }));
  const { request, calls } = await setup(t, (req, res) => {
    if (req.url === "/status") {
      res.end(
        '{"app":"audiobookshelf","serverVersion":"2.36.0","isInit":true,"authMethods":["local","openid"],"authFormData":{"secret":"PRIVATE"}}',
      );
      return true;
    }
  });
  const ping = await request("/ping");
  assert.equal(ping.status, 200);
  assert.equal(await ping.text(), "pong");
  assert.equal(calls.length, 0);
  const status = await request("/status");
  assert.equal(status.status, 200);
  assert.deepEqual((await status.json()).authMethods, ["local"]);
});
test("media rejects redirects without following and upstream stops after browser abort", async (t) => {
  let stopped;
  const ended = new Promise((r) => (stopped = r));
  let stream = false;
  const { request, login, url } = await setup(t, (req, res) => {
    if (catalog(req, res)) return true;
    if (req.url === "/api/items/bookA/file/123") {
      if (!stream) {
        res.writeHead(302, {
          Location: "http://127.0.0.1:1/secret?token=PRIVATE",
        });
        res.end();
        return true;
      }
      res.writeHead(200, { "Content-Type": "audio/mpeg" });
      const timer = setInterval(() => res.write(Buffer.alloc(8192)), 5);
      res.on("close", () => {
        clearInterval(timer);
        stopped();
      });
      return true;
    }
  });
  const { cookie } = await login();
  const redirect = await request("/api/items/bookA/file/123", {
    headers: { Cookie: cookie },
  });
  assert.equal(redirect.status, 502);
  assert.doesNotMatch(await redirect.text(), /PRIVATE|Location/);
  stream = true;
  const controller = new AbortController();
  const r = await fetch(url + "/api/items/bookA/file/123", {
    headers: { Cookie: cookie },
    signal: controller.signal,
  });
  const reader = r.body.getReader();
  await reader.read();
  controller.abort();
  await Promise.race([
    ended,
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error("upstream not aborted")), 1000),
    ),
  ]);
});
test("logout closes only owned playback without position before revoking its refresh session", async (t) => {
  const { request, login, calls } = await setup(t, (req, res) => {
    if (catalog(req, res)) return true;
    if (req.url.endsWith("/play")) {
      res.end(
        '{"id":"logoutplay","userId":"reader","libraryItemId":"bookA","duration":1000,"audioTracks":[]}',
      );
      return true;
    }
    if (req.url.endsWith("/close")) {
      res.end("OK");
      return true;
    }
  });
  const { cookie } = await login();
  await request("/api/items/bookA/play", {
    method: "POST",
    headers: { Cookie: cookie, "Content-Type": "application/json" },
    body: '{"supportedMimeTypes":["audio/mpeg"]}',
  });
  assert.equal(
    (
      await request("/logout", {
        method: "POST",
        headers: { Cookie: cookie, "Content-Type": "application/json" },
        body: "{}",
      })
    ).status,
    200,
  );
  const close = calls.find((x) => x.path === "/api/session/logoutplay/close");
  assert.ok(close);
  assert.deepEqual(close.body, {});
  assert.ok(
    calls.indexOf(close) < calls.findIndex((x) => x.path === "/logout"),
  );
});
test("session owner mismatch and HLS are rejected; missing open session is explicitly expired", async (t) => {
  let mode = "foreign";
  const { request, login } = await setup(t, (req, res) => {
    if (catalog(req, res)) return true;
    if (req.url.endsWith("/play")) {
      res.end(
        JSON.stringify({
          id: "guardplay",
          userId: mode === "foreign" ? "other" : "reader",
          libraryItemId: "bookA",
          duration: 1000,
          audioTracks:
            mode === "hls"
              ? [
                  {
                    index: 0,
                    mimeType: "application/vnd.apple.mpegurl",
                    contentUrl: "/hls/guardplay/output.m3u8",
                  },
                ]
              : [],
        }),
      );
      return true;
    }
    if (req.url.endsWith("/close")) {
      res.end("OK");
      return true;
    }
  });
  const { cookie } = await login();
  const start = () =>
    request("/api/items/bookA/play", {
      method: "POST",
      headers: { Cookie: cookie, "Content-Type": "application/json" },
      body: '{"supportedMimeTypes":["audio/mpeg"]}',
    });
  assert.equal((await start()).status, 502);
  mode = "hls";
  assert.equal((await start()).status, 415);
});
test("production entrypoint binds fixed public address and secure cookie default from server env only", async () => {
  const fs = await import("node:fs/promises");
  const source = await fs.readFile(
    new URL("../index.mjs", import.meta.url),
    "utf8",
  );
  assert.match(source, /ABS_ALLOWED_UPSTREAMS/);
  assert.doesNotMatch(source, /process\.env\.ABS_UPSTREAM\b/);
  assert.match(source, /PUBLIC_ORIGINS/);
  assert.match(source, /0\.0\.0\.0/);
  assert.match(source, /3000/);
});
test("auth envelopes and identity use explicit DTO projections, not arbitrary nested upstream reader metadata", async (t) => {
  const { request } = await setup(t, (req, res) => {
    if (req.url === "/login" || req.url === "/api/me") {
      const user = {
        ...envelope().user,
        books: [{ id: "hidden", media: { metadata: { title: "EXCLUDED" } } }],
        mediaProgress: [
          {
            id: "p",
            libraryItem: {
              id: "hidden",
              media: { metadata: { title: "EXCLUDED" } },
            },
          },
        ],
      };
      res.end(
        JSON.stringify(
          req.url === "/login"
            ? {
                ...envelope(),
                user,
                books: user.books,
                Source: { secret: "PRIVATE" },
              }
            : user,
        ),
      );
      return true;
    }
  });
  const r = await request("/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: '{"username":"s","password":"p"}',
  });
  const cookie = r.headers.get("set-cookie").split(";")[0];
  assert.doesNotMatch(await r.text(), /EXCLUDED|PRIVATE|hidden/);
  const me = await request("/api/me", { headers: { Cookie: cookie } });
  assert.doesNotMatch(await me.text(), /EXCLUDED|PRIVATE|hidden/);
});
test("queued start waits for prior sync; later cross-cookie writer supersedes only the app namespace", async (t) => {
  let unblock, entered;
  const barrier = new Promise((r) => (unblock = r)),
    seen = new Promise((r) => (entered = r));
  let n = 0;
  const { request, login, calls } = await setup(t, async (req, res) => {
    if (catalog(req, res)) return true;
    if (req.url.endsWith("/play")) {
      res.end(
        JSON.stringify({
          id: `race${++n}`,
          userId: "reader",
          libraryItemId: req.url.split("/")[3],
          duration: 1000,
          audioTracks: [],
        }),
      );
      return true;
    }
    if (req.url.endsWith("/sync")) {
      entered();
      await barrier;
      res.end("OK");
      return true;
    }
    if (req.url.endsWith("/close")) {
      res.end("OK");
      return true;
    }
  });
  const { cookie } = await login();
  const send = (path, body, c = cookie) =>
    request(path, {
      method: "POST",
      headers: { Cookie: c, "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
  const a = await (
    await send("/api/items/bookA/play", { supportedMimeTypes: ["audio/mpeg"] })
  ).json();
  const pending = send("/api/session/race1/sync", {
    webGeneration: a.webGeneration,
    webSequence: 1,
    currentTime: 10,
    timeListened: 10,
  });
  await seen;
  const { cookie: other } = await login();
  const next = send(
    "/api/items/bookB/play",
    { supportedMimeTypes: ["audio/mpeg"] },
    other,
  );
  await new Promise((r) => setTimeout(r, 20));
  assert.equal(calls.filter((x) => x.path.endsWith("/play")).length, 1);
  unblock();
  assert.equal((await pending).status, 200);
  assert.equal((await next).status, 200);
  assert.ok(calls.find((x) => x.path === "/api/session/race1/close"));
  assert.equal(
    calls.some((x) => x.path === "/api/sessions/open"),
    false,
  );
});
test("upstream 404 yields session_expired without silently recreating playback and failed refresh stops writes", async (t) => {
  let refreshes = 0;
  const { request, login, calls } = await setup(t, (req, res) => {
    if (catalog(req, res)) return true;
    if (req.url.endsWith("/play")) {
      res.end(
        '{"id":"expired","userId":"reader","libraryItemId":"bookA","duration":1000,"audioTracks":[]}',
      );
      return true;
    }
    if (req.url === "/auth/refresh") {
      refreshes++;
      res.statusCode = 401;
      res.end("PRIVATE");
      return true;
    }
    if (req.url === "/api/me") {
      res.statusCode = 401;
      res.end("PRIVATE");
      return true;
    }
  });
  const { cookie } = await login();
  const start = await request("/api/items/bookA/play", {
    method: "POST",
    headers: { Cookie: cookie, "Content-Type": "application/json" },
    body: '{"supportedMimeTypes":["audio/mpeg"]}',
  });
  const a = await start.json();
  const missing = await request("/api/session/expired/sync", {
    method: "POST",
    headers: { Cookie: cookie, "Content-Type": "application/json" },
    body: JSON.stringify({
      webGeneration: a.webGeneration,
      webSequence: 1,
      currentTime: 10,
      timeListened: 1,
    }),
  });
  assert.equal(missing.status, 404);
  assert.equal((await missing.json()).error, "session_expired");
  assert.equal(calls.filter((x) => x.path.endsWith("/play")).length, 1);
  const me = await request("/api/me", { headers: { Cookie: cookie } });
  assert.equal(me.status, 401);
  assert.equal((await me.json()).error, "authentication_expired");
  assert.equal(refreshes, 1);
  // Retirement may finish its one scoped /logout asynchronously; no protected
  // read, refresh, start or listening write may be dispatched after revocation.
  const before = calls.filter((c) => c.path !== "/logout").length;
  assert.equal(
    (await request("/api/me", { headers: { Cookie: cookie } })).status,
    401,
  );
  assert.equal(calls.filter((c) => c.path !== "/logout").length, before);
  assert.ok(calls.filter((c) => c.path === "/logout").length <= 1);
});
test("unmodified pagination retains authoritative total and Flutter lowercase query names work", async (t) => {
  const { request, login } = await setup(t, (req, res) => {
    if (req.url === "/api/libraries") {
      res.end('{"libraries":[{"id":"lib"}]}');
      return true;
    }
    if (req.url.startsWith("/api/libraries/lib/items")) {
      res.end(
        JSON.stringify(
          req.url.includes("limit=200")
            ? {
                results: [
                  { id: "bookA", media: {} },
                  { id: "bookB", media: {} },
                ],
                total: 2,
              }
            : {
                results: [{ id: "bookA", media: {} }],
                total: 2,
                limit: 1,
                page: 0,
              },
        ),
      );
      return true;
    }
    if (req.url.startsWith("/api/libraries/lib/personalized")) {
      res.end("[]");
      return true;
    }
  });
  const { cookie } = await login();
  const r = await request(
    "/api/libraries/lib/items?limit=1&page=0&collapseseries=0",
    { headers: { Cookie: cookie } },
  );
  assert.equal(r.status, 200);
  assert.equal((await r.json()).total, 2);
  assert.equal(
    (
      await request(
        "/api/libraries/lib/personalized?shelves=continue-listening&limit=10",
        { headers: { Cookie: cookie } },
      )
    ).status,
    200,
  );
});
test("upstream login rejection is sanitized and outage is not mislabeled invalid credentials; Secure is default", async (t) => {
  let status = 503;
  const { request } = await setup(
    t,
    (req, res) => {
      if (req.url === "/login" && status !== 200) {
        res.statusCode = status;
        res.end("PRIVATE upstream credentials");
        return true;
      }
    },
    { secureCookie: true, sessionPolicy: { maxSessions: 1 } },
  );
  const login = () =>
    request("/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: '{"username":"s","password":"p"}',
    });
  const outage = await login();
  assert.equal(outage.status, 502);
  assert.doesNotMatch(await outage.text(), /PRIVATE/);
  status = 401;
  assert.equal((await login()).status, 401);
  status = 200;
  const success = await login();
  assert.match(success.headers.get("set-cookie"), /; Secure/);
});
test("slow browser applies bounded backpressure rather than buffering an audiobook", async (t) => {
  let written = 0;
  let finished = false;
  const chunk = Buffer.alloc(65536);
  const total = 128 * 1024 * 1024;
  const { request, login } = await setup(t, (req, res) => {
    if (catalog(req, res)) return true;
    if (req.url === "/api/items/bookA/file/slow") {
      res.writeHead(200, {
        "Content-Type": "audio/mpeg",
        "Content-Length": total,
      });
      function pump() {
        while (written < total) {
          written += chunk.length;
          if (!res.write(chunk)) {
            res.once("drain", pump);
            return;
          }
        }
        finished = true;
        res.end();
      }
      pump();
      return true;
    }
  });
  const { cookie } = await login();
  const controller = new AbortController();
  const r = await request("/api/items/bookA/file/slow", {
    headers: { Cookie: cookie },
    signal: controller.signal,
  });
  await new Promise((resolve) => setTimeout(resolve, 150));
  assert.equal(finished, false);
  assert.ok(written < 32 * 1024 * 1024, `read ahead ${written} bytes`);
  controller.abort();
  await r.body.cancel().catch(() => {});
});
test("nested book cover presence survives DTO projection without exposing filesystem paths", async (t) => {
  const book = (id, coverPath) => ({
    id, libraryId: "lib", mediaType: "book",
    media: { coverPath, metadata: { title: "Synthetic book" }, audioFiles: [] },
  });
  const { request, login } = await setup(t, (req, res) => {
    if (catalog(req, res)) return true;
    if (req.url === "/api/items/bookA/cover?width=400") {
      res.setHeader("Content-Type", "image/png");
      res.end(Buffer.from([137, 80, 78, 71]));
      return true;
    }
    if (req.url.startsWith("/api/libraries/lib/personalized")) {
      res.end(JSON.stringify([{ id: "recent", entities: [
        book("bookA", "/metadata/items/bookA/cover.jpg"),
        book("bookB", ""), book("hidden", "/private/hidden.jpg"),
      ] }]));
      return true;
    }
  });
  const { cookie } = await login();
  const r = await request("/api/libraries/lib/personalized", { headers: { Cookie: cookie } });
  assert.equal(r.status, 200);
  const dto = await r.json();
  assert.equal(dto[0].entities[0].media.coverPath, "browser-cover");
  assert.ok(!dto[0].entities[1].media.coverPath);
  assert.doesNotMatch(JSON.stringify(dto), /metadata\/items|private|cover\.jpg|hidden/);
  // Model the inspected Flutter presence gate followed by getCoverUrl(itemId).
  const item = dto[0].entities[0];
  assert.ok(item.media.coverPath.length > 0);
  const image = await request(`/api/items/${item.id}/cover?width=400`, { headers: { Cookie: cookie } });
  assert.equal(image.status, 200);
  assert.equal(image.headers.get("content-type"), "image/png");
  assert.deepEqual(new Uint8Array(await image.arrayBuffer()), new Uint8Array([137, 80, 78, 71]));
  assert.equal((await request("/api/items/hidden/cover", { headers: { Cookie: cookie } })).status, 403);
  assert.equal((await request("/api/items/bookA/cover")).status, 401);
  const { sanitize } = await import("../reads.mjs");
  for (const absent of [undefined, null, "", false, 42, {}])
    assert.ok(!sanitize({ media: { coverPath: absent } }).media.coverPath);
});
test("idle session expiry clears cookie authority at the exact boundary", async (t) => {
  let now = 1000;
  const { request, login, calls } = await setup(t, undefined, {
    now: () => now,
    sessionPolicy: { idleMs: 100, absoluteMs: 1000, maxSessions: 2 },
  });
  const { cookie, response } = await login();
  now = 1099;
  assert.equal((await request("/api/me", { headers: { Cookie: cookie } })).status, 200);
  now = 1199;
  const expired = await request("/api/me", { headers: { Cookie: cookie } });
  assert.equal(expired.status, 401);
  assert.match(expired.headers.get("set-cookie"), /Max-Age=0/);
  assert.match(response.headers.get("set-cookie"), /Max-Age=1(?:;|$)/);
  const before = calls.filter((c) => c.path === "/api/me").length;
  assert.equal((await request("/api/me", { headers: { Cookie: cookie } })).status, 401);
  assert.equal(calls.filter((c) => c.path === "/api/me").length, before);
});
test("absolute lifetime cannot be extended by activity or token refresh", async (t) => {
  let now = 1000;
  const { request, login } = await setup(t, undefined, {
    now: () => now, sessionPolicy: { idleMs: 100, absoluteMs: 200 },
  });
  const { cookie } = await login();
  for (now of [1099, 1198]) {
    const refreshed = await request("/auth/refresh", {
      method: "POST", headers: { Cookie: cookie, "Content-Type": "application/json" }, body: "{}",
    });
    assert.equal(refreshed.status, 200);
    assert.equal(refreshed.headers.get("set-cookie"), null);
  }
  now = 1200;
  assert.equal((await request("/api/me", { headers: { Cookie: cookie } })).status, 401);
});
test("session capacity reserves pending logins and rejects without evicting active readers", async (t) => {
  let entered, release;
  const seen = new Promise((r) => entered = r);
  const barrier = new Promise((r) => release = r);
  let hold = true;
  const { request, calls } = await setup(t, async (req, res) => {
    if (req.url === "/login" && hold) {
      entered(); await barrier;
      res.end(JSON.stringify(envelope())); return true;
    }
  }, { sessionPolicy: { maxSessions: 1 } });
  const login = () => request("/login", { method: "POST",
    headers: { "Content-Type": "application/json" }, body: '{"username":"s","password":"p"}' });
  const first = login();
  await seen;
  try {
    hold = false;
    const full = await login();
    assert.equal(full.status, 503);
    assert.deepEqual(await full.json(), { error: "session_capacity" });
    assert.equal(full.headers.get("set-cookie"), null);
    assert.equal(calls.filter((c) => c.path === "/login").length, 1);
  } finally { release(); await first; }
  const success = await first;
  const cookie = success.headers.get("set-cookie").split(";")[0];
  assert.equal((await login()).status, 503);
  assert.equal((await request("/api/me", { headers: { Cookie: cookie } })).status, 200);
  await request("/logout", { method: "POST", headers: { Cookie: cookie,
    "Content-Type": "application/json" }, body: "{}" });
  assert.equal((await login()).status, 200);
});
test("background expiry closes only owned playback, revokes credentials and frees admission without requests", async (t) => {
  let now = 1000, retired;
  const done = new Promise((r) => retired = r);
  const { request, login, calls } = await setup(t, (req, res) => {
    if (catalog(req, res)) return true;
    if (req.url.endsWith("/play")) {
      res.end('{"id":"ttlplay","userId":"reader","libraryItemId":"bookA","audioTracks":[]}'); return true;
    }
    if (req.url.endsWith("/close")) { res.end("OK"); return true; }
    if (req.url === "/logout") { res.end("{}"); retired(); return true; }
  }, { now: () => now, sessionPolicy: { idleMs: 100, maxSessions: 1, sweepMs: 10 } });
  const { cookie } = await login();
  assert.equal((await request("/api/items/bookA/play", { method: "POST",
    headers: { Cookie: cookie, "Content-Type": "application/json" },
    body: '{"supportedMimeTypes":["audio/mpeg"]}' })).status, 200);
  now = 1100;
  let timeout;
  try { await Promise.race([done, new Promise((_, reject) => {
    timeout = setTimeout(() => reject(new Error("no background retirement")), 300);
  })]); } finally { clearTimeout(timeout); }
  const closes = calls.filter((c) => c.path.endsWith("/close"));
  assert.equal(closes.length, 1);
  assert.equal(closes[0].path, "/api/session/ttlplay/close");
  assert.deepEqual(closes[0].body, {});
  assert.ok(calls.indexOf(closes[0]) < calls.findIndex((c) => c.path === "/logout"));
  assert.equal((await request("/api/me", { headers: { Cookie: cookie } })).status, 401);
  await login();
});
test("expiry during refresh cannot resurrect a cookie and revokes the newly rotated refresh token", async (t) => {
  let now = 1000, enter, release;
  const seen = new Promise((r) => enter = r), barrier = new Promise((r) => release = r);
  let loggedOut;
  const retired = new Promise((r) => loggedOut = r);
  const { request, login, calls } = await setup(t, async (req, res) => {
    if (req.url === "/auth/refresh") {
      enter(); await barrier;
      const next = envelope(); next.user.refreshToken = "PRIVATE_ROTATED";
      res.end(JSON.stringify(next)); return true;
    }
    if (req.url === "/logout") { res.end("{}"); loggedOut(); return true; }
  }, { now: () => now, sessionPolicy: { idleMs: 100 } });
  const { cookie } = await login();
  const pending = request("/auth/refresh", { method: "POST",
    headers: { Cookie: cookie, "Content-Type": "application/json" }, body: "{}" });
  await seen;
  try {
    now = 1100;
    assert.equal((await request("/api/me", { headers: { Cookie: cookie } })).status, 401);
  } finally { release(); }
  const refresh = await pending;
  assert.equal(refresh.status, 401);
  let timer;
  try { await Promise.race([retired, new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error("no credential revocation")), 500);
  })]); } finally { clearTimeout(timer); }
  assert.equal(calls.find((c) => c.path === "/logout").headers["x-refresh-token"], "PRIVATE_ROTATED");
  assert.match(refresh.headers.get("set-cookie"), /Max-Age=0/);
});
test("M2 source-shaped shelves, collapsed series and expanded tracks retain safe navigation DTOs", async (t) => {
  const book = {
    id: "bookA", libraryId: "lib", media: {
      coverPath: "/metadata/private/cover.jpg",
      metadata: { title: "Visible", series: [{ id: "seriesA", name: "Saga", sequence: "2.5" }] },
      audioFiles: [{ ino: "987654321", metadata: { path: "/private/audio.m4b" } }],
      tracks: [
        { index: 0, contentUrl: "/api/items/bookA/file/987654321?token=PRIVATE", duration: 42 },
        { index: 1, contentUrl: "/api/items/hidden/file/9" },
        { index: 2, contentUrl: "https://evil.test/steal?token=PRIVATE" },
        { index: 3, contentUrl: "/api/items/bookA/file/../secret" },
      ],
    },
    collapsedSeries: { id: "seriesA", name: "Saga", sequence: "2.5", numBooks: 2,
      libraryItemIds: ["bookA", "hidden", "bookA"] },
  };
  const { request, login } = await setup(t, (req, res) => {
    if (catalog(req, res)) return true;
    if (req.url === "/api/items/bookA?expanded=1") { res.end(JSON.stringify(book)); return true; }
    if (req.url.startsWith("/api/libraries/lib/personalized")) {
      res.end(JSON.stringify([{ id: "recent", label: "Recently Added", entities: [book] }])); return true;
    }
  });
  const { cookie } = await login();
  const shelf = await (await request("/api/libraries/lib/personalized", { headers: { Cookie: cookie } })).json();
  assert.equal(shelf[0].label, "Recently Added");
  const dto = await (await request("/api/items/bookA?expanded=1", { headers: { Cookie: cookie } })).json();
  assert.equal(dto.media.metadata.series[0].sequence, "2.5");
  assert.deepEqual(dto.collapsedSeries, { id: "seriesA", name: "Saga", sequence: "2.5", numBooks: 1, libraryItemIds: ["bookA"] });
  assert.equal(dto.media.audioFiles[0].ino, "987654321");
  assert.equal(dto.media.tracks[0].contentUrl, "/api/items/bookA/file/987654321");
  for (const track of dto.media.tracks.slice(1)) assert.equal(track.contentUrl, undefined);
  assert.doesNotMatch(JSON.stringify(dto), /PRIVATE|private|evil|hidden|secret/);
});
test("M3 author library query and exact series metadata routes are guarded by visible book associations", async (t) => {
  const visible = { id: "bookA", libraryId: "lib", media: { metadata: {
    authors: [{ id: "authorA", name: "Visible author" }],
    series: [{ id: "seriesA", name: "Saga", sequence: "1" }],
  } } };
  const hidden = { id: "hidden", media: { metadata: { title: "EXCLUDED" } } };
  const { request, login, calls } = await setup(t, (req, res) => {
    if (req.url === "/api/libraries") { res.end('{"libraries":[{"id":"lib"}]}'); return true; }
    if (req.url.startsWith("/api/libraries/lib/items")) {
      res.end(JSON.stringify({ total: 1, results: [visible] })); return true;
    }
    if (req.url.startsWith("/api/authors/authorA?")) {
      res.end(JSON.stringify({ id: "authorA", name: "Visible author", numBooks: 2,
        libraryItems: [visible, hidden], series: [{ id: "seriesA", name: "Saga", items: [visible, hidden] }] })); return true;
    }
    if (req.url === "/api/series/seriesA" || req.url === "/api/libraries/lib/series/seriesA") {
      res.end(JSON.stringify({ id: "seriesA", name: "Saga", numBooks: 2, libraryItemIds: ["bookA", "hidden"] })); return true;
    }
  });
  const { cookie } = await login();
  for (const path of ["/api/authors/authorA?include=items,series&library=lib",
    "/api/series/seriesA", "/api/libraries/lib/series/seriesA"]) {
    const r = await request(path, { headers: { Cookie: cookie } });
    assert.equal(r.status, 200, path);
    const dto = await r.json();
    assert.equal(dto.numBooks, 1);
    assert.doesNotMatch(JSON.stringify(dto), /hidden|EXCLUDED/);
    if (dto.libraryItems) assert.equal(dto.libraryItems[0].media.metadata.series[0].sequence, "1");
  }
  for (const path of ["/api/authors/hidden?include=items,series&library=lib",
    "/api/authors/authorA?library=denied", "/api/series/hidden", "/api/libraries/lib/series/hidden"]) {
    assert.equal((await request(path, { headers: { Cookie: cookie } })).status, 403, path);
    assert.equal(calls.some((c) => c.path === path), false);
  }
});
test("M3 author images use an explicit visible-author guard, bounded image query and no generic proxy", async (t) => {
  const { request, login, calls } = await setup(t, (req, res) => {
    if (req.url === "/api/libraries") { res.end('{"libraries":[{"id":"lib"}]}'); return true; }
    if (req.url.startsWith("/api/libraries/lib/items")) {
      res.end('{"total":1,"results":[{"id":"bookA","media":{"metadata":{"authors":[{"id":"authorA","name":"Visible"}]}}}]}'); return true;
    }
    if (req.url === "/api/authors/authorA/image?width=400") {
      res.setHeader("Content-Type", "image/jpeg"); res.end("SYNTHETIC_IMAGE"); return true;
    }
  });
  const { cookie } = await login();
  const image = await request("/api/authors/authorA/image?width=400&ts=123&token=PRIVATE", { headers: { Cookie: cookie } });
  assert.equal(image.status, 200);
  assert.equal(await image.text(), "SYNTHETIC_IMAGE");
  assert.equal(image.headers.get("content-type"), "image/jpeg");
  assert.equal((await request("/api/authors/hidden/image?width=400", { headers: { Cookie: cookie } })).status, 403);
  assert.equal(calls.some((c) => c.path.includes("/authors/hidden/image")), false);
  assert.equal((await request("/api/authors/authorA/image?width=999999", { headers: { Cookie: cookie } })).status, 400);
  assert.equal((await request("/api/authors/authorA/image")).status, 401);
  assert.equal((await request("/api/authors/authorA/file/secret", { headers: { Cookie: cookie } })).status, 404);
});
test("R1 nonempty search authors exclude hidden metadata and rebuild visible association counts", async (t) => {
  const visible = { id: "bookA", media: { metadata: {
    authors: [{ id: "allowed-author", name: "Allowed" }],
  } } };
  const { request, login, calls } = await setup(t, (req, res) => {
    if (req.url === "/api/libraries") { res.end('{"libraries":[{"id":"lib"}]}'); return true; }
    if (req.url.startsWith("/api/libraries/lib/items?")) {
      res.end(JSON.stringify({ total: 1, results: [visible] })); return true;
    }
    if (req.url.startsWith("/api/libraries/lib/search?")) {
      res.end(JSON.stringify({ book: [], narrators: [], tags: [], genres: [], series: [], authors: [
        { id: "allowed-author", name: "Allowed", numBooks: 7 },
        { id: "hidden-author", name: "EXCLUDED_AUTHOR", description: "EXCLUDED_DESCRIPTION", numBooks: 3 },
      ] })); return true;
    }
  });
  const { cookie } = await login();
  const r = await request("/api/libraries/lib/search?q=author", { headers: { Cookie: cookie } });
  assert.equal(r.status, 200);
  const dto = await r.json();
  assert.doesNotMatch(JSON.stringify(dto), /hidden-author|EXCLUDED_AUTHOR|EXCLUDED_DESCRIPTION/);
  assert.deepEqual(dto.authors, [{ id: "allowed-author", name: "Allowed", numBooks: 1 }]);
  for (const path of ["/api/authors/hidden-author", "/api/authors/hidden-author/image"]) {
    assert.equal((await request(path, { headers: { Cookie: cookie } })).status, 403);
    assert.equal(calls.some((c) => c.path === path), false);
  }
  for (const c of calls.filter((c) => c.path.startsWith("/api/")))
    assert.equal(c.headers.authorization, "Bearer PRIVATE_ACCESS");
});
test("R1 entity-only lists and shelves use requested-library associations, not book IDs", async (t) => {
  const book = (id, author, series) => ({ id, media: { metadata: {
    authors: [{ id: author, name: author }], series: [{ id: series, name: series, sequence: "2" }],
  } } });
  const a = book("bookA", "sharedAuthor", "sharedSeries");
  const b = book("bookB", "sharedAuthor", "sharedSeries");
  const other = book("otherBook", "otherAuthor", "otherSeries");
  other.media.metadata.authors.push({ id: "sharedAuthor", name: "Shared" });
  other.media.metadata.series.push({ id: "sharedSeries", name: "Shared series", sequence: "3" });
  const authors = [{ id: "sharedAuthor", name: "Shared", numBooks: 99 },
    { id: "otherAuthor", name: "EXCLUDED_OTHER_AUTHOR", numBooks: 9 },
    { id: "hiddenAuthor", name: "EXCLUDED_AUTHOR", description: "EXCLUDED_DESCRIPTION", numBooks: 8 }];
  const series = [{ id: "sharedSeries", name: "Shared series", numBooks: 99 },
    { id: "otherSeries", name: "EXCLUDED_OTHER_SERIES", numBooks: 9 },
    { id: "hiddenSeries", name: "EXCLUDED_SERIES", numBooks: 8 }];
  const { request, login, calls } = await setup(t, (req, res) => {
    const url = new URL(req.url, "http://fixture");
    let data;
    if (url.pathname === "/api/libraries") data = { libraries: [{ id: "lib" }, { id: "other" }] };
    else if (url.pathname.endsWith("/items")) data = url.pathname.includes("/other/")
      ? { total: 1, results: [other] }
      : { total: 2, results: url.searchParams.get("page") === "0" ? [a] : [b] };
    else if (url.pathname === "/api/libraries/lib/authors") data = { total: 99, results: authors };
    else if (url.pathname === "/api/libraries/lib/series") data = { total: 99, results: series };
    else if (url.pathname.endsWith("/personalized")) data = [
      { id: "newest-authors", type: "authors", entities: authors, total: 99 },
      { id: "recent-series", type: "series", entities: series, total: 99 },
    ];
    else if (url.pathname.endsWith("/search")) data = { authors, series: [
      { series: series[0], books: [a, b, other, book("hiddenBook", "hiddenAuthor", "hiddenSeries")] },
      { series: series[1], books: [other] },
      { series: series[2], books: [book("hiddenBook", "hiddenAuthor", "hiddenSeries")] },
    ] };
    else if (url.pathname === "/api/authors/sharedAuthor") data = { ...authors[0], libraryItems: [a, b, other] };
    else return false;
    res.end(JSON.stringify(data)); return true;
  });
  const { cookie } = await login();
  const get = async (path) => {
    const r = await request(path, { headers: { Cookie: cookie } }); assert.equal(r.status, 200, path);
    const dto = await r.json();
    assert.doesNotMatch(JSON.stringify(dto), /EXCLUDED|otherAuthor|otherSeries|otherBook|hiddenAuthor|hiddenSeries|hiddenBook/);
    return dto;
  };
  const authorList = await get("/api/libraries/lib/authors?limit=20&page=0");
  assert.deepEqual(authorList, { total: 1, results: [{ id: "sharedAuthor", name: "Shared", numBooks: 2 }] });
  const seriesList = await get("/api/libraries/lib/series");
  assert.equal(seriesList.results[0].numBooks, 2); assert.equal(seriesList.total, 1);
  const shelves = await get("/api/libraries/lib/personalized");
  assert.deepEqual(shelves.map((s) => [s.entities.length, s.total, s.entities[0].numBooks]), [[1, 1, 2], [1, 1, 2]]);
  const search = await get("/api/libraries/lib/search?q=shared");
  assert.equal(search.series.length, 1); assert.equal(search.series[0].series.numBooks, 2);
  assert.deepEqual(search.series[0].books.map((x) => x.id), ["bookA", "bookB"]);
  assert.equal((await get("/api/authors/sharedAuthor?library=lib")).numBooks, 2);
  const globalAuthor = await request("/api/authors/sharedAuthor", { headers: { Cookie: cookie } });
  assert.equal(globalAuthor.status, 200);
  assert.equal((await globalAuthor.json()).numBooks, 3);
  for (const path of ["/api/authors/otherAuthor?library=lib", "/api/libraries/lib/series/otherSeries",
    "/api/libraries/lib/search?library=other&q=shared"]) {
    const before = calls.length;
    assert.equal((await request(path, { headers: { Cookie: cookie } })).status, 403, path);
    assert.equal(calls.slice(before).some((c) => c.path === path), false);
  }
  assert.ok(calls.some((c) => c.path === "/api/libraries/lib/items?limit=200&page=1"));
});
test("R1 analogous narrator tag genre arrays and included filterdata expose only visible associations", async (t) => {
  const visible = { id: "bookA", media: { tags: ["Visible tag"], metadata: {
    authors: [{ id: "authorA", name: "Visible author" }], series: [{ id: "seriesA", name: "Visible series" }],
    narrators: ["Visible narrator"], genres: ["Visible genre"],
  } } };
  const named = (name, key) => [{ name, [key]: 9 }, { name: "EXCLUDED_NAME", [key]: 7 }];
  const filterdata = { authors: [{ id: "authorA", name: "Visible author" }, { id: "hiddenAuthor", name: "EXCLUDED_AUTHOR" }],
    series: [{ id: "seriesA", name: "Visible series" }, { id: "hiddenSeries", name: "EXCLUDED_SERIES" }],
    narrators: ["Visible narrator", "EXCLUDED_NARRATOR"], tags: ["Visible tag", "EXCLUDED_TAG"],
    genres: ["Visible genre", "EXCLUDED_GENRE"] };
  const { request, login } = await setup(t, (req, res) => {
    let data;
    if (req.url === "/api/libraries") data = { libraries: [{ id: "lib" }] };
    else if (req.url.startsWith("/api/libraries/lib/items?")) data = { total: 1, results: [visible] };
    else if (req.url.startsWith("/api/libraries/lib/search?")) data = {
      narrators: named("Visible narrator", "numBooks"), tags: named("Visible tag", "numItems"), genres: named("Visible genre", "numItems"),
    };
    else if (req.url === "/api/libraries/lib/narrators") data = { narrators: [
      { id: "source-encoded-name", name: "Visible narrator", numBooks: 9 },
      { id: "hiddenNarrator", name: "EXCLUDED_NARRATOR", numBooks: 7 },
    ] };
    else if (req.url === "/api/libraries/lib?include=filterdata") data = { filterdata };
    else return false;
    res.end(JSON.stringify(data)); return true;
  });
  const { cookie } = await login();
  const get = async (path) => {
    const r = await request(path, { headers: { Cookie: cookie } }); assert.equal(r.status, 200);
    const dto = await r.json(); assert.doesNotMatch(JSON.stringify(dto), /EXCLUDED|hidden/); return dto;
  };
  const search = await get("/api/libraries/lib/search?q=visible");
  assert.deepEqual(search, { narrators: [{ name: "Visible narrator", numBooks: 1 }],
    tags: [{ name: "Visible tag", numItems: 1 }], genres: [{ name: "Visible genre", numItems: 1 }] });
  assert.deepEqual((await get("/api/libraries/lib/narrators")).narrators,
    [{ id: "source-encoded-name", name: "Visible narrator", numBooks: 1 }]);
  assert.deepEqual((await get("/api/libraries/lib?include=filterdata")).filterdata, {
    authors: [filterdata.authors[0]], series: [filterdata.series[0]], narrators: ["Visible narrator"],
    tags: ["Visible tag"], genres: ["Visible genre"],
  });
});
test("R1 search preserves empty and absent entity arrays without inventing metadata", async (t) => {
  const empty = { book: [], authors: [], series: [], narrators: [], tags: [], genres: [] };
  const { request, login } = await setup(t, (req, res) => {
    let data;
    if (req.url === "/api/libraries") data = { libraries: [{ id: "lib" }] };
    else if (req.url.startsWith("/api/libraries/lib/items?")) data = { total: 0, results: [] };
    else if (req.url === "/api/libraries/lib/search?q=empty") data = empty;
    else if (req.url === "/api/libraries/lib/search?q=absent") data = {};
    else return false;
    res.end(JSON.stringify(data)); return true;
  });
  const { cookie } = await login();
  for (const [q, expected] of [["empty", empty], ["absent", {}]]) {
    const r = await request(`/api/libraries/lib/search?q=${q}`, { headers: { Cookie: cookie } });
    assert.equal(r.status, 200); assert.deepEqual(await r.json(), expected);
  }
});
test("Q1 retained series omits hidden-book duration aggregate but preserves visible duration and counts", async (t) => {
  const visible = { id: "bookA", libraryId: "lib", media: { duration: 60,
    metadata: { series: [{ id: "sharedSeries", name: "Shared series" }] } } };
  // Pinned ABS 2.36 seriesFilters sums all associated books (60 + hidden 3600)
  // even when its separately loaded books array is already reader-filtered.
  const shared = { id: "sharedSeries", name: "Shared series", totalDuration: 3660,
    numBooks: 2, books: [visible] };
  const { request, login } = await setup(t, (req, res) => {
    let data;
    if (req.url === "/api/libraries") data = { libraries: [{ id: "lib" }] };
    else if (req.url.startsWith("/api/libraries/lib/items?")) data = { total: 1, results: [visible] };
    else if (req.url === "/api/libraries/lib/series?sort=totalDuration") data = { results: [shared], total: 1 };
    else if (req.url === "/api/libraries/lib/search?q=series") data = { series: [{ series: shared, books: [visible] }] };
    else if (req.url === "/api/libraries/lib/personalized") data = [{ id: "recent-series", type: "series", entities: [shared] }];
    else if (req.url === "/api/series/sharedSeries" || req.url === "/api/libraries/lib/series/sharedSeries") data = shared;
    else if (req.url === "/api/items/bookA") data = visible;
    else if (req.url === "/api/me/listening-stats") data = { totalDuration: 60, totalTime: 60 };
    else return false;
    res.end(JSON.stringify(data)); return true;
  });
  const { cookie } = await login();
  const get = async (path) => {
    const r = await request(path, { headers: { Cookie: cookie } });
    assert.equal(r.status, 200, path); return r.json();
  };
  const list = await get("/api/libraries/lib/series?sort=totalDuration");
  assert.equal(list.total, 1);
  const search = await get("/api/libraries/lib/search?q=series");
  const shelves = await get("/api/libraries/lib/personalized");
  for (const dto of [list.results[0], search.series[0].series, shelves[0].entities[0],
    await get("/api/series/sharedSeries"), await get("/api/libraries/lib/series/sharedSeries")]) {
    assert.equal(dto.id, "sharedSeries");
    assert.equal(dto.numBooks, 1);
    assert.equal(dto.books.length, 1);
    assert.equal(dto.books[0].media.duration, 60);
    assert.equal(Object.hasOwn(dto, "totalDuration"), false);
  }
  assert.equal((await get("/api/items/bookA")).media.duration, 60);
  assert.deepEqual(await get("/api/me/listening-stats"), { totalDuration: 60, totalTime: 60 });
});

// A real HTTP body barrier, not a delayed mock promise: headers and partial
// upstream JSON are available, but no protected browser bytes may be released.
for (const route of ["final-search", "identity", "refresh", "playback-start", "playback-read"]) {
  test(`Q2 final buffered ${route} is fenced after local logout revocation`, async (t) => {
    let enter, release;
    const seen = new Promise((r) => enter = r), barrier = new Promise((r) => release = r);
    const visible = { id: "bookA", libraryId: "lib", media: { duration: 60,
      metadata: { authors: [{ id: "authorA" }] } } };
    const play = { id: "heldPlay", userId: "reader", libraryItemId: "bookA", duration: 60, audioTracks: [] };
    let hold = false;
    const { request, login, calls } = await setup(t, async (req, res) => {
      let data, delayed = false;
      if (req.url === "/api/libraries") data = { libraries: [{ id: "lib" }] };
      else if (req.url.startsWith("/api/libraries/lib/items?")) {
        data = { total: 1, results: [visible] };
        // playback.get's last await is permission enumeration after its session body.
        delayed = hold && route === "playback-read";
      }
      else if (req.url === "/api/libraries/lib/search?q=delayed") {
        data = { authors: [{ id: "authorA", name: "Visible author", numBooks: 1 }] };
        delayed = hold && route === "final-search";
      }
      else if (req.url === "/api/me") { data = envelope().user; delayed = hold && route === "identity"; }
      else if (req.url === "/auth/refresh") { data = envelope(); delayed = hold && route === "refresh"; }
      else if (req.url === "/api/items/bookA/play") { data = play; delayed = hold && route === "playback-start"; }
      else if (req.url === "/api/session/heldPlay") data = play;
      else if (req.url === "/api/session/heldPlay/close") { res.end("OK"); return true; }
      else return false;
      if (delayed) {
        res.setHeader("Content-Type", "application/json");
        // The legacy fixture rewrites item pages to minified JSON in end().
        // Keep that path whole; all other probes hold the final body byte.
        if (route !== "playback-read") res.write(JSON.stringify(data).slice(0, -1));
        enter(); await barrier;
        res.end(route === "playback-read" ? JSON.stringify(data) : "}");
      } else res.end(JSON.stringify(data));
      return true;
    });
    const { cookie } = await login();
    const headers = { Cookie: cookie };
    const post = (path, body = {}) => request(path, { method: "POST",
      headers: { ...headers, "Content-Type": "application/json" }, body: JSON.stringify(body) });
    if (route === "playback-read")
      assert.equal((await post("/api/items/bookA/play", { supportedMimeTypes: ["audio/mpeg"] })).status, 200);
    hold = true;
    const pending = route === "refresh" ? post("/auth/refresh")
      : route === "playback-start" ? post("/api/items/bookA/play", { supportedMimeTypes: ["audio/mpeg"] })
      : request(route === "identity" ? "/api/me" : route === "playback-read" ? "/api/session/heldPlay"
        : "/api/libraries/lib/search?q=delayed", { headers });
    await seen;
    let logout;
    try {
      if (route === "final-search") {
        assert.equal(calls.filter((c) => c.path === "/api/items/batch/get").length, 1);
        assert.ok(calls.some((c) => c.path === "/api/libraries/lib/items?limit=200&page=0"));
      }
      logout = post("/logout");
      if (["refresh", "playback-start"].includes(route)) {
        // Retirement must wait for the refresh/start owner. Observe the local
        // revocation through a separate request before releasing that owner.
        let rejected;
        for (let attempt = 0; attempt < 100; attempt++) {
          rejected = await request("/api/collections", { headers });
          if (rejected.status === 401) break;
          await rejected.body.cancel();
        }
        assert.equal(rejected.status, 401);
      } else {
        // Required final-search proof: logout 200 precedes final JSON release.
        assert.equal((await logout).status, 200);
      }
    } finally { release(); }
    const late = await pending;
    assert.equal(late.status, 401);
    assert.match(late.headers.get("set-cookie"), /Max-Age=0/);
    assert.deepEqual(await late.json(), { error: "authentication_expired" });
    assert.equal((await logout).status, 200);
    const before = calls.length;
    assert.equal((await request("/api/me", { headers })).status, 401);
    assert.equal(calls.length, before);
    if (route === "playback-start") {
      const close = calls.find((c) => c.path === "/api/session/heldPlay/close");
      assert.ok(close); assert.deepEqual(close.body, {});
      assert.ok(calls.indexOf(close) < calls.findIndex((c) => c.path === "/logout"));
    }
  });
}

export { setup, origin, envelope };
// ABS 2.36 library pages are minified even with expanded=1; associations
// come only from the separate reader-authorized, read-only batch endpoint.
test("R1 minified wire resolves exact opaque associations through expanded bulk read", async (t) => {
  const author = "32de6593-1058-487d-bc8a-6bd68fce9628";
  const books = ["bookA", "bookB"].map((id) => ({ id, libraryId: "lib", media: { metadata: {
    authors: [{ id: author, name: "Same display name" }],
    series: [{ id: "seriesA", name: "Saga" }], narrators: ["Narrator"],
  } } }));
  const { request, login, calls } = await setup(t, (req, res, body) => {
    if (req.url === "/api/libraries") { res.end('{"libraries":[{"id":"lib"}]}'); return true; }
    if (req.url.startsWith("/api/libraries/lib/items?")) {
      const page = Number(new URL(req.url, "http://fixture").searchParams.get("page"));
      res.end(JSON.stringify({ total: 2, results: [{ id: books[page].id, libraryId: "lib",
        media: { metadata: { authorName: "Same display name", seriesName: "Saga", narratorName: "Narrator" } } }] })); return true;
    }
    if (req.url === "/api/items/batch/get" && req.method === "POST") {
      res.end(JSON.stringify({ libraryItems: books.filter((b) => body.libraryItemIds.includes(b.id)) })); return true;
    }
    if (req.url.startsWith("/api/libraries/lib/search")) {
      res.end(JSON.stringify({ authors: [{ id: author, name: "Same display name", numBooks: 9 },
        { id: "hidden", name: "Same display name", numBooks: 9 }], series: [{ id: "seriesA", numBooks: 9 }],
        narrators: [{ name: "Narrator", numBooks: 9 }] })); return true;
    }
    if (req.url === `/api/authors/${author}`) { res.end(JSON.stringify({ id: author, numBooks: 9 })); return true; }
  });
  const { cookie } = await login();
  const headers = { Cookie: cookie };
  const search = await request("/api/libraries/lib/search?q=Same", { headers });
  assert.equal(search.status, 200);
  const dto = await search.json();
  assert.deepEqual(dto.authors, [{ id: author, name: "Same display name", numBooks: 2 }]);
  assert.deepEqual(dto.series, [{ id: "seriesA", numBooks: 2 }]);
  assert.deepEqual(dto.narrators, [{ name: "Narrator", numBooks: 2 }]);
  assert.equal((await request(`/api/authors/${author}`, { headers })).status, 200);
  const batches = calls.filter((c) => c.path === "/api/items/batch/get");
  assert.equal(batches.length, 2);
  for (const c of batches) {
    assert.equal(c.method, "POST"); assert.deepEqual(c.body, { libraryItemIds: ["bookA", "bookB"] });
    assert.equal(c.headers.authorization, "Bearer PRIVATE_ACCESS");
  }
  const before = calls.length;
  assert.equal((await request("/api/items/batch/get", { method: "POST",
    headers: { ...headers, "Content-Type": "application/json" }, body: '{"libraryItemIds":["hidden"]}' })).status, 404);
  assert.equal(calls.length, before);
});

test("R1 rejects library-page identity collisions before expanded association reads", async (t) => {
  const { request, login, calls } = await setup(t, (req, res) => {
    if (req.url === "/api/libraries") { res.end('{"libraries":[{"id":"lib"},{"id":"other"}]}'); return true; }
    if (/^\/api\/libraries\/(lib|other)\/items/.test(req.url)) {
      res.end('{"total":1,"results":[{"id":"collision","media":{"metadata":{}}}]}'); return true;
    }
    if (req.url.includes("/search")) { res.end('{"authors":[]}'); return true; }
  });
  const { cookie } = await login();
  const result = await request("/api/libraries/lib/search?q=collision", { headers: { Cookie: cookie } });
  assert.equal(result.status, 502);
  assert.equal(calls.some((c) => c.path === "/api/items/batch/get"), false);
});

test("R1 expanded batches are bounded, complete across all pages, and skipped for ordinary book reads", async (t) => {
  const books = Array.from({ length: 205 }, (_, i) => ({ id: `book${i}`, libraryId: "lib",
    media: { metadata: { authors: [{ id: "bulkAuthor" }], series: [] } } }));
  const { request, login, calls } = await setup(t, (req, res, body) => {
    if (req.url === "/api/libraries") { res.end('{"libraries":[{"id":"lib"}]}'); return true; }
    if (req.url.startsWith("/api/libraries/lib/items?")) {
      const page = Number(new URL(req.url, "http://fixture").searchParams.get("page") ?? 0);
      res.end(JSON.stringify({ total: books.length, results: books.slice(page * 100, (page + 1) * 100) })); return true;
    }
    if (req.url === "/api/items/batch/get") {
      res.end(JSON.stringify({ libraryItems: books.filter((b) => body.libraryItemIds.includes(b.id)).reverse() })); return true;
    }
    if (req.url.includes("/search")) { res.end('{"authors":[{"id":"bulkAuthor","numBooks":999}]}'); return true; }
    if (req.url === "/api/items/book0") { res.end(JSON.stringify(books[0])); return true; }
    if (req.url === "/api/items/book0/cover") { res.end("SYNTHETIC_IMAGE"); return true; }
  });
  const { cookie } = await login(); const headers = { Cookie: cookie };
  const r = await request("/api/libraries/lib/search?q=bulk", { headers });
  assert.equal(r.status, 200);
  assert.deepEqual((await r.json()).authors, [{ id: "bulkAuthor", numBooks: 205 }]);
  const batches = calls.filter((c) => c.path === "/api/items/batch/get");
  assert.deepEqual(batches.map((c) => c.body.libraryItemIds.length), [100, 100, 5]);
  assert.equal(new Set(batches.flatMap((c) => c.body.libraryItemIds)).size, 205);
  const before = calls.length;
  for (const path of ["/api/items/book0", "/api/items/book0/cover", "/api/libraries/lib/items?limit=1&page=0"])
    assert.equal((await request(path, { headers })).status, 200);
  assert.equal(calls.slice(before).some((c) => c.path === "/api/items/batch/get"), false);
  assert.equal(calls.some((c) => /items\/book\d+\?expanded/.test(c.path)), false);
});

for (const failure of ["missing", "duplicate", "foreign", "wrong-library", "no-library", "no-metadata",
  "invalid-entity", "scalar-entities", "scalar-narrators", "bad-tags", "not-array", "denied", "outage"]) {
  test(`R1 expanded batch fails closed on ${failure} without forwarding search`, async (t) => {
    const books = ["bookA", "bookB"].map((id) => ({ id, libraryId: "lib",
      media: { metadata: { authors: [{ id: "authorA" }], series: [], narrators: [] }, tags: [] } }));
    const { request, login, calls } = await setup(t, (req, res) => {
      if (req.url === "/api/libraries") { res.end('{"libraries":[{"id":"lib"}]}'); return true; }
      if (req.url.startsWith("/api/libraries/lib/items?")) {
        res.end(JSON.stringify({ total: 2, results: books })); return true;
      }
      if (req.url === "/api/items/batch/get") {
        const result = structuredClone(books);
        if (failure === "missing") result.pop();
        if (failure === "duplicate") result[1] = result[0];
        if (failure === "foreign") result[1].id = "hidden";
        if (failure === "wrong-library") result[0].libraryId = "other";
        if (failure === "no-library") delete result[0].libraryId;
        if (failure === "no-metadata") delete result[0].media.metadata;
        if (failure === "invalid-entity") result[0].media.metadata.authors = [{ id: "not/a/route" }];
        if (failure === "scalar-entities") result[0].media.metadata.series = "Saga";
        if (failure === "scalar-narrators") result[0].media.metadata.narrators = "Narrator";
        if (failure === "bad-tags") result[0].media.tags = [{}];
        if (failure === "denied") res.statusCode = 403;
        if (failure === "outage") res.statusCode = 503;
        res.end(JSON.stringify({ libraryItems: failure === "not-array" ? {} : result })); return true;
      }
      if (req.url.includes("/search")) { res.end('{"authors":[{"id":"authorA"}]}'); return true; }
    });
    const { cookie } = await login();
    const response = await request("/api/libraries/lib/search?q=author", { headers: { Cookie: cookie } });
    assert.equal(response.status, failure === "denied" ? 403 : 502);
    assert.equal(calls.some((c) => c.path.includes("/search")), false);
    assert.doesNotMatch(await response.text(), /authorA|bookA|hidden/);
  });
}

test("R1 local logout during expanded batch prevents late entity disclosure", async (t) => {
  let enter, release;
  const seen = new Promise((r) => enter = r), barrier = new Promise((r) => release = r);
  const { request, login, calls } = await setup(t, async (req, res) => {
    if (req.url === "/api/libraries") { res.end('{"libraries":[{"id":"lib"}]}'); return true; }
    if (req.url.startsWith("/api/libraries/lib/items?")) {
      res.end('{"total":1,"results":[{"id":"bookA","libraryId":"lib","media":{"metadata":{"authorName":"Author"}}}]}'); return true;
    }
    if (req.url === "/api/items/batch/get") {
      enter(); await barrier;
      res.end('{"libraryItems":[{"id":"bookA","libraryId":"lib","media":{"metadata":{"authors":[{"id":"authorA"}]}}}]}'); return true;
    }
  });
  const { cookie } = await login(); const headers = { Cookie: cookie };
  const pending = request("/api/libraries/lib/search?q=author", { headers });
  await seen;
  try {
    assert.equal((await request("/logout", { method: "POST", headers: { ...headers,
      "Content-Type": "application/json" }, body: "{}" })).status, 200);
  } finally { release(); }
  assert.equal((await pending).status, 401);
  assert.equal(calls.some((c) => c.path.includes("/search")), false);
});

test("R1 permission revocation in a later batch discards earlier associations and stops enumeration", async (t) => {
  const books = Array.from({ length: 205 }, (_, i) => ({ id: `book${i}`, libraryId: "lib",
    media: { metadata: { authors: [{ id: "authorA" }] } } }));
  let batchNumber = 0;
  const { request, login, calls } = await setup(t, (req, res, body) => {
    if (req.url === "/api/libraries") { res.end('{"libraries":[{"id":"lib"}]}'); return true; }
    if (req.url.startsWith("/api/libraries/lib/items?")) {
      const page = Number(new URL(req.url, "http://fixture").searchParams.get("page"));
      res.end(JSON.stringify({ total: 205, results: books.slice(page * 100, (page + 1) * 100) })); return true;
    }
    if (req.url === "/api/items/batch/get") {
      if (++batchNumber === 2) { res.statusCode = 403; res.end("PRIVATE_PERMISSION_ERROR"); }
      else res.end(JSON.stringify({ libraryItems: books.filter((b) => body.libraryItemIds.includes(b.id)) }));
      return true;
    }
  });
  const { cookie } = await login();
  const r = await request("/api/libraries/lib/search?q=author", { headers: { Cookie: cookie } });
  assert.equal(r.status, 403);
  assert.deepEqual(await r.json(), { error: "upstream_rejected" });
  assert.equal(batchNumber, 2);
  assert.equal(calls.some((c) => c.path.includes("/search")), false);
});
