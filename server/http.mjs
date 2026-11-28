export class Fault extends Error {
  constructor(status, code) {
    super(code);
    this.status = status;
    this.code = code;
  }
}
export function json(res, status, value) {
  if (res.destroyed) return;
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(value));
}
export async function readJSON(req) {
  if (req.headers["content-type"]?.split(";")[0].trim() !== "application/json")
    throw new Fault(415, "json_required");
  let size = 0;
  const chunks = [];
  for await (const chunk of req) {
    size += chunk.length;
    if (size > 65536) throw new Fault(413, "body_too_large");
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw new Fault(400, "invalid_json");
  }
}
export function loginLimiter(limit = 10, now = Date.now) {
  const buckets = new Map();
  return (key) => {
    const time = now();
    for (const [k, v] of buckets) if (v.until <= time) buckets.delete(k);
    if (!buckets.has(key)) {
      if (buckets.size >= 10000) throw new Fault(429, "login_rate_limited");
      buckets.set(key, { until: time + 60000, count: 0 });
    }
    if (++buckets.get(key).count > limit)
      throw new Fault(429, "login_rate_limited");
  };
}
