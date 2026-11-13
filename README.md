# ntfy-unified

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
Pinned upstream commit: b1035e69fd1b4d67df4490994c2cf289790cce64
License: MIT; preserve the original LICENSE and attribution.
See docs/UPSTREAM.md for provenance and docs/ALPHA.md for acceptance criteria.
