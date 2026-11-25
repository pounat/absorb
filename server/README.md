# Absorb Web BFF

Dependency-free Node 22+ server. `createProviderApp({origins, allowedUpstreams, allowHttp})` in `providers.mjs` returns a Node request listener for both providers. Set required `PUBLIC_ORIGINS` using your own protected configuration, then start:

```
node server/index.mjs
```

`index.mjs` binds **0.0.0.0:3000**. `PUBLIC_ORIGINS` is comma-separated exact HTTPS origins (no trailing slash). Browser login selects an immutable per-session server under the [destination policy](../docs/server-selection.md). The production entrypoint never configures a default upstream. The low-level ABS app keeps its legacy fixed-upstream embedding seam for regression tests only. No forwarded-host trust, external redirects, root npm package, or third-party runtime dependencies. DNS results are pinned for each session; login again after a selected destination changes. Link-local/multicast/unspecified destinations, including mapped IPv4 link-local addresses, are denied.

**Health check: public GET `/ping` returns 200 text `pong`, without contacting ABS.** `/status` returns only minimal ABS initialization/version data and advertises local login only. Health is process liveness, not upstream readiness.

## Browser protocol (ABS unless noted)

- Login accepts bounded JSON serverUrl/username/password, uses modern ABS token headers, and creates an opaque random cookie. The compiled browser also requests `sessionRouting:true`, receiving a nonsecret route label and a separate Secure/HttpOnly/SameSite=Strict cookie path per account. Legacy embedding tests retain Path=/. The matching route and cookie are both required; the label is not a credential. Only explicitly passed `secureCookie:false` permits synthetic local HTTP tests. It is not an environment switch or forwarded-header inference.
- Only the cookie authenticates; bearer headers and query token values are not credentials. Browser-compatible `user.accessToken`/`user.refreshToken` are the **nonsecret `browser-cookie` sentinel**. No real ABS credential is emitted. User/envelope fields are explicitly projected; embedded auth-envelope progress/bookmarks are empty and must be obtained from dedicated permitted read APIs.
- Every non-GET/HEAD request requires an exact configured Origin and `application/json`, maximum 65,536 bytes. Login defaults to 10 validly shaped attempts/minute per socket peer, independent of spoofable forwarded IP headers. Behind one Nginx ingress that is effectively a shared login budget. Upstream JSON responses are capped at 8 MiB; socket idle timeout is 30 seconds.
- Refresh is single-flight per cookie, rotates the credential pair, retries once only after a definitive upstream 401, and never refreshes on 403. Failure revokes local authorization. Logout removes the local cookie authority first, queues best-effort empty-body closes of that cookie's playback, then revokes only its refresh session (never allDevices).
- Responses are private/no-store and no-referrer. The server does not log request URLs, credentials, bodies or upstream errors.

### Bounded cookie authority

Sessions expire at **7 days absolute** or **1 day idle**, whichever comes first. Only admitted cookie-authenticated requests touch idle time; activity and token rotation never extend absolute lifetime. Login sets cookie `Max-Age` to the absolute lifetime; an expired, revoked or unknown cookie receives HTTP 401 and a matching HttpOnly/SameSite/Secure `Max-Age=0` deletion. Refresh failure also clears the cookie immediately. Server time, not browser cookie retention, enforces expiry. Already admitted media streams are not forcibly interrupted by expiry.

The process admits at most **256 session slots**, counting pending upstream logins and retiring sessions until cleanup finishes. A full process returns **503 `{error:"session_capacity"}`** before contacting upstream login, without setting a cookie or evicting an active reader. Failed login releases its reservation. Capacity may remain unavailable while expired-session cleanup is in flight; retry explicitly rather than displacing another reader.

A single unreferenced per-app scheduler sweeps every **60 seconds**; nonpublic requests also sweep and cookie lookup checks exact expiry boundaries. Revocation is immediate and idempotent. Retirement queues best-effort empty-body closes only for playback owned by that cookie, waits for its in-flight refresh, revokes only its resulting refresh session, releases owned records/unused writer queues, and clears local credentials even when upstream cleanup fails. A late successful rotation remains private and is revoked; it cannot restore cookie authority. No all-devices logout or progress/listening increment is sent.

Programmatic test/operator options are `createApp({..., now: () => milliseconds, sessionPolicy: {absoluteMs, idleMs, maxSessions, sweepMs}})`. Omitted fields use the defaults above; explicit bounds must be positive safe integers (`sweepMs <= 2147483647`). They are server-side options, not request fields or forwarded headers. `await app.dispose()` clears its unreferenced timer and drains already-started retirement work when an embedding/test tears down its listener; it is not a substitute for explicit user logout. No credential persistence is added.

## Exact surface

