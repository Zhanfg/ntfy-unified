#!/usr/bin/env bash
# Screenshot interaction test of the real Tauri webview. Fresh HOME, no real credentials.
set -euo pipefail
if [[ "$1" != "--inside" ]]; then
  APP="$(readlink -f "$1")"
  OUT="$(readlink -m "$2")"
  mkdir -p "$OUT"
  exec xvfb-run -a -s "-screen 0 360x640x24" \
    dbus-run-session -- bash "$0" --inside "$APP" "$OUT"
fi
shift
APP="$1"
OUT="$2"

HOME="$(mktemp -d)"
export HOME
chmod 700 "$HOME"
APP_PID=""
cleanup() {
  if [[ -n "$APP_PID" ]]; then
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
  rm -rf "$HOME"
}
trap cleanup EXIT

keyring_password="$(head -c 32 /dev/urandom | base64)"
eval "$(printf '%s\n' "$keyring_password" | gnome-keyring-daemon --daemonize --login --components=secrets)"
unset keyring_password
printf ready | secret-tool store --label=g2-drawer-ci application g2-drawer-ci
test "$(secret-tool lookup application g2-drawer-ci)" = ready

"$APP" > "$OUT/app.log" 2>&1 &
APP_PID=$!
WINDOW=""
for _ in $(seq 1 45); do
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    echo "Native Tauri process exited before drawer test" >&2
    exit 1
  fi
  WINDOW="$(xdotool search --onlyvisible --name 'ntfy-unified' | head -n 1 || true)"
  if [[ -n "$WINDOW" ]]; then break; fi
  sleep 1
done
test -n "$WINDOW"
xdotool windowsize "$WINDOW" 360 640
xdotool windowmove "$WINDOW" 0 0
xdotool windowfocus "$WINDOW" || true
sleep 4

capture() { import -window root "$OUT/$1.png"; }
capture closed
xdotool mousemove --window "$WINDOW" 34 44 click 1
sleep 2
capture open
xdotool key Escape
sleep 2
capture escape-closed
xdotool mousemove --window "$WINDOW" 34 44 click 1
sleep 2
capture reopened
xdotool mousemove --window "$WINDOW" 340 320 click 1
sleep 2
capture backdrop-closed

python3 - "$OUT" <<'PY'
import os, subprocess, sys
out = sys.argv[1]
def pixel_change(first, second):
    source = os.path.join(out, first + ".png")
    target = os.path.join(out, second + ".png")
    result = subprocess.run(
        ["compare", "-metric", "AE", source, target, "null:"],
        capture_output=True, text=True
    )
    if result.returncode not in (0, 1):
        raise AssertionError("ImageMagick compare failed: " + result.stderr[-400:])
    return int(result.stderr.strip().split()[0])
opened = pixel_change("closed", "open")
reopened = pixel_change("closed", "reopened")
escape_restored = pixel_change("closed", "escape-closed")
backdrop_restored = pixel_change("closed", "backdrop-closed")
same_open = pixel_change("open", "reopened")
print("360px drawer changed pixels:", {
    "opened": opened,
    "reopened": reopened,
    "escape_to_baseline": escape_restored,
    "backdrop_to_baseline": backdrop_restored,
    "open_reopen_delta": same_open
})
# Compare screenshots at the actual 360 x 640 pixel root, not absolute luminance.
# Dark and light themes differ in total brightness; pixel-change ratios are
# theme-neutral, while still requiring large opening changes and real closure.
assert opened >= 50000, "Navigation did not visibly open"
assert reopened >= 50000, "Navigation did not visibly reopen"
assert escape_restored < opened // 10, "Escape did not restore closed view"
assert backdrop_restored < reopened // 10, "Backdrop click did not restore closed view"
assert same_open < opened // 10, "Reopened drawer does not match the open view"
print("PASS: 360px drawer opens, Escape and backdrop close, reopening stable")
PY
