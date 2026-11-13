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
def brightness(label):
    path = os.path.join(out, label + ".png")
    result = subprocess.check_output([
        "convert", path, "-crop", "1x1+340+320", "+repage",
        "-colorspace", "Gray", "-format", "%[fx:mean]", "info:"
    ], text=True)
    return float(result)
names = ["closed", "open", "escape-closed", "reopened", "backdrop-closed"]
values = {name: brightness(name) for name in names}
print("drawer backdrop luminance:", values)
baseline = values["closed"]
assert baseline - values["open"] > 0.12, "Opening navigation did not dim backdrop"
assert baseline - values["reopened"] > 0.12, "Reopening navigation failed"
assert values["escape-closed"] - values["open"] > 0.12, "Escape did not close drawer"
assert values["backdrop-closed"] - values["reopened"] > 0.12, "Backdrop click did not close drawer"
print("PASS: 360px narrow drawer, Escape and backdrop close")
PY
