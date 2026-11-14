#!/usr/bin/env bash
# Head-specific, emulator-only measurements. Never reports synthetic fixtures as device data.
set -euo pipefail
OUT="${1:-quant-out}"
mkdir -p "$OUT"
PKG="cc.axymorrsen.ntfyunified"
: > "$OUT/results.tsv"
record() { printf '%s\t%s\n' "$1" "$2" | tee -a "$OUT/results.tsv"; }
fail() { record "FAIL" "$*"; exit 1; }
# Preserve emulator diagnostics on every failure, including bounded recovery exhaustion.
capture_diagnostics() {
  local rc="$?"
  if [ "$rc" -ne 0 ]; then
    adb shell dumpsys window windows > "$OUT/window-failure.txt" 2>&1 || true
    adb shell dumpsys activity activities > "$OUT/activity-failure.txt" 2>&1 || true
    adb logcat -d -v threadtime -t 2500 > "$OUT/logcat-failure-long.txt" 2>&1 || true
  fi
}
trap capture_diagnostics EXIT

# Window focus and resumed activity are both checked. A system ANR dialog may
# cover the app even while Android still reports the app as resumed.
capture_focus() {
  local density="$1" iteration="$2" windows activity focus resumed
  windows="$(adb shell dumpsys window windows 2>&1 || true)"
  activity="$(adb shell dumpsys activity activities 2>&1 || true)"
  focus="$(printf '%s\\n' "$windows" | grep -m1 -E 'mCurrentFocus=' || true)"
  resumed="$(printf '%s\\n' "$activity" | grep -m1 -E 'topResumedActivity=|mResumedActivity=' || true)"
  printf 'density=%s probe=%s focus=%s resumed=%s\\n' "$density" "$iteration" "$focus" "$resumed" | tee -a "$OUT/focus-${density}.txt"
  [[ "$focus" == *"$PKG"* && "$resumed" == *"$PKG"* ]]
}

# Recover only from a foreground interruption; never treat it as an app result.
# The Wait button is preferred over Close app to avoid killing the launcher.
recover_foreground() {
  local density="$1" recovery="$2" dialog="$OUT/recovery-dialog-${density}.xml"
  adb shell uiautomator dump /sdcard/ntfy-recovery.xml > "$OUT/recovery-dump-${density}.txt" 2>&1 || true
  adb exec-out cat /sdcard/ntfy-recovery.xml > "$dialog" 2>/dev/null || true
  local tap
  tap="$(python3 - "$dialog" <<'PY_WAIT'
import re, sys, xml.etree.ElementTree as ET
try:
    for node in ET.parse(sys.argv[1]).iter("node"):
        if "Wait" in (node.get("text",""), node.get("content-desc","")):
            m = re.fullmatch(r"\\[(\\d+),(\\d+)\\]\\[(\\d+),(\\d+)\\]", node.get("bounds",""))
            if m:
                a,b,c,d=map(int,m.groups())
                print((a+c)//2, (b+d)//2)
                break
except (ET.ParseError, OSError):
    pass
PY_WAIT
)"
  if [[ -n "$tap" ]]; then
    read -r x y <<< "$tap"
    printf 'density=%s recovery=%s selecting Wait at %s,%s\\n' "$density" "$recovery" "$x" "$y" | tee -a "$OUT/focus-${density}.txt"
    adb shell input tap "$x" "$y" || true
  else
    printf 'density=%s recovery=%s no Wait action found; bringing app forward\\n' "$density" "$recovery" | tee -a "$OUT/focus-${density}.txt"
  fi
  adb shell am start -W -n "$PKG/.MainActivity" >> "$OUT/foreground-recovery-${density}.txt" 2>&1 || true
  sleep 3
}
adb wait-for-device
adb shell settings put system screen_off_timeout 600000
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
record source_sha "${GITHUB_SHA:-unknown}"
record device_type "GitHub Actions KVM Android emulator (NOT OnePlus 13)"
record network_e2e "NOT TESTED: no approved credentials or local mock server; publish-to-hierarchy and publish-to-native-notification latencies unavailable"
record permission_e2e "NOT TESTED: OS permission grant/deny flow not automated"
record signing "debug APK automatically signed by Android Gradle for emulator installation only; no signature material or APK uploaded"
start_app() {
  adb shell am force-stop "$PKG" || true
  adb logcat -c
  adb shell am start -W -n "$PKG/.MainActivity" | tr -d '\r'
}
for density in 320 480; do
  adb shell wm density "$density"
  adb shell am force-stop "$PKG" || true
  sleep 2
  for attempt in 1 2 3; do
    start_app > "$OUT/start-${density}-${attempt}.txt"
    grep -E 'TotalTime: [0-9]+' "$OUT/start-${density}-${attempt}.txt" >/dev/null || fail "no am start -W TotalTime for density $density attempt $attempt"
    sleep 2
  done
  adb shell dumpsys meminfo "$PKG" > "$OUT/pss-${density}.txt"
  adb logcat -d -v brief -s NtfyInsets:I Tauri/Console:I chromium:I > "$OUT/logcat-${density}.txt"
  # WebView readiness only counts while our app owns the foreground window.
  # System/Launcher ANR overlays are recovered separately, at most three times.
  ready=0
  ui_attempt=0
  recovery_attempt=0
  while [ "$ui_attempt" -lt 20 ]; do
    if ! capture_focus "$density" "check-${ui_attempt}-recovery-${recovery_attempt}"; then
      if [ "$recovery_attempt" -ge 3 ]; then
        fail "foreground recovery exhausted at density $density; see focus/window/logcat evidence"
      fi
      recovery_attempt=$((recovery_attempt + 1))
      recover_foreground "$density" "$recovery_attempt"
      continue
    fi
    ui_attempt=$((ui_attempt + 1))
    if adb shell uiautomator dump /sdcard/ntfy-quant.xml > "$OUT/uiautomator-${density}.txt" 2>&1 &&
       adb exec-out cat /sdcard/ntfy-quant.xml > "$OUT/hierarchy-${density}.xml" &&
       python3 - "$OUT/hierarchy-${density}.xml" <<'PY_READY'
