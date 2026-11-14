#!/usr/bin/env python3
"""Only evaluate real native and webview measurements, never synthesize device data."""
import json
import re
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit("Usage: verify-ui-measurements.py <numeric-adb-log>")
raw = Path(sys.argv[1]).read_text()
native = re.findall(
    r"bars_top_px=(\d+).*?bars_bottom_px=(\d+).*?density=([0-9.]+)"
    r".*?bars_top_dp=([0-9.]+).*?native_padding_top_px=(\d+)", raw
)
web = re.findall(r"\[ntfy-ui-insets\]\s*(\{[^\n]+\})", raw)
if not native or not web:
    raise SystemExit("NOT MEASURED: native/JS numeric metrics absent")
top, bottom, density, native_dp, native_padding = map(float, native[-1])
browser = json.loads(web[-1])
def number(key):
    return float(browser[key])
applied = number("applied_css_safe_top_px")
env = number("css_env_top_px")
gap = number("header_button_top_css_px")
design = number("design_padding_top_css_px")
if abs(native_padding - top) > 0.1:
    raise SystemExit("FAIL native top padding differs from system bar top")
if abs(applied) > 0.1:
    raise SystemExit("FAIL CSS applied nonzero second safe-area layer")
if abs(native_dp - top / density) > 0.2:
    raise SystemExit("FAIL native density conversion inconsistent")
if not 18 <= gap <= 22:
    raise SystemExit("FAIL first header control is not 20dp ±2dp from safe viewport top")
if abs(design - 20) > 0.1:
    raise SystemExit("FAIL design top padding is not 20 CSS dp")
print(json.dumps({
    "status": "PASS numeric checks; physical screenshots still require visual inspection",
    "native_bars_top_px": top,
    "native_bars_bottom_px": bottom,
    "native_density": density,
    "native_top_dp": top / density,
    "native_padding_top_px": native_padding,
    "webview_computed_safe_top_css_px": env,
    "webview_applied_safe_top_css_px": applied,
    "header_top_gap_css_dp": gap,
    "design_padding_css_dp": design,
    "webview_device_pixel_ratio": number("dpr"),
    "viewport_width_css_px": number("viewport_width_css_px"),
}, indent=2))
