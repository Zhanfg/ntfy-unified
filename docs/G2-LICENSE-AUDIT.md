# G2 UI dependency / license audit

Scope: commit baseline G1 0.0.1; new G2 UI patch reuses the current installed UI
dependencies and CSS. **No third-party source files are copied or newly vendored.**
Versions are controlled by package.json/pnpm-lock.yaml; the links below are for
the corresponding upstream project licenses.

| Dependency already in project | Upstream | Declared license |
| --- | --- | --- |
| Next.js | https://github.com/vercel/next.js/blob/canary/license.md | MIT |
| React / React DOM | https://github.com/facebook/react | MIT |
| Radix UI | https://github.com/radix-ui/primitives/blob/main/LICENSE | MIT |
| Tailwind CSS | https://github.com/tailwindlabs/tailwindcss/blob/main/LICENSE | MIT |
| shadcn UI | https://github.com/shadcn-ui/ui/blob/main/LICENSE.md | MIT |
| Sonner | https://github.com/emilkowalski/sonner/blob/main/LICENSE.md | MIT |
| Lucide React | https://github.com/lucide-icons/lucide/blob/main/LICENSE | ISC (permissive) |

- The imported Rubix desktop client is MIT; original \`LICENSE\` stays intact.
- New CSS is written for this project and follows the existing design decisions.
- Telegram Android / Desktop / Web GPL code is **not imported**.
- No new NPM or Rust package is added by G2. The list is a focused audit of the
  UI libraries touched here, not a full transitive dependency / SBOM audit.
- Before final release, CI should produce a full transitive license report.
