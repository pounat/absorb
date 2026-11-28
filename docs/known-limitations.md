# Known limitations and qualification boundaries

## Release and device status

- The canonical requested endpoint is `https://absorb.example.com`. A working isolated HTTPS qualification stack is not proof that this public endpoint is deployed. Configure and verify your own HTTPS endpoint.
- Synthetic fixture tests do not establish production login, private-library playback or production-library performance. Browser/device integration must be verified independently.
- Physical Android and Tesla Model Y browsers have not been qualified. Desktop narrow/touch emulation is not a physical-device test. Use `tesla-testing.md` while parked; only a passenger should interact if any subsequent test occurs while moving.
- Background playback, screen/focus changes, steering-wheel controls and playback while driving are not promised. The application does not bypass vehicle/browser safety restrictions. Long automotive listening sessions remain a separate field test.

## Authentication and deployment

- Audiobookshelf and BookOrbit username/password connections require an explicit user-entered server URL. Public HTTPS destinations are validated and pinned per account; private/HTTP servers require explicit operator opt-in. Saved accounts have isolated scoped cookie routes. OIDC/API-key sign-in and full native feature parity are not provided.
- The BFF is a single-process service. Credentials and opaque-cookie sessions are held in memory; restarting it requires sign-in again. Do not horizontally replicate it without adding an appropriate shared authority design.
- Default auth bounds are a seven-day absolute lifetime, one-day idle lifetime and 256 admitted/pending/retiring sessions. Capacity rejection does not evict an active reader.
- Upstream addressing is pinned for each account session. If its backend address changes, sign in again rather than weakening destination controls.

## Playback and progress

- Direct browser-decodable audio is supported; AAC/M4B and multi-file playback require integration qualification on your server. Codec support still depends on the client. HLS/transcoding sessions and DRM media are outside this release.
- Audio starts from a user gesture. Browser autoplay policy or vehicle firmware can still reject playback; the application cannot override either.
- ABS browser session sync posts directly after about twenty seconds, then every ten seconds, without recurring progress GET preflights. Pause, seek and lifecycle checkpoints remain. BookOrbit retains its separate native progress policy. Network latency, process termination and shutdown can lose the final unacknowledged segment.
- Transient ABS sync failures do not pause audio; four failures warn. Explicit 401/403/404/409 suspends saving until user recovery without stopping buffered audio. The nine-second warning deadline retains the actual transport until settlement, so a transport that never settles can block later writes/close indefinitely. Increments are consumed once and never replayed after uncertainty; no offline listening ledger is promised. The BFF retains its uncertain-write quarantine.
- A failed progress read is not treated as position zero. Only a confirmed progress 404 permits the new-book absence path; nonzero-baseline absence blocks automatic writes.
- Audiobookshelf has no atomic cross-device compare-and-swap transaction. Strict initial/recovery reads and owned ordered sessions do not prevent independent native-device last-writer races. BookOrbit validates native revision acknowledgements, but this does not create an atomic cross-device transaction across every native progress endpoint. HTTP/3/network behavior is unchanged.
- Native cross-book cached prebuffer/metadata-only promotion is disabled on web. Each next book must take the normal reconciled browser session start. Native-device behavior has not been runtime-qualified by this web work.
- This is not an offline downloader. Already-buffered audio is not a supported offline queue or a durable progress journal.

## Permissions and feature parity

- Reader permissions remain authoritative. Collections and unsupported native/admin routes may be omitted or denied rather than disclose nested books. This release does not replace the Audiobookshelf administrative UI.
- ABS 2.36 entity search/series responses can contain unfiltered metadata or aggregates. The BFF filters associations/counts and omits unsafe series aggregate duration; other ABS clients and the upstream deployment are not patched by this fork.
- Entity/filterdata routes expand the reader's accessible catalog in sequential batches of at most 100 IDs. Their cost is linear in accessible catalog size; large-library performance has not been production-qualified. Ordinary book/media/range/playback admissions avoid those expanded reads.
- There is no atomic upstream snapshot across enumeration, expanded association reads and final metadata reads. Local buffered JSON responses are separately fenced against completed local revocation; previously admitted media streams follow their documented streaming policy.
- External cover search, administration, offline downloads and casting are not newly supported. BookOrbit prepared narrated EPUBs support sanitized in-app passage-level Read Along, not word alignment or full pagination/annotations; ordinary MP3 plus plain EPUB does not imply alignment. BookOrbit native downloads remain separately permission-gated. See [Read Along limits](bookorbit-readalong.md).
