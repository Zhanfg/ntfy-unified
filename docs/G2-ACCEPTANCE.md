# 0.0.2 G2 deskop UI acceptance checklist

**Scope:** React/Next.js frontend only plus window-size/version metadata.
No protocol, database, credential or native delivery change.

| Category | Required test / evidence |
| --- | --- |
| Install | Windows NSIS and Linux DEB compile and launch; package size against G1 |
| Wide layout | at 1180x760 show sidebar, topic navigation, message list, search, actions |
| Narrow layout | at 360x640 open mobile nav, select topic, close backdrop/Escape, open forms |
| Server form | verify real mouse click on **Save** with pointer, also Enter; do not assume xdotool outside-click bug |
| Message actions | mark read, delete, search, load more, link/attachment and publish are unchanged |
| Network | self-hosted ntfy subscribe/send/receive/restart/reconnect is still operational |
| Accessibility | use keyboard Tab, visible focus ring, named icon buttons, reduced-motion preference |
| Theme | light/dark/system theme, priority/unread/connection/error states remain legible |
| Security | no credentials logged, no plaintext DB fallback, GPL source absent |
| CI | frontend typecheck/build, Linux headless 15s smoke **unchanged**, Windows/ Linux unsigned installers |

**Reporting:** state 'built' and 'device-verified' separately per platform.
G2 can be merged only after external desktop UI regression E2E, then G3 Android begins.
