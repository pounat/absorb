import test from "node:test";
import assert from "node:assert/strict";
import { playbackManager } from "../playback.mjs";
import { createApp } from "../app.mjs";
import { spawnSync } from "node:child_process";

test("invalid session bounds fail at startup rather than disable bounded admission or expiry", async () => {
  for (const key of ["idleMs", "absoluteMs", "maxSessions", "sweepMs"]) {
    for (const value of [0, -1, Infinity, NaN, 1.5, "100", undefined]) {
      let app;
      try {
        assert.throws(() => {
          app = createApp({ upstream: "http://127.0.0.1:1", origins: ["https://example.test"],
            sessionPolicy: { [key]: value } });
        }, /sessionPolicy/);
      } finally { await app?.dispose(); }
    }
  }
});

test("session scheduler alone never keeps a Node process alive", () => {
  const module = new URL("../app.mjs", import.meta.url).href;
  const result = spawnSync(process.execPath, ["--input-type=module", "-e",
    `import {createApp} from ${JSON.stringify(module)}; createApp({upstream:'http://127.0.0.1:1',origins:['https://example.test']});`],
    { timeout: 1500, encoding: "utf8" });
  assert.equal(result.error, undefined);
  assert.equal(result.status, 0, result.stderr);
});

test("recreated playback managers reuse the app/user device identity without colliding with native devices", async () => {
  const deviceIds = [];
  const activeDevices = new Map([["native-device", "native-playback"]]);
  let n = 0;
  const authorized = async (s, path, init) => {
    if (path === "/api/libraries") return Response.json({ libraries: [{ id: "lib" }] });
    if (path.includes("/items?")) return Response.json({ total: 1, results: [{ id: "book" }] });
    if (path.endsWith("/play")) {
      const id = `stable${++n}`;
      const device = JSON.parse(init.body).deviceInfo.deviceId;
      deviceIds.push(device);
      // ABS starts replace previous playback for this exact device identity.
      activeDevices.set(device, id);
      return Response.json({ id, userId: s.userId, libraryItemId: "book", audioTracks: [] });
    }
    return new Response("OK");
  };
  for (const userId of ["reader", "reader", "other-reader"]) {
    const manager = playbackManager(authorized);
    await manager.start({ userId }, "book", undefined, { supportedMimeTypes: ["audio/mpeg"] });
  }
  assert.equal(deviceIds[0], deviceIds[1]);
  assert.notEqual(deviceIds[0], deviceIds[2]);
  assert.match(deviceIds[0], /^absorb-web-[a-f0-9]+$/);
  assert.equal(activeDevices.size, 3); // native + one per app reader, not one per restart
  assert.equal(activeDevices.get("native-device"), "native-playback");
  assert.equal(activeDevices.get(deviceIds[0]), "stable2");
});

test("retiring a cookie releases its owned playback records, not another cookie's records", async () => {
  let n = 0;
  const playback = playbackManager(async (s, path) => {
    if (path === "/api/libraries") return Response.json({ libraries: [{ id: "lib" }] });
    if (path.includes("/items?")) return Response.json({ total: 1, results: [{ id: "book" }] });
    if (path.endsWith("/play")) return Response.json({ id: `p${++n}`, userId: s.userId,
      libraryItemId: "book", audioTracks: [] });
    return new Response("OK");
  });
  const first = { userId: "reader" }, other = { userId: "reader" };
  await playback.start(first, "book", undefined, { supportedMimeTypes: ["audio/mpeg"] });
  await playback.start(other, "book", undefined, { supportedMimeTypes: ["audio/mpeg"] });
  first.revoked = true;
  await playback.logout(first);
  assert.throws(() => playback.requireOwned(first, "p1"), { code: "session_not_owned" });
  assert.equal(playback.requireOwned(other, "p2").closed, false);
  other.revoked = true;
  await playback.logout(other);
  assert.throws(() => playback.requireOwned(other, "p2"), { code: "session_not_owned" });
});
