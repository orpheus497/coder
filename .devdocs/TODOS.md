# TODOS

## Active

*(empty — see `PROGRESS.md` for what was completed this session)*

## Backlog

### Awaiting a ruling

- **D5 — retrieval is never scoped.** `prepare` takes a `projectRoot` and the server
  never passes one, so every query searches every workspace. Needs a wire decision:
  how does the server learn the conversation?
- **D6 — the partial-node merge protects the window only.** `putEntity` merges onto the
  stored row; the `POST /api/db/*` route calls `upsert` directly and blanks omitted
  columns. Conflicts with `api.nim`'s stated intent.
- **V-17 — report citations drift.** Symbol-bearing citations with a gate, or drop line
  numbers from prose.

### Defects

- **D9 — no chunked request bodies.** `http.parseRequest` reads `Content-Length` only.
- **`rag.query` does not filter deleted rows.** Root of two of report 03's three
  deferred findings.
- **`serve-selftest`, `relay-selftest` and the six shell suites have not been run** since the
  changes of 2026-09-09. They bind listeners and the session was instructed not to run the
  server. Nothing depends on them for the fixes made — `routes-selftest` covers the routing
  change without a socket — but the suite is not fully green until they are run.

### Reachable now that the target host is the working host

- FreeBSD `sysctl` hardware probe, exercised.
- `fork`/`setsid`/`execv` backend path against FreeBSD process semantics.
- D-Bus tray against a real `StatusNotifierWatcher`.
- Embedded Neovim page.
- GTK 4.20.4 and libadwaita 1.8.5.1, against the 4.14/1.5 the audit host had.
- `png/gui-*.png` screenshots, which gate reordering the README to lead with the window.

### Carried from the audit reports

- Phase 0.2 — record the comment standard where a future session reads it.
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

- **V-17 needs a ruling.** Correcting citations a fourth time will not hold. Either cite the
  symbol beside the line, with a gate that fails when the symbol moves, or drop line numbers
  from prose and keep them only where a report quotes source verbatim.
- Report 08 §5's landing sites for M-3 are accurate and none has been taken; leave the plan
  and take the work rather than restating it.
