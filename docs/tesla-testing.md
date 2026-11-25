# Real-vehicle Tesla test checklist

**Status: physical Tesla testing unverified.** A desktop browser, Android user-agent emulation, narrow viewport screenshots and Flutter widget tests do not establish vehicle behavior.

Test while **parked first**, using the right-side browser pane rather than assuming the whole vehicle display is available.

1. Open `https://absorb.example.com`; confirm valid HTTPS, normal loading, and a useful error if offline.
2. Sign in with the intended ABS account. Check accessible books only, actual cover art, Continue Listening, search and book details.
3. Start a book with a deliberate tap. Confirm sound, title/progress legibility, and no clipped controls or horizontal scrolling.
4. Pause/resume; jump back 15 seconds and forward 30 seconds; seek without relying on a tiny drag handle; change speed and choose a named chapter.
5. Wait at least one periodic checkpoint. Pause and verify the resulting position from another ABS client. Reopen the web app and verify resume near that saved position.
6. Resize/switch browser pane or vehicle screen and return. Record whether audio continues, pauses, buffers or requires another tap. Do not assume background audio support.
7. Briefly interrupt connectivity; return online and confirm a visible recovery state and sensible authoritative position, not silent reset or duplicate sessions.
8. Try automatic narrow mode and Settings' manual Tesla Mode. Check large separated touch targets, dark contrast and reduced animation preference.
9. Sign out and confirm protected API/media access no longer works. Reauthentication must be clear after an API-container restart or session expiry.
10. Record Tesla model, firmware/browser version, approximate pane dimensions, date, audio/background interruption behavior and each failed step. Never include passwords, tokens, session capability URLs or private book/account screenshots in a public issue.

If testing while moving, only a **passenger** may interact. Do not alter vehicle software, defeat safety restrictions, or infer steering-wheel/native media controls from this web app.
