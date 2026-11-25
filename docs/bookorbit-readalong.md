# BookOrbit native Read Along (web)

Prepared narrated EPUBs now have an in-app **READ ALONG** action in their book details. The view renders sanitized publication text and follows the current Absorb player's native media-overlay fragment. Open is read-only; Play/Pause and ten-second seeks operate the existing player and its existing native progress/session flow. Reload reads the selected narrated file's native saved position without saving a local zero. Switching accounts retires the view.

## Trust boundaries

- Existing native `GET /epub/:book/info?fileId=:file` supplies publication manifest and spine. The new BFF `GET /epub/:book/publication/:file/*` rechecks native book/file access and exact manifest membership on **every** entry fetch; XHTML must also belong to the spine. Only XHTML/HTML, CSS, selected raster images and fonts are admitted, with an 8 MiB entry bound. No generic ZIP/download proxy, browser upstream URL, reader mutations or generated audio are added.
- A trusted same-origin host fetches XHTML as data, copies allowed structural/typographic markup into an inert sanitized document, and uses `iframe.srcdoc` with `sandbox="allow-same-origin"` **without scripts**. Publisher scripts, handlers, forms, nested frames, embeds, base elements and external links are not retained. Nested CSP denies scripts, connects, media, objects and forms; CSS/image/font fetches are scoped to that book/file publication path. External CSS imports/beacons are CSP-blocked before network. The parent uses `getElementById`, not publisher-controlled selectors or book messages.
- Existing global `X-Frame-Options: DENY` and `frame-ancestors 'none'` remain unchanged. HTTP publication documents cannot be framed; srcdoc is intentionally used instead. The original ZIP stays immutable.

## Scope and limitations

This is **passage/fragment-level native timing**, not word alignment. Unmatched text remains readable. Follow scrolls on passage-block changes and pauses following briefly after manual interaction; it never autoplays. Narrated EPUBs whose audio is the EPUB overlay are supported. Separate audiobook/EPUB pairs requiring scaled alignment, ordinary MP3s, PDFs/comics, SVG/MathML, embedded publisher style blocks, complex scripted/fixed-layout publications and arbitrary encoded/non-ASCII ZIP member names are not newly supported. External publication dependencies are deliberately blocked. Basic paragraphs, emphasis, inline typographic declarations, allowed local stylesheets, raster images and fonts are retained. This does not promise native Readium pagination, bookmarks or annotation parity, word precision, or physical Tesla codec/device certification.

Every publication request uses the selected account's immutable server binding and scoped cookie route. Resource URLs retain that account prefix.
