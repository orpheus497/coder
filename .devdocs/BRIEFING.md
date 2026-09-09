# BRIEFING

**Current as of 2026-09-09T22:23Z.** Overwritten each session.

All eleven trackers the Workspace Architecture mandates exist and are synchronized.

`AGENTS.md` is present at the repository root and tracked in git (`5606d418`).

## Where the project is

Both binaries (`bin/jenova-core` and `bin/jenova`) build natively in this workspace.

**Twenty-one of the twenty-two self-tests are socket-free and pass natively.**
Only `serve-selftest` binds a listener (port 18642) to drive load against a fake upstream;
an earlier claim that `relay-selftest` also binds a listener was false — its source in
`src/jenova_core.nim` (lines 6125–6209) tests `upstream.spliceHeaders` purely in memory on a
fixed string buffer. Neither `serve-selftest` nor the shell suites were run under the
standing instruction not to bind listeners.

**This workspace is a Linux container hosted on a FreeBSD system.**
Kernel-level inspections, `sysctl` probes, and hardware detection paths must account for
container isolation. The `sysctl` probe, the `fork`/`setsid`/`execv` backend path, the
D-Bus tray, the Neovim page, and the GUI screenshots remain outstanding functional work.

## What this session did

1. Performed deep codebase analysis cross-referencing actual Nim code logic (not code comments)
   against `.devdocs/` claims.
   - Verified that attachment turns in `pipeline.nim` handle `JArray` text and prefix stripping correctly.
   - Verified that `workspace.nim` bounds context at 64KB and reads bodies individually after scoping.
   - Verified that `routes.nim` prioritizes `/v1/embeddings` before `/v1/`.
   - Verified that `db.queryBlob` raises on non-DONE/ROW step codes.
   - Verified that `mathfont.chooseFont` walks font roots once.
2. Corrected false tracker claim regarding `relay-selftest`'s listener requirements.
3. Updated tracking status of `AGENTS.md` (confirmed committed in `5606d418`).
4. Realigned `PLANS.md` with `TODOS.md` by clearing executed items that already live in `PROGRESS.md`.
5. Confirmed exact state of outstanding features:
   - Maths rendering M-3: `mathtex` and `mathfont` are pure and self-tested, but `markdown.BlockKind`
     has no `bkMath` and `gui.nim` has no import or Cairo render branch for display math.
   - Render memos (Phase 2.2): `BlockMemo` (cap 512), `ParseMemo` (cap 128), and `thumbCache` (cap 128)
     are conversation-scaled rather than viewport-scaled.
   - Chunked requests (D9): `http.nim` parses `Content-Length` only and drops chunked bodies.

## Blockers

None. Rulings established on D5 (retrieval scoping hierarchy), D6 (partial-node merge in `upsert`),
and V-17 (citation policy).

- **D5 ruled:** Strict container-tree scoping (Non-workspace chats/unfiled isolated → Workspace →
  Project → Folder). Wire via `X-Jenova-Scope`.
- **D6 ruled:** Move row merge into `api.upsert` to protect omitted fields from blanking.
- **V-17 ruled:** Zero citations or tracking labels in code comments; reference material lives in `.devdocs/` only.

## Next 3-5 steps

1. Scope D6 into `PLANS.md`, move to `TODOS.md` Active, and execute merge in `api.upsert`.
2. Scope D5 into `PLANS.md`, move to `TODOS.md` Active, and implement container-hierarchy RAG filtering and `X-Jenova-Scope` header.
3. Factor a pure, socket-free chunked body decoder into `http.nim` (D9) to prevent silent drops.
4. Progress M-3: add `bkMath` to `markdown.BlockKind`, parse display math blocks, and wire Cairo rendering into `gui.nim`.