import sys
import xml.etree.ElementTree as ET
try:
    nodes = ET.parse(sys.argv[1]).iter("node")
    labels = {
        n.get(attr, "")
        for n in nodes
        for attr in ("text", "content-desc")
    }
    sys.exit(0 if {"Open navigation", "Connect"} <= labels else 1)
except (ET.ParseError, OSError):
    sys.exit(1)
PY_READY
    then
      ready=1
      printf 'density=%s accessibility ready on attempt %s/20\n' "$density" "$ui_attempt" | tee "$OUT/accessibility-${density}.txt"
      break
    fi
    printf 'density=%s accessibility not ready (attempt %s/20)\n' "$density" "$ui_attempt" >> "$OUT/accessibility-${density}.txt"
    sleep 3
  done
  test "$ready" -eq 1 || fail "WebView accessibility tree not ready at density $density after 20 foreground-verified attempts (~60s polling)"
  capture_focus "$density" "capture-final" || fail "foreground interrupted before screenshot at density $density"
  adb exec-out screencap -p > "$OUT/screen-${density}.png"
  test -s "$OUT/hierarchy-${density}.xml" || fail "hierarchy empty at $density"
done
adb shell wm density reset
python3 - "$OUT" <<'PY'
import json, pathlib, re, statistics, sys, xml.etree.ElementTree as ET
from PIL import Image
out = pathlib.Path(sys.argv[1])
results = {}
errors = []
def expect(cond, description):
    if not cond: errors.append(description)
