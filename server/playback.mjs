import { createHash } from "node:crypto";
import { Fault } from "./http.mjs";
import { accessible, getJSON, sanitize, filterItems } from "./reads.mjs";
const validID = (x) => typeof x === "string" && /^[A-Za-z0-9_-]+$/.test(x);
export function playbackManager(authorized) {
  const users = new Map();
  const owned = new Map();
  let generation = 0;
  function user(session) {
    if (!validID(session.userId)) throw new Fault(502, "invalid_session_owner");
    if (!users.has(session.userId))
      users.set(session.userId, {
        tail: Promise.resolve(),
        deviceId: `absorb-web-${createHash("sha256").update("absorb-web:v1\0").update(session.userId).digest("hex")}`,
        active: null,
      });
    return users.get(session.userId);
  }
  function serial(session, work) {
    const state = user(session);
    const task = state.tail.then(() => {
      if (session.revoked) throw new Fault(401, "authentication_expired");
      return work(state);
    });
    state.tail = task.catch(() => {});
    return task;
  }
  function requireOwned(session, id) {
    const record = owned.get(id);
    if (!record || record.session !== session)
      throw new Fault(403, "session_not_owned");
    return record;
  }
  async function post(session, path, body) {
    return authorized(session, path, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
  }
  async function closeRecord(record) {
    // No position/increment on supersession: never replay stale progress.
    const r = await post(record.session, `/api/session/${record.id}/close`, {});
    await r.body?.cancel();
    if (!r.ok && r.status !== 404)
      throw new Fault(502, "session_close_uncertain");
    record.closed = true;
  }
  async function start(session, item, episode, body) {
    return serial(session, async (state) => {
      if (
        !body ||
        !Array.isArray(body.supportedMimeTypes) ||
        !body.supportedMimeTypes.length ||
        body.supportedMimeTypes.length > 16
      )
        throw new Fault(400, "browser_mime_types_required");
      const mimes = body.supportedMimeTypes.filter((x) =>
        [
          "audio/mpeg",
          "audio/mp4",
          "audio/aac",
          "audio/ogg",
          "audio/webm",
          "audio/flac",
          "audio/wav",
        ].includes(x),
      );
      if (!mimes.length) throw new Fault(415, "unsupported_audio");
      const scope = await accessible(authorized, session);
      if (!scope.ids.has(item)) throw new Fault(403, "item_denied");
      if (state.active && !state.active.closed) await closeRecord(state.active);
      const r = await post(
        session,
        `/api/items/${item}/play${episode ? "/" + episode : ""}`,
        {
          deviceInfo: {
            deviceId: state.deviceId,
            clientName: "Absorb Web",
            clientVersion: "1",
          },
          mediaPlayer: "html5",
          forceDirectPlay: false,
          forceTranscode: false,
          supportedMimeTypes: [...new Set(mimes)],
        },
      );
      if (!r.ok) {
        await r.body?.cancel();
        throw new Fault(r.status === 404 ? 404 : 502, "playback_start_failed");
      }
      const data = await r.json();
      if (
        !validID(data.id) ||
        data.userId !== session.userId ||
        data.libraryItemId !== item ||
        owned.has(data.id)
      )
        throw new Fault(502, "invalid_session_owner");
      const record = {
        id: data.id,
        session,
        item,
        generation: ++generation,
        lastSeq: 0,
        closed: false,
        uncertain: false,
        tracks: new Map(),
      };
      owned.set(data.id, record);
      state.active = record;
      for (const track of data.audioTracks ?? []) {
        if (
          !Number.isSafeInteger(track.index) ||
          track.index < 0 ||
          typeof track.contentUrl !== "string"
        )
          throw new Fault(502, "invalid_track");
        // No HLS or external destinations: route construction, never URL forwarding.
        if (
          track.mimeType?.includes("mpegurl") ||
          track.contentUrl.startsWith("/hls/")
        ) {
          await closeRecord(record);
          throw new Fault(415, "hls_not_supported");
        }
        const direct = new RegExp(`^/api/items/${item}/file/[A-Za-z0-9_-]+$`);
        const path = track.contentUrl.split("?")[0];
        if (
          path !== `/public/session/${record.id}/track/${track.index}` &&
          !direct.test(path)
        ) {
          await closeRecord(record);
          throw new Fault(502, "unsafe_track_url");
        }
        record.tracks.set(String(track.index), path);
      }
      const safe = sanitize(filterItems(data, scope.ids));
      safe.webGeneration = record.generation;
      safe.audioTracks = (data.audioTracks ?? []).map((track) => ({
        ...sanitize(track),
        contentUrl: `/public/session/${record.id}/track/${track.index}`,
      }));
      return safe;
    });
  }
  async function mutate(session, id, action, body) {
    return serial(session, async (state) => {
      const record = requireOwned(session, id);
      if (
        record.closed ||
        state.active !== record ||
        body?.webGeneration !== record.generation ||
        !Number.isSafeInteger(body?.webSequence) ||
        body.webSequence <= record.lastSeq
      )
        throw new Fault(409, "obsolete_playback");
      if (record.uncertain)
        throw new Fault(409, "session_reconciliation_required");
      const payload = {};
      for (const key of ["currentTime", "timeListened", "duration"]) {
        if (body[key] === undefined) {
          if (action === "sync" && key !== "duration")
            throw new Fault(400, "invalid_playback_values");
          continue;
        }
        const v = body[key];
        if (
          typeof v !== "number" ||
          !Number.isFinite(v) ||
          v < 0 ||
          v > (key === "timeListened" ? 3600 : 31536000)
        )
          throw new Fault(400, "invalid_playback_values");
        payload[key] = v;
      }
      if (
        action === "close" &&
        Object.keys(payload).length &&
        !("currentTime" in payload && "timeListened" in payload)
      )
        throw new Fault(400, "invalid_playback_values");
      record.lastSeq = body.webSequence;
      let r;
      try {
        r = await post(session, `/api/session/${id}/${action}`, payload);
      } catch {
        record.uncertain = true;
        throw new Fault(502, "listening_write_uncertain");
      }
      const status = r.status;
      await r.body?.cancel();
      if (status === 404) {
        record.closed = true;
        throw new Fault(404, "session_expired");
      }
      if (status !== 200) {
        record.uncertain = true;
        throw new Fault(
          status >= 400 && status < 500 ? status : 502,
          "listening_write_uncertain",
        );
      }
      if (action === "close") record.closed = true;
    });
  }
  async function get(session, id) {
    const record = requireOwned(session, id);
    if (record.closed) throw new Fault(404, "session_expired");
    const r = await authorized(session, `/api/session/${id}`);
    if (r.status === 404) {
      await r.body?.cancel();
      record.closed = true;
      throw new Fault(404, "session_expired");
    }
    if (!r.ok) {
      await r.body?.cancel();
      throw new Fault(502, "session_read_failed");
    }
    const data = await r.json();
    if (data.userId !== session.userId || data.id !== id)
      throw new Fault(502, "invalid_session_owner");
    const scope = await accessible(authorized, session);
    if (!scope.ids.has(record.item)) throw new Fault(403, "item_denied");
    const out = sanitize(filterItems(data, scope.ids));
    out.webGeneration = record.generation;
    out.audioTracks = (data.audioTracks ?? []).map((track) => ({
      ...sanitize(track),
      contentUrl: `/public/session/${id}/track/${track.index}`,
    }));
    return out;
  }
  async function logout(session) {
    const state = user(session);
    const work = state.tail.then(async () => {
      await session.refreshing?.catch(() => {});
      const snapshot = { ...session, revoked: false };
      for (const r of owned.values())
        if (r.session === session && !r.closed) {
          try {
            const response = await authorized(
              snapshot,
              `/api/session/${r.id}/close`,
              {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: "{}",
              },
              false,
            );
            await response.body?.cancel();
          } catch {}
          r.closed = true;
        }
      for (const [id, record] of owned) {
        if (record.session !== session) continue;
        owned.delete(id);
        if (state.active === record) state.active = null;
      }
    });
    state.tail = work.catch(() => {});
    const tail = state.tail;
    await tail;
    // A concurrently queued start must retain its existing per-user queue.
    if (state.tail === tail && ![...owned.values()].some((r) => r.session.userId === session.userId))
      users.delete(session.userId);
    return work;
  }
  return { start, mutate, get, requireOwned, logout };
}
