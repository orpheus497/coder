# DECISIONS LOG

Architectural and structural decisions, and ambiguities resolved. Newest first.

---

## 2026-09-09T04:24Z — the FreeBSD "blocked" framing is retired

Report 05 Phase 1 and report 01 A-2 both record their remaining work as blocked on a
FreeBSD host with the GUI built. That was true of the container the audits ran in; it is
not true of this workspace, which is the target host reached through the Linuxulator.
Both binaries build natively here and the twenty-one self-tests pass.

The `sysctl` probe, the `fork`/`setsid`/`execv` path, the D-Bus tray, the Neovim page,
GTK 4.20.4 and the GUI screenshots are therefore outstanding work rather than blocked
work, and are recorded in `TODOS.md` as such.

## 2026-09-09T04:24Z — the `.devdocs/` trackers are created rather than assumed absent

`AGENTS.md` mandates eleven trackers under `.devdocs/`; none existed, and `AGENTS.md`
itself is absent from the tree (deleted in `c5111ce3`). Report 03 records that the
earlier tracker corpus was deleted deliberately, because the labelling apparatus it
produced had spread into 689 dangling references across `src/`.

Resolved: the trackers are recreated because the governance file requires them, and are
written without cross-reference labels — the defect was the labels and their reach into
source comments, not the existence of a task ledger. `AGENTS.md` is read from git history
until it is restored to the tree.

## 2026-09-09T04:24Z — six audit defects split into five executed and two held

Nine defects were found by reading `src/` against the audit reports. Five are unambiguous
repairs of code that does not do what its own module says it does, and are executed:
D1, D2/D3, D4, D7, D8.

Two are held for a ruling because they change a contract rather than repair a defect:

- **D5, retrieval scoping.** `pipeline.prepare` accepts a `projectRoot` and no caller
  passes one, so every retrieval searches every workspace. Closing it requires the server
  to learn which conversation a completion belongs to, and the body carries no
  conversation id — so it needs a new header or body field, which the frozen Web UI also
  sees. Recommended: an `X-Jenova-Scope` request header, absent meaning today's global
  behaviour.
- **D6, the partial-node merge.** `api.putEntity` merges a partial node onto the stored
  row; the `POST /api/db/*` route calls `upsert` directly and blanks every column the
  caller omitted. `api.nim`'s own header states the blanking is intended — the client
  "posts partial objects and means them" — while `gui.nim` documents the same behaviour
  as the defect that wrote a zero-byte file over a real one. The two cannot both stand.
  Recommended: move the merge into `upsert`, since a blanked `content` column destroys
  stored bytes.

## 2026-09-09T04:24Z — the workspace context is bounded at its source, not at the trimmer

`workspace.contextFor` has no token budget and its output enters the system message,
which `pipeline.trimHistory` deliberately never drops. Teaching the trimmer to drop or
truncate system content was rejected: that message carries the persona and every injected
block, so shortening it changes who is answering and what was retrieved. The budget goes
on the block being built instead, where the omission can be counted and reported.
