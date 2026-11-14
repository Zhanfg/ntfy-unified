#!/usr/bin/env python3
"""Non-weakened G3 CI assertions for safe-area, device viewport and native Activity."""
from html.parser import HTMLParser
from pathlib import Path
import sys

def require(ok, reason):
    if not ok:
        raise AssertionError(reason)

layout = Path("app/layout.tsx").read_text()
css = Path("styles/globals.css").read_text()
client = Path("components/ntfy/client.tsx").read_text()
native = Path("android/overrides/MainActivity.kt.in").read_text()
patch = Path("scripts/android/apply-insets.sh").read_text()
require("export const viewport: Viewport" in layout, "missing Next viewport export")
for token in ("width: 'device-width'", "initialScale: 1", "viewportFit: 'cover'"):
    require(token in layout, "viewport missing " + token)
require("maximumScale" not in layout and "userScalable: false" not in layout,
        "accessibility zoom was locked")
for side in ("top", "bottom", "left", "right"):
    require("env(safe-area-inset-" + side in css, "missing CSS safe area: " + side)
for token in ("padding-block-start", "padding-block-end",
              "padding-inline-start", "padding-inline-end", "min-height: 2.5rem"):
    require(token in css, "missing responsive CSS behavior " + token)
require("min-h-dvh" in client and "matchMedia('(min-width: 768px)')" in client,
        "responsive layout/viewport breakpoint modified")
for token in ("WindowCompat.setDecorFitsSystemWindows(window, false)",
              "WindowInsetsCompat.Type.systemBars()",
              "WindowInsetsCompat.Type.displayCutout()",
              "ViewCompat.setOnApplyWindowInsetsListener(content)",
              "view.setPadding(bars.left, bars.top, bars.right, bars.bottom)",
              "ViewCompat.requestApplyInsets(content)",
              "override fun onConfigurationChanged(newConfig: Configuration)"):
    require(token in native, "missing native dynamic insets " + token)
require("src-tauri/gen/android/app/src/main/java" in patch,
        "missing reproducible generated Android Activity patch")
require("setTextZoom" not in native and "setInitialScale" not in native,
        "native Activity overrides density/zoom with a fixed value")
print("PASS: native system inset source, CSS safe areas, dynamic device viewport/density")

# msg-011: additional assertions, preserving every pre-existing check above.
# Android's content-root padding is the SINGLE effective safe-area layer.
for value in ("padding-block-start: 0", "padding-block-end: 0",
              "padding-inline-start: 0", "padding-inline-end: 0"):
    require(value in css, "Android must not double-apply CSS safe inset: " + value)
for value in ("padding-block-start: env(", "padding-block-end: env(",
              "padding-inline-start: env(", "padding-inline-end: env("):
    require(value not in css, "double-counted browser safe inset: " + value)
for value in ('DARK_SURFACE = "#0c1420"', 'LIGHT_SURFACE = "#f2f5fb"',
              "window.setBackgroundDrawable(ColorDrawable(surface))",
              "window.decorView.setBackgroundColor(surface)",
              "window.statusBarColor = Color.TRANSPARENT",
              "window.navigationBarColor = Color.TRANSPARENT",
              "isAppearanceLightStatusBars = !dark",
              "isAppearanceLightNavigationBars = !dark"):
    require(value in native, "Android system bar theme/color missing: " + value)
for value in ("bars_top_px=", "native_padding_top_px=", "bars_top_dp=",
              "ViewCompat.setOnApplyWindowInsetsListener(content)",
              "view.setPadding(bars.left, bars.top, bars.right, bars.bottom)"):
    require(value in native, "missing actual Kotlin native inset measurement: " + value)
bridge = Path("components/ntfy/android-system-bars.tsx").read_text()
for value in ("useTheme", "resolvedTheme", "android_set_appearance",
              "getComputedStyle(safeProbe)", "getComputedStyle(root)",
              "css_env_top_px", "applied_css_safe_top_px",
              "header_button_top_css_px", "design_padding_top_css_px",
              "window.devicePixelRatio", "window.innerWidth"):
    require(value in bridge, "missing JS theme/safe-area/DPI instrumentation: " + value)
require("<AndroidSystemBars />" in layout, "native appearance sync is not mounted")
mobile_command = Path("src-tauri/src/commands/mod.rs").read_text().split(
    "#[cfg(mobile)]\\npub fn handler()", 1)[-1]
require("appearance::android_set_appearance" in mobile_command,
        "Android appearance IPC not registered")
require('Builder::<Wry>::new("appearance")' in
        Path("src-tauri/src/appearance.rs").read_text(),
        "Android appearance native plugin not registered")
plugin = Path("android/overrides/AppearancePlugin.kt.in").read_text()
for value in ("@TauriPlugin", "@Command", "setAppearance(invoke: Invoke)",
              "setNtfyAppearance(args.dark)"):
    require(value in plugin, "Android color theme bridge missing: " + value)
print("PASS: native themed system bars, single native inset authority and Kotlin/JS measurements")

if "--generated" in sys.argv:
    found = sorted(Path("src-tauri/gen/android/app/src/main/java").rglob("MainActivity.kt"))
    require(len(found) == 1, "generated Activity is absent or ambiguous")
    actual = found[0].read_text()
    for token in ("class MainActivity : TauriActivity()",
                  "WindowCompat.setDecorFitsSystemWindows(window, false)",
                  "WindowInsetsCompat.Type.systemBars()",
                  "ViewCompat.requestApplyInsets(content)",
                  "view.setPadding(bars.left, bars.top, bars.right, bars.bottom)"):
        require(token in actual, "generated Kotlin does not contain " + token)
    print("PASS: real generated Tauri MainActivity includes dynamic native insets")
    plugins = sorted(Path("src-tauri/gen/android/app/src/main/java").rglob("AppearancePlugin.kt"))
    require(len(plugins) == 1, "native appearance plugin not generated")
    compiled_plugin = plugins[0].read_text()
    require("setAppearance(invoke: Invoke)" in compiled_plugin,
            "generated Android plugin lacks theme change command")
    require("setNtfyAppearance(args.dark)" in compiled_plugin,
            "generated plugin does not apply theme to Activity")
    require('DARK_SURFACE = "#0c1420"' in actual and
            "isAppearanceLightStatusBars = !dark" in actual,
            "generated Activity lacks correct status bar color/contrast")
    print("PASS: actual generated Kotlin theme bridge and contrast implementation")

if "--exported" in sys.argv:
    class ViewportMeta(HTMLParser):
        def __init__(self):
            super().__init__()
            self.values = []
        def handle_starttag(self, tag, attrs):
            if tag == "meta":
                meta = dict(attrs)
                if meta.get("name") == "viewport":
                    self.values.append(meta.get("content", ""))
    path = Path("out/index.html")
    require(path.exists(), "Next did not export out/index.html")
    parser = ViewportMeta()
    parser.feed(path.read_text())
    require(len(parser.values) == 1, "expected a single exported viewport meta")
    value = parser.values[0].lower().replace(" ", "")
    for token in ("width=device-width", "initial-scale=1", "viewport-fit=cover"):
        require(token in value, "exported viewport missing " + token + ": " + value)
    require("user-scalable=no" not in value, "zoom disabled in exported viewport")
    print("PASS: built HTML has real device viewport and viewport-fit=cover")
