import http from "node:http";
import { publicAddress, trustedServer } from "./destination.mjs";
export { selectUpstream } from "./destination.mjs";
import https from "node:https";
import { lookup } from "node:dns/promises";
import { isIP } from "node:net";
import { Readable } from "node:stream";
import { Fault } from "./http.mjs";
function forbiddenIP(address) {
  const ip = address.toLowerCase();
  const mapped = ip.match(/^::ffff:([0-9a-f]{1,4}):([0-9a-f]{1,4})$/);
  if (mapped) {
    const high = Number.parseInt(mapped[1], 16),
      low = Number.parseInt(mapped[2], 16);
    return forbiddenIP(`${high >>> 8}.${high & 255}.${low >>> 8}.${low & 255}`);
  }
  return (
    /^(?:0\.|169\.254\.|(?:22[4-9]|23\d|24\d|25[0-5])\.)/.test(ip) ||
    ip === "::" || ip === "100.100.100.200" || ip === "fd00:ec2::254" ||
    /^(?:fe[89ab]|ff)/.test(ip) ||
    (ip.startsWith("::ffff:") && forbiddenIP(ip.slice(7))) ||
    ip === "::ffff:a9fe:a9fe"
  );
}
export function config(options) {
  if (options.upstream === undefined || options.upstream === "") {
    config({ ...options, upstream: "https://example.com" });
    return null;
  }
  if (
    typeof options.upstream !== "string" ||
    /[\\%?#]/.test(options.upstream) ||
    /(?:^|\/)\.{1,2}(?:\/|$)/.test(options.upstream)
  )
    throw new Error("Invalid ABS_UPSTREAM");
  const upstream = new URL(options.upstream);
  const host = upstream.hostname.replace(/^\[|\]$/g, "");
  if (
    !["http:", "https:"].includes(upstream.protocol) ||
    upstream.username ||
    upstream.password ||
    forbiddenIP(host) ||
    !/^\/(?:[A-Za-z0-9_-]+\/?)*$/.test(upstream.pathname)
  )
    throw new Error("Invalid ABS_UPSTREAM");
  if (
    !Array.isArray(options.origins) ||
    !options.origins.length ||
    options.origins.some((o) => {
      try {
        const u = new URL(o);
        return u.origin !== o || u.protocol !== "https:";
      } catch {
        return true;
      }
    })
  )
    throw new Error("PUBLIC_ORIGINS requires exact HTTPS origins");
  return upstream;
}
export function transport(upstream, options = {}) {
  const hostname = upstream.hostname.replace(/^\[|\]$/g, "");
  let pinned;
  function addresses() {
    return (pinned ??= (async () => {
      const list = isIP(hostname)
        ? [{ address: hostname, family: isIP(hostname) }]
        : await Promise.race([
          (options.resolve ?? lookup)(hostname, { all: true }),
          new Promise((_, reject) => { const timer = setTimeout(() => reject(new Fault(502, "upstream_dns_timeout")), 5000); timer.unref(); }),
        ]);
      if (!list.length || list.some((x) => forbiddenIP(x.address) ||
        (options.selected && !publicAddress(x.address) && !trustedServer(upstream, options))))
        throw new Fault(502, "upstream_destination_denied");
      return list;
    })());
  }
  return async (path, init = {}) => {
    if (!/^\/(?!\/)/.test(path) || /[\\\r\n]/.test(path))
      throw new Fault(502, "unsafe_upstream_path");
    const list = await addresses();
    const target = new URL(upstream.href.replace(/\/$/, "") + path);
    return new Promise((resolve, reject) => {
      const request = (target.protocol === "https:" ? https : http).request(
        target,
        {
          method: init.method ?? "GET",
          headers: init.headers,
          signal: init.signal,
          lookup: (_host, options, cb) => {
            const matches = options.family
              ? list.filter((x) => x.family === options.family)
              : list;
            const chosen = matches[0];
            if (!chosen) return cb(new Error("Destination family unavailable"));
            cb(
              null,
              ...(options.all ? [matches] : [chosen.address, chosen.family]),
            );
          },
        },
        (response) => {
          if (response.statusCode >= 300 && response.statusCode < 400 && response.statusCode !== 304) {
            response.destroy();
            reject(new Fault(502, "upstream_redirect_denied"));
            return;
          }
          const body = Readable.toWeb(response);
          const headers = new Headers();
          for (const [key, value] of Object.entries(response.headers))
            if (value !== undefined)
              headers.set(key, Array.isArray(value) ? value.join(", ") : value);
          resolve({
            status: response.statusCode,
            ok: response.statusCode >= 200 && response.statusCode < 300,
            headers,
            body,
            async json() {
              const deadline = setTimeout(() => request.destroy(new Error("Response timeout")), 15000);
              deadline.unref();
              const reader = body.getReader();
              let size = 0;
              const chunks = [];
              try {
                while (true) {
                  const { value, done } = await reader.read();
                  if (done) break;
                  size += value.length;
                  if (size > 8 * 1024 * 1024)
                    throw new Fault(502, "upstream_json_too_large");
                  chunks.push(Buffer.from(value));
                }
                return JSON.parse(Buffer.concat(chunks).toString("utf8"));
              } catch (e) {
                await reader.cancel().catch(() => {});
                throw e;
              } finally { clearTimeout(deadline); }
            },
          });
        },
      );
      const deadline = setTimeout(() => request.destroy(new Error("Header timeout")), 15000);
      deadline.unref();
      request.once("response", () => clearTimeout(deadline));
      request.once("error", () => clearTimeout(deadline));
      request.setTimeout(30000, () =>
        request.destroy(new Error("Upstream timeout")),
      );
      request.on("error", reject);
      if (init.body) request.write(init.body);
      request.end();
    });
  };
}