- Public GET `/ping`, `/status`.
- POST `/login`, `/auth/refresh`, `/logout`.
- GET `/api/me`.
- GET `/api/libraries`; `/api/libraries/:id`; and library `items`, `search`, `personalized`, `series`, `authors`, `narrators`.
- GET expanded `/api/items/:id`, `/api/authors/:id` (including `include=items,series&library=:libraryId`), `/api/series/:id`, `/api/libraries/:libraryId/series/:seriesId`. Author/series details require association with an enumerated visible book; results and counts are intersected with that entity/library's visible item IDs.
- Authenticated GET/HEAD `/api/authors/:id/image`, with its own visible-author association guard. Only bounded width/height/format options forward; timestamp/cache-busting and query credentials do not.
- GET `/api/me/progress`, item/episode progress, bookmarks, listening sessions/stats and item listening sessions. No authentication-device sessions are exposed.
- Collection listings return empty compatible objects without upstream requests; collection details are not permitted.
- POST `/api/items/:id/play` (optional episode suffix); owned GET `/api/session/:id`; POST owned session `sync`/`close`.
- Authenticated GET/HEAD `/api/items/:id/file/:ino`, `/api/items/:id/cover`, `/public/session/:id/track/:index`.

Everything else is denied without forwarding, including metadata/admin/upload/delete endpoints, mutating GET shortcuts, arbitrary API endpoints, raw HLS, and direct progress PATCH. Query names for permitted reads are allowlisted in `reads.mjs`; raw token query values are dropped.

Every metadata read/media admission/playback start enumerates **all** accessible-item pages under that reader's own credentials. Duplicate IDs, changing totals, empty incomplete pages or enumeration failures fail closed. Nested item objects/references are intersected with that set; empty groups are omitted and affected local counts are rebuilt. Unmodified book pagination totals are preserved. Entity-only author/series rows (including search wrappers, typed personalized shelves, library lists and included filterdata) are checked against visible-book associations within the requested library; narrator/tag/genre rows or filter strings use exact-name associations from trusted expanded metadata. ABS 2.36 list pages are always minified, so entity-bearing routes, author images and included filterdata perform an additional private reader-authorized `POST /api/items/batch/get` read in sequential batches of at most 100 already-enumerated IDs. Complete exact batch membership, duplicates, library IDs and association shapes are validated before release. Missing/revoked items or malformed batches fail closed; display names never establish author/series IDs. Ordinary book reads, item media/cover/ranges and playback admissions do not fetch these expanded batches. The browser batch POST remains denied and its mutation allowlist is unchanged. Retained entity book/item counts are rebuilt from associated visible items. Entity-list/shelf totals describe the returned visible rows, not an upstream full search total. A conflicting library path/query is denied before forwarding. Embedded visible-book metadata keeps its author/series navigation IDs and sequences; arbitrary entity IDs are never treated as book IDs. Metadata is recursively field-allowlisted; upstream filesystem paths, track metadata, credential fields and arbitrary content URLs are removed. Media destinations are constructed from validated item/session/track routes, not taken as generic URLs.

**Cover DTO contract delta:** a nonempty upstream string `media.coverPath` becomes the fixed nonsecret **`"browser-cover"` presence marker**, at any nested book DTO depth; absent/empty/nonstring values do not advertise a cover. This is deliberately **not a fetchable URL**. The existing Flutter `registerBookCover`/detail-sheet consumers only test nonemptiness, then `ApiService.getCoverUrl(itemId)` constructs the same-origin `/api/items/:id/cover` URL. The narrow projection also retains scalar shelf `label`, series `sequence`, `numBooks`, safe `ino`, and nested `collapsedSeries`; restored `libraryItemIds` are deduplicated/intersected with accessible IDs and affected counts rebuilt. Expanded-track `contentUrl` survives only as a validated relative `/api/items/<parent-item-id>/file/<ino>` route with all query material removed; foreign, traversal and cross-item routes are omitted. Actual upstream cover filesystem paths never cross the boundary, `imagePath` is still removed, and permission filtering/cover proxy admission are unchanged. Compiled-browser verification remains a separate integration gate.

## Ordered playback and recovery

`webGeneration` is an integer returned on start/session read. Sync/close require this generation plus a strictly increasing positive integer `webSequence`. They are stripped before forwarding. Operations, including start/supersession/logout, serialize in a per-user app-only namespace shared across cookies/tabs. A deterministic server-created `absorb-web-<sha256>` device ID hashes the validated ABS user ID under the fixed `absorb-web:v1` domain. It remains stable across manager/process recreation so the next ABS start can replace that app/user's pre-restart device playback, without colliding with native/unrelated devices. Multiple separate BFF deployments against the same ABS intentionally share this app/user identity; concurrent replicas are still unsupported. Ownership/generation authority is not restored from the hash; reauthentication and a fresh explicit start remain mandatory. Prior app playback is closed without any stale position before another start. Returned owner and item must match before a playback session is admitted.

