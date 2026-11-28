# Build and run the browser client

## Requirements

Docker Engine with Compose, a chosen Audiobookshelf or BookOrbit server, and a
trusted HTTPS reverse proxy. This project never creates or modifies upstream
servers/storage. No private/external Docker network is joined by default.

Set the required server-side variables through your own protected runtime
configuration: `PUBLIC_ORIGINS` (exact trusted HTTPS origins).
No deployment environment file or operator configuration is distributed here.
The browser selects its server at login under the [destination policy](server-selection.md). No default upstream is configured. `ABS_ALLOWED_UPSTREAMS` and `ABS_ALLOW_HTTP` explicitly grant private/HTTP exceptions for both providers. Do not put credentials in frontend build
arguments, source archives, or public issue reports. User access/refresh tokens
exist only in the BFF's memory. Example hostnames are not live services.

```sh
export SOURCE_COMMIT="$(git rev-parse HEAD)"
export IMAGE_TAG="$(git rev-parse --short=12 HEAD)"
docker compose config --quiet
docker compose build
docker compose up -d
docker compose ps
curl --fail --head http://127.0.0.1:13380/absorb/
```

The web listener defaults to loopback. Configure your own HTTPS reverse proxy to
reach it; preserve request Origin and cookies. Do not expose the insecure listener
directly. Secure cookies intentionally require HTTPS; no environment switch
weakens this default. Public routing and certificates are operator responsibilities.
Nginx must reach the BFF, never proxy protected routes directly to Audiobookshelf.

Both containers run unprivileged with read-only filesystems and bounded resources.
Health checks establish process liveness, not authentication, upstream readiness,
media playback or progress durability. Nginx access logs are disabled and API
errors do not echo upstream credentials. Avoid verbose request/body logging.

## Rebuild and tests

The Docker build pins Flutter 3.44.0 and serves the app at `/absorb/`. Roboto fonts
and their license are shipped locally; no runtime font CDN is required. For local
SDK checks, install that Flutter SDK, then run:

```sh
flutter pub get
node --test server/test/*.test.mjs
python3 -m unittest discover -s tests/deployment -v
python3 test/web_adapter/source_contract_test.py
flutter test test/web_adapter test/web_playback test/web_tesla
flutter build web --release --base-href /absorb/ --no-web-resources-cdn --no-wasm-dry-run
```

Two Dart transport tests require the synthetic BFF fixture. To include them,
start this in a separate terminal (stop it after the test run):

```sh
node test/web_adapter/synthetic_bff_fixture.mjs
```

Then run the focused suite with the fixture URL:

```sh
SYNTHETIC_BFF_URL=http://127.0.0.1:39871 flutter test --concurrency=2 test/web_adapter test/web_playback test/web_tesla
```

Use an isolated disposable reader and synthetic media for integration testing;
never use production accounts or listening history as fixtures. Physical device
qualification, HTTPS routing, and real-server compatibility are separate gates.
See [known limitations](known-limitations.md) and [parked testing](tesla-testing.md).

The build serves matching GPL source at `/source/absorb-web-source.tar.gz` and
`/source/LICENSE`. `tools/build_source_archive.py` excludes environment files,
Git metadata, generated output, and operator files. Preserve upstream attribution,
dependency locks and third-party font notices. Rebuild generated assets from source.

## Updates

Review changes before rebuilding; do not reset an existing deployment blindly.
Keep previous image digests and protected configuration outside the checkout.
Restarting the single-process API invalidates browser sessions and requires a new
login. It does not reset progress already acknowledged by Audiobookshelf.
