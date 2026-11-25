# Browser server selection

The shared sign-in form exposes **Server URL → Username → Password**, in that
order, for Audiobookshelf and BookOrbit. Every new/add-account form starts blank.
Changing provider clears the URL and credentials and invalidates validation.
Enter a complete HTTPS URL; a simple base path is supported. URL validation in
the browser is local syntax checking, not an upstream probe. No server is
contacted until an explicit sign-in. Startup may restore an explicitly saved
account, but a fresh installation has no destination and makes no upstream call.

Credentials go only to the same-origin BFF. `/login` selects ABS;
`/bookorbit/api/v1/auth/login` selects BookOrbit. Both receive bounded JSON
`{serverUrl,username,password,sessionRouting:true}`. The BFF applies the same
strict destination policy before sending credentials, then binds the selected
origin/base path and pinned DNS answers immutably to that cookie authority.

## Account isolation

Each sign-in has a separate, nonsecret public routing label under
`/sessions/:label` or `/bookorbit/sessions/:label`. A matching Secure, HttpOnly,
SameSite=Strict cookie is scoped to that path. The routing label alone, a cookie
from another account, an omitted cookie, or a different provider cannot authorize
requests. All subsequent catalog/media/progress/refresh/logout requests use that
route. BookOrbit file handoff links retain the same route and require its cookie.

Browser account preferences intentionally retain the entered normalized URL,
provider, username and **nonsecret routing label**, not passwords or upstream
access/refresh tokens. Account scopes include provider, full normalized URL
(including scheme/base path) and username; same IDs on different servers do not
share progress/settings. An unavailable saved cookie does not trigger a fallback
login or select another server. Server credentials remain only in BFF RAM.
Restarting the BFF requires signing in again.

## Destination policy

- Public HTTPS by default; no default upstream or automatic server discovery.
- Reject credentials, query/fragment, control characters, percent escapes,
  backslashes, traversal, ambiguous numeric addresses and unsupported base paths.
- Reject nonpublic/reserved IPv4 and IPv6. DNS answers must all satisfy policy;
  mixed public/private answers fail closed before credential transmission.
- DNS is pinned for each authority and used by every actual socket, including
  refresh, identity, catalog and downloads; hostname/TLS verification is retained.
- Redirects are denied, not followed. Native media validator 304 is preserved.
- Bounded DNS, headers/body, JSON, inbound body, admission and session lifetimes
  remain enforced. This is not an arbitrary URL or mutation proxy.

`PUBLIC_ORIGINS` is required: comma-separated exact trusted HTTPS browser origins.
The production entrypoint ignores legacy fixed-upstream environment settings.
The low-level ABS app retains its fixed-upstream compatibility seam for existing
embedders/tests; the public multi-provider entrypoint never supplies that seam.

## Explicit self-hosted private-server opt-in

`ABS_ALLOWED_UPSTREAMS` is the shared operator destination allowlist for **both**
providers (the name is retained for compatibility). Specify exact scheme, host
and port origins, with no wildcard/suffix matching. This grants private address
access only to explicitly trusted DNS administrators. To permit HTTP for one of
those origins also set `ABS_ALLOW_HTTP=true`. Neither option supplies a default
login URL. Link-local/metadata/multicast/unspecified destinations remain blocked
even when allowlisted. Prefer HTTPS. Attach a private Docker network manually
only if your chosen server needs it; the default Compose has no external network.
Never commit an actual deployment configuration or secrets.

## BookOrbit capability boundary

Supported: username/password login, library browsing, protected covers, in-app
audiobook listening and EPUB narration, native CAS audiobook positions, narration
positions and listening-session accounting. Permitted file downloads remain an
optional script-free same-origin handoff, not the primary listening action.
[Read Along](bookorbit-readalong.md) renders sanitized prepared narrated EPUB text
with native passage timing. Administration, TTS and unrelated mutations are not
implemented for BookOrbit web. Native provider paths are preserved. Book membership and
manifest/playlist membership are checked before media admission; the upstream
server remains authoritative for native permission revocation. Every media URL
uses the selected account's `/bookorbit/sessions/<label>/api/v1/` cookie path.
No token or upstream-host URL is placed in media or handoff links. BookOrbit JSON
sends explicit Content-Length for the 3.8 protocol; ABS framing is unchanged.

## Qualification

```sh
node --test server/test/*.test.mjs
flutter test test/web_adapter test/web_playback test/web_tesla
flutter build web --release --base-href /absorb/ --no-web-resources-cdn --no-wasm-dry-run
python3 tools/finalize_web_update.py
CHROME_BIN=/path/to/chromium python tests/browser/server_login.py
```

Node and browser fixtures use synthetic local providers, generated test TLS and
synthetic audio only. They do not qualify an installed server version, real
content, physical Tesla hardware, or native device builds. BFF protocol/permission
coverage and actual compiled-browser UI/media evidence must be reported separately.
