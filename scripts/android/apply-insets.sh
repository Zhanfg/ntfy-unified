#!/usr/bin/env bash
# Must run after Tauri Android init, before Kotlin/Gradle compilation.
set -euo pipefail
python3 - <<'PY'
from pathlib import Path
import re

root = Path("src-tauri/gen/android/app/src/main/java")
activities = sorted(root.rglob("MainActivity.kt"))
if len(activities) != 1:
    raise SystemExit(f"Expected exactly one generated MainActivity, got {len(activities)}")
dest = activities[0]
source = dest.read_text()
match = re.search(r"(?m)^package\s+([A-Za-z_][\w.]*)\s*$", source)
if not match or "TauriActivity" not in source:
    raise SystemExit("Unexpected Tauri Android MainActivity; refuse to overwrite")
template = Path("android/overrides/MainActivity.kt.in").read_text()
assert template.count("__TAURI_PACKAGE__") == 1
dest.write_text(template.replace("__TAURI_PACKAGE__", match.group(1)))
plugin_template = Path("android/overrides/AppearancePlugin.kt.in").read_text()
if plugin_template.count("__TAURI_PACKAGE__") != 1:
    raise SystemExit("Invalid AppearancePlugin template")
plugin_dest = dest.with_name("AppearancePlugin.kt")
plugin_dest.write_text(plugin_template.replace("__TAURI_PACKAGE__", match.group(1)))
print("Applied native WindowInsets to generated Android Activity:", dest)
print("Installed native appearance plugin:", plugin_dest)
PY
