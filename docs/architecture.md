# Browser architecture

The original browser port extends GPL-3.0-or-later Absorb at public upstream
`c887df5c60a4562870069fbd21d841c066f53ecc`. Upstream Nathan Poulson attribution
and native branches are retained. This is the original book-first Flutter web
interface, not an experimental readalong implementation.

Flutter remains at `/absorb/`, with same-origin requests and a nonsecret cookie
sentinel. A dependency-free Node BFF owns real Audiobookshelf access/refresh
credentials in memory. The browser receives only an opaque HttpOnly, Secure,
SameSite=Strict cookie. The BFF enforces exact mutation origins, JSON/body/login
bounds, immutable per-session upstream addressing with SSRF/DNS protections, endpoint and query allowlists, reader-visible
metadata filtering, and owned ordered playback sessions. Nginx never bypasses it.

Media streams preserve byte ranges and use backpressure and disconnect cancellation.
Listening increments are not retried after ambiguous dispatch: conservative recovery
can undercount the last unacknowledged segment rather than duplicate accounting.
Audiobookshelf offers no idempotency key/CAS for this workflow.

Collections and unsupported native/admin paths are omitted or denied instead of
being forwarded without permission filtering. Direct browser-decodable audio is
the supported path; HLS, native downloads, casting and offline queues are not.

The BFF is single-process, with bounded in-memory credentials and sessions. Its
restart requires login again. Only the API joins the existing backend network.
Deployment uses unprivileged containers, read-only filesystems, loopback ingress,
and an operator-managed HTTPS reverse proxy. See the [adapter contract](web-adapter-contract.md)
for the exact boundary and [deployment](deployment.md) for reproducible commands.

Compilation, unit tests, synthetic transport tests, actual browser playback and
physical device behavior are distinct qualification gates. No generated browser
assets or operator test receipts are included in this source contribution.
