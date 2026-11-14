#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from pathlib import Path
import re
lib = Path("src-tauri/src/lib.rs").read_text()
cmd = Path("src-tauri/src/commands/mod.rs").read_text()
ntfy = Path("src-tauri/src/ntfy/notifications.rs").read_text()
sidebar = Path("components/ntfy/sidebar.tsx").read_text()
prefs = Path("components/ntfy/preferences.tsx").read_text()
route = Path("components/ntfy/desktop-only-route.tsx").read_text()
for module in ("automation", "tray", "windows", "modules"):
    assert re.search(r"#\[cfg\(desktop\)\]\s*mod " + module + r";", lib), module
assert "#[cfg(desktop)]\n    let builder" in lib, "desktop-only plugins no cfg"
assert "initialize_android_channel(app.handle())" in lib, "Android channel not initialized"
mobile = cmd.split("#[cfg(mobile)]\npub fn handler()", 1)[1]
for forbidden in ("automation::", "logs::", "runProgram", "test_rule"):
    assert forbidden not in mobile, "desktop-only IPC on mobile: " + forbidden
for required in (
    "create_channel(channel)",
    'ANDROID_MESSAGE_CHANNEL: &str = "ntfy-messages"',
    ".channel_id(ANDROID_MESSAGE_CHANNEL)",
    "permission_state()",
    "android_delivery_allowed",
    "notification_suppressed_permission",
    "notification_permission_check_error",
    "notification_channel_unavailable",
    "ntfy:delivery-error",
):
    assert required in ntfy, "missing notification implementation: " + required
assert ntfy.index('super::diagnostics::stage("receipt_stored")') < ntfy.index("let permission = app.notification().permission_state()"), "permission checked before message persistence"
assert "isPermissionGranted()" in prefs and "requestPermission()" in prefs, "missing UI permission action"
assert "{!android && (" in sidebar, "desktop sidebar links not gated"
for name in ("automation", "logs", "webhook"):
    assert f'href="/{name}/"' in sidebar, "missing guarded route: " + name
    assert "DesktopOnlyRoute" in (Path("app") / name / "page.tsx").read_text(), "unguarded desktop-only direct route: " + name
assert "navigator.userAgent" in sidebar and "navigator.userAgent" in route, "missing Android WebView UA detection"
assert "if (android === null) return null" in route, "desktop page may mount before Android check"
print("PASS: Android mobile Rust IPC and UI route boundaries enforced")
print("PASS: notification permission, channel initialization, denial/error fallback and saved Inbox")
PY
