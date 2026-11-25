import http from "node:http";
import { createProviderApp } from "./providers.mjs";
const app = createProviderApp({
  allowedUpstreams: (process.env.ABS_ALLOWED_UPSTREAMS ?? "").split(",").map(x => x.trim()).filter(Boolean),
  allowHttp: process.env.ABS_ALLOW_HTTP === "true",
  origins: (process.env.PUBLIC_ORIGINS ?? "")
    .split(",")
    .map((x) => x.trim())
    .filter(Boolean),
});
const server = http.createServer(
  { requestTimeout: 30000, headersTimeout: 15000, maxHeaderSize: 16384 },
  app,
);
server.listen(3000, "0.0.0.0");
process.on('SIGTERM', async()=>{server.close();await app.dispose();});
