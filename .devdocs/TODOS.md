# TODOS

## Active

*(No active tasks currently scoped in PLANS.md)*

## Backlog

### Ruled Policies

- **V-17 — documentation citation policy.** Ruled: zero citations, labels, or document cross-references
  in code comments. Citations live strictly in `.devdocs/` as reference material.

### Defects
- **The two races report 03 deferred remain open.** `rag.query` now filters deleted rows,
  which was named as their shared root, so a stale hit is no longer *returned*. The races
  themselves — `forgetMessage` against restore-and-update indexing, and descendant discovery
  against fork creation — still need the per-message lock or deletion generation that report
  03 describes, and that is a concurrency design for the retrieval layer rather than a patch.
- **`serve-selftest` and the six shell suites have not been run** since the
  changes of 2026-09-09. They bind listeners and the session was instructed not to run the
  server. `relay-selftest` does not bind a socket (it tests pure string header splicing in memory)
  and can run socket-free. Nothing depends on the listener suites for the fixes made —
  `routes-selftest` covers the routing change without a socket — but the suite is not fully
  green until they are run.

### Reachable now that the target host is the working host

- FreeBSD `sysctl` hardware probe, exercised.
- `fork`/`setsid`/`execv` backend path against FreeBSD process semantics.
- D-Bus tray against a real `StatusNotifierWatcher`.
- Embedded Neovim page.
- GTK 4.20.4 and libadwaita 1.8.5.1, against the 4.14/1.5 the audit host had.
- `png/gui-*.png` screenshots, which gate reordering the README to lead with the window.

### Carried from the audit reports

- Phase 2.2 — reduce the three render memos to viewport scale.
- Phase 4.3 — the command palette.
- Phase 5.4 — attachment "view all", favourite models, selective export; plus the model
  information detail that is the remainder of 5.1.
- P-A3 audio capture; P-A7 PDF rasteriser.
- P-B1 — an error surface carrying the server's own detail.
- M-3 and M-4 — larger than reported: `mathtex` and `mathfont` are not imported by
  `gui.nim` and `markdown.BlockKind` has no `bkMath`.
- Phase 8 batches 3-8, against a comment share that has risen to 32.4%.

### Report hygiene

*(The corrections listed here were made on 2026-09-09 — see `PROGRESS.md`. What remains is
the class, not the instances.)*

- Report 08 §5's landing sites for M-3 are accurate and none has been taken; leave the plan
  and take the work rather than restating it.
