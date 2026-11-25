import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";
import { Fault } from "./http.mjs";
import { accessible } from "./reads.mjs";
const forwarded = ["range", "if-range", "if-none-match", "if-modified-since"];
const returned = [
  "content-range",
  "accept-ranges",
  "content-length",
  "content-type",
  "etag",
  "last-modified",
];
export async function streamMedia(
  req,
  res,
  url,
  session,
  authorized,
  playback,
) {
  const path = url.pathname;
  let upstreamPath = path;
  let item;
  const publicTrack = path.match(
    /^\/public\/session\/([A-Za-z0-9_-]+)\/track\/(\d+)$/,
  );
  const direct = path.match(
    /^\/api\/items\/([A-Za-z0-9_-]+)\/(?:file\/[A-Za-z0-9_-]+|cover)$/,
  );
  const authorImage = path.match(/^\/api\/authors\/([A-Za-z0-9_-]+)\/image$/);
  if (publicTrack) {
    const record = playback.requireOwned(session, publicTrack[1]);
    if (record.closed) throw new Fault(404, "session_expired");
    upstreamPath = record.tracks.get(publicTrack[2]);
    if (!upstreamPath) throw new Fault(404, "track_not_found");
    item = record.item;
  } else if (direct) item = direct[1];
  else if (!authorImage) return false;
  const controller = new AbortController();
  const abort = () => controller.abort();
  res.once("close", abort);
  try {
    const scope = await accessible(authorized, session, { entities: !!authorImage });
    if (authorImage ? !scope.authors.has(authorImage[1]) : !scope.ids.has(item))
      throw new Fault(403, "item_denied");
    const headers = { "Accept-Encoding": "identity" };
    for (const name of forwarded)
      if (req.headers[name]) headers[name] = req.headers[name];
    // Only safe, bounded image options are accepted; query credentials never forward.
    if (path.endsWith("/cover") || authorImage) {
      const q = new URLSearchParams();
      for (const name of ["width", "height", "format"])
        if (url.searchParams.has(name)) {
          const v = url.searchParams.get(name);
          if (!/^(?:[1-9]\d{0,3}|webp|jpeg|png)$/.test(v))
            throw new Fault(400, "invalid_image_option");
          q.set(name, v);
        }
      if (q.size) upstreamPath += "?" + q;
    }
    const r = await authorized(session, upstreamPath, {
      method: req.method,
      headers,
      signal: controller.signal,
    });
    if (![200, 206, 304, 416].includes(r.status)) {
      await r.body?.cancel();
      throw new Fault(
        [401, 403, 404].includes(r.status) ? r.status : 502,
        r.status === 404 ? "media_expired" : "media_unavailable",
      );
    }
    if (
      r.headers.get("content-encoding") &&
      !["identity"].includes(r.headers.get("content-encoding"))
    ) {
      await r.body?.cancel();
      throw new Fault(502, "unsupported_content_encoding");
    }
    for (const name of returned)
      if (r.headers.has(name)) res.setHeader(name, r.headers.get(name));
    res.writeHead(r.status);
    if (req.method === "HEAD" || r.status === 304 || !r.body) {
      await r.body?.cancel();
      res.end();
    } else
      await pipeline(Readable.fromWeb(r.body), res, {
        signal: controller.signal,
      });
    return true;
  } finally {
    res.off("close", abort);
  }
}
export const mediaAllowed =
  /^(?:\/api\/items\/[A-Za-z0-9_-]+\/(?:file\/[A-Za-z0-9_-]+|cover)|\/api\/authors\/[A-Za-z0-9_-]+\/image|\/public\/session\/[A-Za-z0-9_-]+\/track\/\d+)$/;
