#!/usr/bin/env python3
"""Reproducible branding of the pinned MIT desktop ntfy client."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHA = "b1035e69fd1b4d67df4490994c2cf289790cce64"

def rewrite(path, fn):
    p = ROOT / path
    data = json.loads(p.read_text())
    fn(data)
    p.write_text(json.dumps(data, indent=2) + "\n")

def replace(path, old, new):
    p = ROOT / path
    s = p.read_text()
    if old not in s:
        raise RuntimeError(f"Unexpected upstream change: {path}")
    p.write_text(s.replace(old, new))

def package(p):
    p.update(name="ntfy-unified", title="ntfy-unified", version="0.0.1",
             description="Lightweight cross-platform ntfy client (desktop Alpha)",
             homepage="https://github.com/Zhanfg/ntfy-unified",
             repository={"type": "git", "url": "https://github.com/Zhanfg/ntfy-unified.git"},
             bugs={"url": "https://github.com/Zhanfg/ntfy-unified/issues"})
    p.pop("author", None)
    p.pop("maintainers", None)

def tauri(t):
    t["productName"] = "ntfy-unified"
    t["version"] = "0.0.1"
    t["identifier"] = "cc.axymorrsen.ntfyunified"
    t["app"]["windows"][0]["title"] = "ntfy-unified"
    t["bundle"]["publisher"] = "Zhanfg"
    t["bundle"]["createUpdaterArtifacts"] = False
    # Upstream release signatures/URLs cannot be trusted as fork releases.
    if "updater" in t.get("plugins", {}):
        t["plugins"]["updater"]["endpoints"] = []

rewrite("package.json", package)
rewrite("src-tauri/tauri.conf.json", tauri)
replace("src-tauri/Cargo.toml", 'name = "ntfy_app"', 'name = "ntfy_unified"')
replace("src-tauri/Cargo.lock", 'name = "ntfy_app"\\nversion = "1.1.0"', 'name = "ntfy_unified"\\nversion = "0.0.1"')
replace("src-tauri/Cargo.toml", 'version = "1.1.0"', 'version = "0.0.1"')
replace("src-tauri/Cargo.toml", 'repository = "https://github.com/rubix-studios-pty-ltd/ntfy-app"',
        'repository = "https://github.com/Zhanfg/ntfy-unified"')
replace("src-tauri/src/ntfy/http.rs", 'Rubix-Ntfy/', 'ntfy-unified/')
replace("components/ntfy/sidebar.tsx", '>ntfy</h1>', '>ntfy-unified</h1>')

# Removing next/font/google keeps build reproducible without remote font downloads.
p = ROOT / "app/layout.tsx"
s = p.read_text()
s = s.replace("import { Inter } from 'next/font/google'\n", "")
s = s.replace("import { cn } from '@/lib/utils'\n", "")
start, end = s.find("const inter = Inter({"), s.find("export const metadata:")
if start == -1 or end == -1:
    raise RuntimeError("Upstream font layout changed")
s = s[:start] + s[end:]
s = s.replace("title: 'Ntfy'", "title: 'ntfy-unified'")
s = s.replace("className={cn(inter.variable, 'bg-background-main font-sans text-foreground antialiased')}",
              'className="bg-background-main font-sans text-foreground antialiased"')
p.write_text(s)

css = ROOT / "styles/globals.css"
css.write_text(css.read_text() + """
/* ntfy-unified: low-cost system fonts and blue/graphite visual tokens. */
:root {
  --font-inter: ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  --background-main: #f3f6fc; --foreground: #1a2940;
  --primary: #396ed7; --primary-hover: #2857b2;
  --secondary: #e8effd; --secondary-foreground: #294e98;
  --accent: #e8effd; --accent-foreground: #294e98;
  --border: #dce4f1; --input: #dce4f1; --ring: #477de3;
  --brand: #396ed7;
}
.dark {
  --background: #141d2a; --background-main: #0d141e;
  --foreground: #e4edff; --card: #1a2637; --card-foreground: #e4edff;
  --popover: #1c2a3f; --popover-foreground: #e4edff;
  --primary: #87aafa; --primary-hover: #a1baff; --primary-foreground: #101c35;
  --secondary: #263b5b; --secondary-foreground: #d3e1ff;
  --border: #354762; --input: #354762; --ring: #87aafa;
  --accent: #263b5b; --accent-foreground: #d3e1ff; --brand: #87aafa;
}
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: .01ms !important; animation-iteration-count: 1 !important;
    transition-duration: .01ms !important; scroll-behavior: auto !important;
  }
}
""")

(ROOT / "README.md").write_text("""# ntfy-unified

A lightweight desktop-first ntfy client. Alpha 0.0.1 uses the existing MIT-licensed
Rubix Studios Ntfy App and preserves its Rust/Tauri ntfy transport,
SQLite persistence, notifications and React/Next.js interface.

Status: Alpha source integration. CI packages are unsigned test builds;
runtime validation and six-platform support are NOT yet claimed.

Build with Node 24, pnpm, Rust stable and Tauri OS dependencies:
    corepack enable
    pnpm install --frozen-lockfile
    pnpm run typecheck
    pnpm exec tauri build

Security: The original updater endpoint is disabled. Keep ntfy topics access-controlled.
Upstream supports local automations capable of running commands; enable them only
for trusted topics. Do not store passwords or API keys in this repository.

Source: https://github.com/rubix-studios-pty-ltd/ntfy-app
Pinned upstream commit: """ + SHA + """
License: MIT; preserve the original LICENSE and attribution.
See docs/UPSTREAM.md for provenance and docs/ALPHA.md for acceptance criteria.
""")
docs = ROOT / "docs"
docs.mkdir(exist_ok=True)
(docs / "UPSTREAM.md").write_text(
    "# Provenance\n\nOriginal MIT project: https://github.com/rubix-studios-pty-ltd/ntfy-app\n"
    "Pinned SHA: " + SHA + "\nOriginal copyright (c) 2026 Rubix Studios.\n"
    "The MIT LICENSE is preserved. Telegram source has not been copied.\n")
print("Prepared Alpha 0.0.1 from", SHA)
