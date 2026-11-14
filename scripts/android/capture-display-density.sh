#!/usr/bin/env bash
# Supervisor-only, with explicit device owner authorization. No signing or login.
set -euo pipefail
ADB="$(command -v adb)"
PKG="cc.axymorrsen.ntfyunified"
DPI="$1"
OUT="$2"
[[ "$DPI" =~ ^[0-9]+$ ]] && (( DPI >= 160 && DPI <= 800 ))
mkdir -p "$OUT"
"$ADB" get-state | grep -qx device
"$ADB" shell pm path "$PKG" >/dev/null
BEFORE="$("$ADB" shell wm density | tr -d '\r')"
OVERRIDE="$(printf '%s\n' "$BEFORE" | sed -n 's/^Override density: \([0-9][0-9]*\)$/\1/p')"
CURRENT="$(printf '%s\n' "$BEFORE" | sed -n 's/^\(Physical\|Override\) density: \([0-9][0-9]*\)$/\2/p' | tail -n 1)"
test -n "$CURRENT"
test "$CURRENT" != "$DPI"
restore() {
  if [[ -n "$OVERRIDE" ]]; then
    "$ADB" shell wm density "$OVERRIDE" >/dev/null || true
  else
    "$ADB" shell wm density reset >/dev/null || true
  fi
}
trap restore EXIT
capture() {
  local label="$1"
  "$ADB" shell am force-stop "$PKG"
  "$ADB" shell log -t NtfyUiMark "START-$label" >/dev/null
  "$ADB" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null
  sleep 8
  "$ADB" exec-out screencap -p > "$OUT/$label.png"
  test -s "$OUT/$label.png"
  "$ADB" shell wm density | tr -d '\r' > "$OUT/$label-density.txt"
  "$ADB" shell wm size | tr -d '\r' > "$OUT/$label-size.txt"
  "$ADB" shell settings get system font_scale | tr -d '\r' > "$OUT/$label-font-scale.txt"
  # Strict filtering: no other logcat lines or secrets are exported.
  "$ADB" logcat -d -v brief -s NtfyUiMark:I NtfyInsets:I Tauri/Console:I '*:S' |
    awk -v marker="START-$label" '
      index($0,"NtfyUiMark") && index($0,marker) {capture=1; next}
      capture && (index($0,"NtfyInsets:") || index($0,"[ntfy-ui-insets]")) {print}
    ' > "$OUT/$label-metrics.log"
  python3 scripts/android/verify-ui-measurements.py "$OUT/$label-metrics.log" \
    > "$OUT/$label-report.json"
}
capture "normal-$CURRENT"
"$ADB" shell wm density "$DPI"
sleep 3
capture "alternate-$DPI"
restore
trap - EXIT
echo "Original wm density restored. Keep screenshots and logs private in $OUT"