def metric(density):
    d = {}
    starts = []
    for i in (1,2,3):
        raw = (out / f"start-{density}-{i}.txt").read_text()
        match = re.search(r"TotalTime:\s*(\d+)", raw)
        expect(bool(match), f"{density}: missing startup TotalTime #{i}")
        if match: starts.append(int(match.group(1)))
    d["cold_start_total_time_ms"] = starts
    if starts: d["start_total_time_median_ms"] = statistics.median(starts)
    raw = (out / f"logcat-{density}.txt").read_text(errors="replace")
    native = re.findall(r"bars_top_px=(\d+).*?density=([\d.]+).*?native_padding_top_px=(\d+)", raw)
    expect(bool(native), f"{density}: native inset metrics missing")
    if native:
        top, actual_density, padding = map(float, native[-1])
        d.update(status_bar_height_px=top, native_density=actual_density, native_padding_top_px=padding)
        expect(abs(top-padding)<0.1, f"{density}: native inset padding mismatch")
    d["pss_kb"] = None
    mem = (out / f"pss-{density}.txt").read_text(errors="replace")
    pss = re.search(r"TOTAL PSS:\s*(\d+)", mem) or re.search(r"^\s*TOTAL\s+(\d+)", mem, re.M)
    if pss: d["pss_kb"] = int(pss.group(1))
    expect(d["pss_kb"] is not None, f"{density}: PSS missing")
    tree = ET.parse(out / f"hierarchy-{density}.xml")
    nodes = list(tree.iter("node"))
    def bounds(node):
        m = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", node.get("bounds",""))
        return [int(x) for x in m.groups()] if m else None
    def has_label(node, value):
        return any(node.get(attr, "") == value for attr in ("text", "content-desc"))
    menu = next((n for n in nodes if has_label(n, "Open navigation")), None)
    connect = next((n for n in nodes if has_label(n, "Connect")), None)
    expect(menu is not None, f"{density}: accessible Open navigation button absent")
    expect(connect is not None, f"{density}: accessible Connect button absent")
    if menu is not None and bounds(menu) is not None:
        x1,y1,x2,y2 = bounds(menu)
        d["header_button_top_px"] = y1
        d["header_button_height_px"] = y2-y1
        if native:
            d["header_gap_dp"] = (y1-top)/actual_density
            expect(abs(d["header_gap_dp"]-20)<=2, f"{density}: top gap {d['header_gap_dp']:.2f}dp, expected 20±2")
    if connect is not None and bounds(connect) is not None:
        x1,y1,x2,y2 = bounds(connect)
        d["connect_button_height_px"] = y2-y1
    for k in ("header_button_height_px","connect_button_height_px"):
        expect(k in d, f"{density}: {k} not measurable")
    img=Image.open(out/f"screen-{density}.png").convert("RGB")
    d["screen_px"]=list(img.size)
    sample_height = int(d.get("status_bar_height_px",0))
    expect(sample_height>0 and sample_height<img.height, f"{density}: status bar height invalid")
    if 0<sample_height<img.height:
        x=min(20,img.width-1)
        samples=[img.getpixel((x,y)) for y in range(sample_height)]
        white=[i for i,rgb in enumerate(samples) if min(rgb)>=245]
        d["status_bar_sample_x_px"]=x
        d["status_bar_sample_rgb_top"]=list(samples[0])
        d["near_white_status_rows_px"]=len(white)
        d["near_white_status_row_indices"]=white[:20]
        expect(not white, f"{density}: near-white status bar rows {len(white)}")
    return d
for density in (320,480):
    results[str(density)]=metric(density)
for name in ("header_button_height_px","connect_button_height_px"):
    a,b=results["320"],results["480"]
    if name in a and name in b and a.get("native_density") and b.get("native_density"):
        diff=abs(a[name]/a["native_density"]-b[name]/b["native_density"])
        results[name+"_delta_dp"]=round(diff,4)
        expect(diff<=1, f"{name}: difference {diff:.3f}dp > 1dp")
results["network_e2e"] = "NOT TESTED; no approved credentials, local mock or publish automation"
results["physical_device"] = "NOT TESTED; emulator is not OnePlus 13"
results["failures"]=errors
(out/"measurements.json").write_text(json.dumps(results,indent=2,ensure_ascii=False)+"\n")
print(json.dumps(results,indent=2))
if errors: sys.exit("QUANT FAIL: "+"; ".join(errors))
PY
record status "PASS: emulator UI/density/launch quant assertions; transport E2E NOT TESTED"
