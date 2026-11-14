# G3 msg-011 double inset and status bar regression

Supervisor prior device evidence at old signed 44593f51:
930x2048 screenshot, x=20 sample: near-white rows 0–103 (luminance
about 252), dark app from row 104 (about 28), menu top around 270.
Thus previous white band was 104 *physical pixels* and the gap
was about 166 *physical pixels*. Density for that shot is unknown,
so converting those pixels into dp would fabricate evidence.

The revised Android code paints native window/decor/content surfaces
dark (#0c1420) or light (#f2f5fb), and synchronizes icon appearance
using a minimal, isolated appearance plugin. Android content bounds
receive actual systemBars/displayCutout insets, dynamically computed.
CSS safe-area env() values are retained for numeric diagnostics but
are NOT applied as a second app-padding layer.

Kotlin NtfyInsets logcat lines expose native bars.top pixels, density,
native padding and computed dp. WebView [ntfy-ui-insets] lines expose
actual getComputedStyle CSS env and applied padding, viewport width,
DPR, design padding and first header control top. No secrets included.

## User-supervised real-device check

After the supervisor securely signs and installs a NEW head APK,
and only with explicit device-owner permission, execute:

    bash scripts/android/capture-display-density.sh 480 ./private-results

480 is an EXAMPLE alternative DPI. It must differ from the device's
actual setting. The script captures two real screenshots and
density/size/font-scale plus sanitized inset metrics, then restores
the original override with a trap. The validator requires:
- native top padding equals measured bars.top, in px
- applied CSS safe padding equals zero even if CSS env reports nonzero
- physical bars.top divided by display density equals native logged dp
- menu-button top is 20 ± 2 CSS dp, from safe WebView top

Screenshot comparison must also establish:
- no near-white stripe in dark mode, with readable status icons
- consistent light theme status background and dark icons
- no obscured controls above bottom gesture bar
- no duplicate blank space and reasonable drawer at both DPI settings

Do not claim a new physical measurement until the signed version is
tested on the phone. Untested G3 functional items remain: server
connection, topic subscription, message receipt and native notification.
PR #7 stays Draft, and G4 remains plan-only.