Start uses browser-provided MIME support intersected with a small audio allowlist; forces `mediaPlayer:html5`, `forceDirectPlay:false`, `forceTranscode:false`, and ignores client device IDs/startOffset. Direct track URLs returned to the browser are same-origin cookie-authenticated paths. HLS/external destinations are explicitly unsupported, never advertised as working.

Sync/close forward only finite nonnegative seconds (`currentTime`/`duration` <= one year, `timeListened` <= one hour). Success is plain `OK`. Duplicate/obsolete sequence/generation is HTTP 409. A dispatch/5xx ambiguity reserves the sequence and freezes subsequent increments with `session_reconciliation_required`; **no ambiguous listening write is retried**. Conservative recovery requires an explicit new start, which closes the old session without a delta; it may undercount rather than double-count. HTTP 404 returns `session_expired`, never silently recreates/replays. The client must reread authoritative progress before explicit recovery and resolve another-device/local-checkpoint conflicts itself.

Error bodies are fixed JSON `{error: code}` including `authentication_required`, `authentication_expired`, `upstream_unavailable`, `session_expired`, `obsolete_playback`, `listening_write_uncertain`, `session_reconciliation_required`, and `hls_not_supported`. Nonzero listening writes have no exactly-once guarantee across process death, because ABS itself supplies no idempotency key/CAS.

Media uses native HTTP streams with backpressure and disconnect cancellation. GET/HEAD, Range/If-Range/validators, 200/206/304/416, lengths/types/ranges are preserved. Upstream cookies, redirects and acceleration headers are not forwarded. Compressed media responses are conservatively rejected rather than corrupting byte ranges.

## Verification and limits

```
node --test server/test/*.test.mjs
# Host default was Node 24; exact Node 22 verification also executed:
npx --yes --package=node@22 node --test --test-reporter=spec server/test/*.test.mjs
```

All fixtures are synthetic local HTTP servers exercising the real request listener
and transport; they are not production account or playback evidence. Run the suite
against the exact candidate before review. No private release receipts are included.

Remaining release gates/limitations:

- Operators must verify real ABS login/rotation/DTO compatibility, browser direct audio/ranges, progress readback and Flutter error UX using an isolated disposable reader/book. Physical Tesla is unverified.
- Single Node process/replica only. In-memory credentials, ownership, writer queue, rate buckets and generations disappear on restart; reauthentication is mandatory. No persisted exactly-once accounting, distributed lease, durable session store or horizontal scaling claim. Bounded local expiry/admission is implemented above; cleanup is best effort and cannot guarantee upstream revocation across process death.
- Full enumeration on every read/media admission is intentionally conservative and potentially expensive on large libraries; no permission snapshot cache is currently used. Changes during enumeration are not an upstream transactional snapshot. A filtered paginated nested group reports only its filtered local count, not a newly enumerated full search-result total.
- No HLS/socket adapter, OIDC, API-key login, ebooks, bookmarks/progress editing or native offline-sync endpoints. Unsupported ancillary Flutter features receive errors rather than passthrough.
- Metadata DTO projection is deliberately narrow and requires real Flutter integration review, especially optional podcast/author/stats fields. The root-origin Docker deployment is the exercised URL form; synthetic base-path forwarding is tested, but installed-server track URL variants remain a separate compatibility gate.
- A supersession can be blocked if closing the previous app session cannot be confirmed (including its old authentication expiring); it fails conservatively instead of opening competing writers.

## BookOrbit provider

`createBookOrbitApp` owns only `/bookorbit/` and has separate cookies, token state,
rate budget, bounded admission and retirement. Login requires an explicit URL and
uses the identical `selectUpstream`/pinned transport policy as ABS. There is no
fixed server in the production provider dispatcher. Browser routes are
`/bookorbit/sessions/:public-label/api/v1/...`; only the matching HttpOnly cookie
authorizes them. Upstream access/refresh tokens and passwords never cross the BFF
response boundary. BookOrbit alone adds explicit Content-Length on JSON requests
for the 3.8 native admission protocol; ABS framing is untouched.

The allowlist is limited to login/me/refresh/logout, app-info, library reads and
book queries/details/audio-progress reads; protected covers; and a file download
whose membership in the selected book is checked immediately before admission.
The upstream's reader permissions remain authoritative. Download permission
revocation is not bypassed by cached book membership. Range/HEAD/304/416 are
preserved. Cover/download destinations are constructed, never taken from external
thumbnail URLs. The script-free book access HTML links only to this cookie route.
No web embedded playback/reading, progress mutation, TTS or administration is
implemented for this provider. Native BookOrbit controls remain platform-gated
and unchanged. See `docs/server-selection.md` for the full capability disclosure.
