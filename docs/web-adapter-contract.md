# Absorb Web adapter contract

This is the integration authority for the pinned GPL-3.0-or-later Absorb fork. Existing mobile behavior is preserved. Implementation targets Audiobookshelf 2.36.0 behavior.

## Public layout

The Flutter application remains at `/absorb/`; `/` redirects there. There is no canonical deployment hostname or default upstream. Both providers use a blank editable Server URL, Username and Password form. The saved account URL is the user-entered normalized target; actual network traffic is exclusively same-origin through a per-account public route plus matching HttpOnly cookie. See [server selection](server-selection.md) for the current dual-provider contract, storage/isolation model, destination policy and BookOrbit limits. The remainder of this document describes the inherited ABS endpoint surface; root paths below are prefixed by the account session route for the compiled browser.

A Node HTTP BFF owns `/login`, `/logout`, `/auth/refresh`, `/status`, `/ping`, `/api/...`, and authenticated media paths. Nginx serves static assets and proxies these paths only to the BFF. It NEVER proxies directly to ABS. There is no generic URL forwarding endpoint. BFF export: `createApp(options)` returns a Node HTTP request listener, with `options.upstream`, `options.origins`, and injectable test-only clocks/transports where useful. Production entrypoint: `server/index.mjs`; listens on `0.0.0.0:3000`. Session storage may be in-memory: restart requires reauthentication, but ABS progress remains authoritative.

## Authentication compatibility

POST `/login` receives `{serverUrl,username,password}` JSON, validates the destination and forwards only to that selected ABS `/login`, requesting modern tokens. Legacy callers omitting `serverUrl` require the optional fixed operator server. Real access/refresh tokens remain in BFF memory. Passwords are never persisted. Browser gets an opaque HttpOnly, Secure, SameSite cookie (`absorb_web_session`, path `/`); local test HTTP may explicitly disable Secure, never based on an untrusted forwarded header. Origin is required and exactly allowlisted for mutations. JSON bodies bounded to 64 KiB; login rate-limited; no raw upstream errors, cookies, credentials, capability-bearing URLs or response bodies in logs.

Native Absorb auth DTOs require nonempty token strings. The BFF supplies the documented **non-secret sentinel** `browser-cookie` as `user.accessToken` and `user.refreshToken`, and removes real and legacy tokens recursively from responses (including `/api/me`). This sentinel is not authentication and can be safely persisted by legacy app account-state code. Incoming Authorization/token query values never authenticate BFF requests: only the HttpOnly cookie does. `/auth/refresh` transparently refreshes the BFF's owned ABS credential and returns the sanitized compatible envelope; `/logout` revokes only this auth refresh session and clears the cookie. No API-key or OIDC login in this web release. Native socket authentication must not attempt to send the sentinel to ABS; web uses HTTP state refresh.

## Read and permission boundary

Use an exact endpoint/method allowlist, not an unrestricted `/api` passthrough. Needed reads include identity, accessible libraries, library items/search/personalized/series/authors, expanded items/chapters/covers/files, progress and owned playback sessions. NEVER permit admin/metadata/upload/delete endpoints or arbitrary GETs (some ABS GETs mutate state). Unsupported extras return useful 403/404 JSON rather than forwarding.

ABS collection listings can leak excluded book metadata. MVP may omit collections entirely: return compatible empty collections responses and never forward collection details. Review all nested book results: obtain a complete paginated accessible-item ID set using the logged-in reader's credentials, filter nested book objects, rebuild affected counts, and omit empty groups. Fail closed if permission enumeration fails. Do not use admin credentials or an admin fallback. Preserve necessary metadata for the existing Flutter models but remove upstream filesystem paths and credentials.

## Playback boundary

POST `/api/items/:id/play` starts a real ABS session with browser-capable MIME types, `mediaPlayer:html5`, `forceDirectPlay:false` unless explicitly codec-qualified, unique app/device namespace, and no unsupported startOffset assumption. BFF verifies returned owner, binds the playback ID to the current app cookie, and adds `webGeneration` to the returned session. Every sync/close body includes `webGeneration` and strictly increasing integer `webSequence`, added by Dart ApiService. BFF strips these two fields before ABS forwarding, rejects obsolete generations/sequences, serializes per-session operations, and closes the previous app-owned session before opening another. There is one writer per user/device namespace; do not close unrelated devices' sessions.

Sync endpoint is singular `/api/session/:id/sync`; `{currentTime,timeListened,duration}` uses seconds, with listening increment rather than cumulative position/duration. Success is plain `OK`; close also returns plain `OK`. Validate finite bounded values. Never blindly retry an ambiguous nonzero listening increment; reconcile open-session timeListening/currentTime first or conservatively avoid recounting. Duplicate client sequences must not duplicate history. A late close must not overwrite a new generation. On ABS-session 404 return a visible recoverable session-expired state; do not silently recreate and replay a stale position. Reconnect reads current server progress before the user resumes; another-device progress wins unless the user explicitly selects a local checkpoint.

BFF permits GET/HEAD media only for authenticated, authorized items and owned sessions. Preserve Range/If-Range/validators and 200/206/304/416, content lengths/types/ranges; stream with backpressure, abort on disconnect, never buffer books. Immutable session upstream, no redirects to other origins, no untrusted contentUrl destinations. Authenticated `/public/session/:id/track/:index` can remain the Flutter URL form but must validate cookie ownership before forwarding. App media URLs contain no ABS credential. Unsupported HLS codecs must produce a useful error unless a tested browser HLS adapter is implemented; do not claim HLS support from an m3u8 response alone.

## Flutter ownership and UX

The adapter owns same-origin selection, MIME negotiation, generation/sequence maps,
and cookie-sentinel compatibility while preserving native branches. Web playback
uses authoritative progress and explicit recovery. Tesla mode adapts the existing
book-first player for narrow panes, with persisted manual selection and large touch
targets. Release-web debug output is disabled to avoid capability-bearing diagnostics.

## Tests and honest qualification

Focused Node tests run via `node --test server/test/*.test.mjs` using a clearly synthetic local ABS test fixture, never mislabeled as production evidence. Real owner account is not replaced by a synthetic account. Actual ABS write tests must use a clearly isolated disposable test account/book, not any reader's progress. Separately verify real browser playback/progress against installed ABS; Flutter unit/widget tests run with the real containerized SDK. Desktop, Android emulation, actual Android, and physical Tesla evidence are separately labeled. Physical Tesla behavior remains unverified without the vehicle. Corresponding source and GPL/upstream notices ship with the browser bundle.
