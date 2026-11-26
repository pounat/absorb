# Read Along appearance

The Aa action in the browser Read Along reader opens a scrollable appearance sheet.
Text size (14–36px), line spacing (1.20–2.20), Serif (Georgia), Sans-serif
(Arial/Helvetica), System font, and Dark/Sepia/Light themes apply immediately.
Reset restores 20px Georgia, 1.75 spacing and Dark. Preferences are nonsecret,
device/browser-local SharedPreferences under `readalong_appearance_v1`, shared
across books. They are not sent to the media server or attached to an account.

The trusted host validates numbers and enumerated identifiers independently of
Dart. Only its own stylesheet is changed: no chapter fetch, frame replacement,
media owner change, playback action or progress write. The first visible text
block's viewport offset is preserved across reflow, including with Follow off.
Publication fragment IDs and existing active-highlight/follow handling remain.
Publisher paragraph fonts/colors are overridden for readable preferences; heading
hierarchy and emphasis remain, images are not inverted. No downloadable fonts.

The publication sandbox still allows same-origin DOM access but never scripts;
all sanitization, scoped resource policy, strict production CSP and late-owner
fences remain. Local JSON is untrusted and malformed values use bounded defaults.
The web finalizer versions the reader helper by its actual SHA256, as well as the
compiled main/bootstrap. A normal reload is enough; clearing browser storage is
not required.

The reader suspends only its own iframe's pointer input while the appearance
sheet is open, restoring the exact prior inline value on dismissal or disposal.
This keeps touchscreen sheet controls reachable without replacing publication
or media state; duplicate opens and late iframe initialization are fenced.

Qualification uses synthetic media/users through the unchanged real BFF and the
compiled Flutter UI under production CSP, with computed iframe styles, advancing
and paused original media, exact document/media identity, chapter changes,
reader remount, authenticated reload and genuine persistent-profile reopen.
390×700 and 1000×640 sheets are checked; this is not physical Tesla certification.
Private QA scripts/credentials/screenshots are deliberately outside this source.
