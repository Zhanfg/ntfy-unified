# G2 narrow drawer CI evidence

Linux CI launches the actual Tauri executable in a fresh 360x640 Xvfb display
with a temporary GNOME Secret Service. It captures: closed.png, open.png,
escape-closed.png, reopened.png, backdrop-closed.png.

The test asserts the backdrop outside the 256px drawer visibly dims when opened
and returns to its original brightness after Escape and an outside click. It also
verifies the app stays running and an ephemeral keyring works. Failure blocks the
Linux job; screenshots and app.log are uploaded **even on failure** for triage.

This is a new HOME and a blank local database. No user server or token is used.
It cannot replace real desktop/device E2E or human visual QA; review screenshots
from CI artifacts and check keyboard focus and forms separately.
