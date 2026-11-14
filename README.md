# ntfy-unified

Lightweight desktop-first ntfy client. The original Rust/Tauri transport,
SQLCipher persistence, native notifications and React/Next.js UI originate from
the MIT-licensed [Rubix Studios ntfy-app](https://github.com/rubix-studios-pty-ltd/ntfy-app).

## Release stages

- **0.0.1 G1 passed:** Linux desktop self-hosted ntfy E2E independently verified
  by the external supervisor. CI built Windows and Linux installers.
- **0.0.2 G2 accepted:** responsive React inbox/sidebar, graphite-blue
  design tokens, accessible controls, reduced-motion styling and light animation.
  External supervisor verified auth, notifications and persistence.
- **0.0.3 G3 in progress:** Android foreground Rust core reuse, encrypted Keystore and native notification integration; signed installation and device E2E not yet verified.
- 0.0.4: reconnect/recovery/performance improvements.
- 0.1.0: six-platform build matrix, with build and device verification statuses
  recorded separately for each platform.

This is a desktop-first alpha. Passing CI does not imply physical-device validation
on other platforms. See [Issue #2](https://github.com/Zhanfg/ntfy-unified/issues/2)
and [PR #1](https://github.com/Zhanfg/ntfy-unified/pull/1).

## Build

Requires Node 24, pnpm, Rust stable and OS-specific Tauri dependencies.

```sh
corepack enable
pnpm install --frozen-lockfile
pnpm run typecheck
pnpm run build:ui
pnpm exec tauri build
```

## Security and licensing

- The app requires HTTPS and OS credential services. The SQLCipher database has
  no plaintext fallback; user secrets are never part of this repository.
- Inherited automations can execute commands, so use trusted access-controlled topics.
- The upstream updater and its endpoints are removed from this fork.
- **No Telegram/GPL code is copied.** UI changes use existing permissively
  licensed dependencies without adding a new animation engine.
- The Rubix Studios MIT license and copyright must be retained.

Source commit: `b1035e69fd1b4d67df4490994c2cf289790cce64`.
See `docs/UPSTREAM.md` and `docs/ALPHA.md`.

G3 technical and signing boundaries: [docs/G3-ANDROID-ARCHITECTURE.md](docs/G3-ANDROID-ARCHITECTURE.md). No unsigned package is advertised as installable.
