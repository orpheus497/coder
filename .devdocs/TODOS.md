# TODOS

## Active

*(None — all active items executed and verified.)*

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
- **The mapped-window tier has never been run.** `Xvfb`, `xdotool` and `xclip` are absent
  from this host, so `gui_build.sh` runs only its build-only tier. Every other suite —
  the self-tests, the six shell suites and `gui_check.sh` — is green.

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
- Phase 8 batches 3-8, against a comment share that has risen to 32.4%.

### Report hygiene

*(The corrections listed here were made on 2026-09-09 — see `PROGRESS.md`. What remains is
the class, not the instances.)*

- Report 08 §5's landing sites for M-3 are accurate and none has been taken; leave the plan
  and take the work rather than restating it.
