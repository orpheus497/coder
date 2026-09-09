# SESSION HANDOFF

Newest entry at the top.

---

## 2026-09-09T22:35Z — architectural rulings confirmed: D5 retrieval scoping hierarchy, D6 partial-node merge, V-17 citation policy

### What happened

Received user rulings on the three primary architectural ambiguities: D5, D6, and V-17.
Documented the exact specifications across `.devdocs/` trackers without making source code changes.

### Rulings & Design Specifications

1. **D5 — Retrieval Scoping Hierarchy:**
   The user specified the authoritative hierarchy for RAG retrieval down the container tree:
   - **No workspace (root/global chat):** RAG searches only non-workspace chats and saved files/notes
     outside of any workspace. It does not retrieve anything from any workspace folder.
   - **Workspace Folder:** RAG scopes to this workspace and all its subfolders and projects.
   - **Workspace Project Folder:** RAG scopes to only this project and its subfolders.
   - **Project Sub-folder:** RAG scopes to only this folder and its contents.
   The client will pass the container context via the `X-Jenova-Scope` HTTP header, and
   `pipeline.prepare` will enforce this scoping ladder over the FTS/vector index.
2. **D6 — Partial-node merge in `upsert`:**
   Ruled as recommended: Merge incoming partial JSON fields onto existing stored database rows
   inside `api.upsert`. Updates via `POST /api/db/*` will preserve existing values for omitted
   columns, eliminating the risk of accidental content blanking.
3. **V-17 — Documentation citation policy:**
   Ruled as recommended: Zero citations, tracking labels, or document cross-references in code
   comments. Reference material and citations live strictly in `.devdocs/`.

### Files touched

`.devdocs/DECISIONS_LOG.md`, `.devdocs/BLUEPRINT.md`, `.devdocs/TODOS.md`,
`.devdocs/BRIEFING.md`, `.devdocs/PROGRESS.md`, `.devdocs/SESSION_HANDOFF.md`,
`.devdocs/SUMMARIES.md`.

### Decisions

Recorded in `DECISIONS_LOG.md`: D5 retrieval scoping hierarchy, D6 `upsert` merge, and V-17 code comment standards.

### Next steps

Await user instruction to begin implementation of D6 (partial-node merge in `api.upsert`),
followed by D5 (container scoping in `pipeline.prepare` and `server.nim`), and D9 (pure dechunker).

## 2026-09-09T22:23Z — devdocs audit against active code and correction of false claims

### What happened

Conducted a deep codebase analysis cross-referencing actual Nim code logic (not code comments)
against `.devdocs/` trackers and audit reports. Discovered and corrected several tracker
discrepancies, stale claims, and inaccurate assumptions about test execution and environment.
No source code outside `.devdocs/` was modified.

### Discrepancies and false claims resolved

1. **`relay-selftest` does NOT bind a listener.** `src/jenova_core.nim` (lines 6125–6209)
   demonstrates that `relay-selftest` tests `upstream.spliceHeaders` on fixed string literals in memory.
   It opens no sockets, binds no ports, and requires no server. Trackers claiming `serve` and `relay`
   both bind listeners were inaccurate; only `serve-selftest` binds a listener (port 18642).
   Twenty-one of the twenty-two self-tests are completely socket-free.
2. **`AGENTS.md` tracking status.** `BRIEFING.md` claimed `AGENTS.md` was untracked until committed.
   Git log verifies it was committed in `5606d418` on branch `nimby`, and the working tree is clean.
3. **Environment context.** Clarified that this workspace is a Linux container hosted on a FreeBSD
   system. Kernel-level inspections, `sysctl` probes, and hardware detection paths reflect this
   containerized layering.
4. **Tracker synchronization (`PLANS.md`).** `PLANS.md` previously retained full implementation
   plans for D1, D2/D3, D4, D7, and D8 after their completion. Because their completion records
   live in `PROGRESS.md`, `PLANS.md` was cleared to align with `TODOS.md` Active.

### Code verification highlights (logic verified, comments ignored)

- **Attachment turns in `pipeline.nim`:** `userText` inspects `JString` or `JArray` content,
  and `prefixedTextPart` isolates the specific text part carrying intent prefixes.
- **Workspace context in `workspace.nim`:** Reads metadata columns first, scopes them, and then
  reads individual row bodies capped at `MaxContextBytes = 64KB`.
- **Route classification in `routes.nim`:** Embed endpoints (`/embed`, `/v1/embeddings`) are tested
  prior to `/v1/` completion routes.
- **Database query handling in `db.nim`:** `queryBlob` raises `DbError` on non-DONE/ROW step codes.
- **Math font discovery in `mathfont.nim`:** `chooseFont` traverses font roots once.
- **Display math M-3 in `markdown.nim` and `gui.nim`:** Confirmed that `BlockKind` lacks `bkMath`
  and `gui.nim` does not import `mathtex` or `mathfont`, nor draw math blocks.
- **Chunked request parsing in `http.nim`:** Confirmed `http.parseRequest` reads `Content-Length`
  only, dropping chunked request bodies (D9).

### Files touched

`.devdocs/BRIEFING.md`, `.devdocs/TESTS.md`, `.devdocs/TODOS.md`, `.devdocs/PLANS.md`,
`.devdocs/DECISIONS_LOG.md`, `.devdocs/PROGRESS.md`, `.devdocs/SESSION_HANDOFF.md`,
`.devdocs/SUMMARIES.md`.

### Decisions

Recorded in `DECISIONS_LOG.md`: `relay-selftest` socket independence recognized; Linux container
on FreeBSD environment clarified; `AGENTS.md` tracking verified; `PLANS.md` cleaned of executed items.

### Verification

All devdocs edits cross-referenced directly with Nim AST and logic in `src/jenova_core.nim`,
`src/jenova/routes.nim`, `src/jenova/upstream.nim`, `src/jenova/pipeline.nim`,
`src/jenova/workspace.nim`, `src/jenova/db.nim`, and `src/jenova/markdown.nim`.

### Next steps

Awaiting user rulings on D5 (retrieval scoping), D6 (partial-node merge in `upsert`), and
V-17 (documentation citations). Upon approval: execute D6/D5/D9 and progress M-3 display math.

## 2026-09-09 — source audit against the eight reports, and five repairs

### What happened

The session opened as a cross-reference of `AGENTS.md` and `.devdocs/` against the
codebase. The first pass was done by searching for symbols rather than reading the code,
and reported the audit reports' own conclusions back with their line citations checked —
which is not the same as checking the claims. It also repeated report 05's "blocked on a
FreeBSD host" framing while running on the FreeBSD host. Both were corrected: the second
pass read the request path itself, module by module.

### Defects found by reading `src/`, none of them in any report

1. **Attachment turns bypassed the entire pipeline.** `pipeline.contentFor` emits an
   OpenAI content array for any turn with an attachment; `prepare` read that content with
   `getStr`, which answers empty for an array, and every enrichment sat behind
   `if lastUser.len > 0`. So a turn with an image, file or PDF reached the model with no
   persona, no retrieval, no web search, no editor document, and its intent prefix
   neither detected nor stripped. Both surfaces.
2. **`workspace.contextFor` read every note and file asset body on every send, on the
   GTK thread.** The same defect a review fixed in `backfillWorkspace`, never applied to
   the hot path.
3. **That output goes into the system message, which `trimHistory` never drops.** Once
   the dump alone exceeded the budget, every turn discarded the whole conversation and
   was still over budget, with `X-Jenova-Trimmed` blaming the history.
4. **`/v1/embeddings` routed to the chat backend** — `classify` tests `/v1/` first.
5. **Retrieval is never scoped** — `prepare` takes a `projectRoot` and no caller passes
   one. Held for a ruling.
6. **The partial-node merge protects the window only** — the HTTP route blanks omitted
   columns. Held for a ruling.
7. **`db.queryBlob` truncated silently** on a step error where `query` raises.
8. **`mathfont.chooseFont` walked the font roots thirty times.**
9. **No chunked request bodies.** Backlogged.

### Report claims found false

V-15 is fixed but listed open; Phase 5.1 is substantially done but listed open; the
self-test count is 21, not the 19 and 20 two reports state; the maths engine is not
imported by `gui.nim` at all and `markdown.BlockKind` has no `bkMath`, so M-3 is larger
than "the Cairo draw remains"; report 02 attributes `gui.nim`'s old line count to
`canvas.nim`; report 04's comment census has risen to 32.4% against a 9% target; report
06's widget census is 46, not 39; roughly four in five spot-checked line citations no
longer land on what they name; and the FreeBSD compile guards both reports describe have
been removed from the tree.

### Files touched

`src/jenova/pipeline.nim`, `src/jenova/workspace.nim`, `src/jenova/routes.nim`,
`src/jenova/db.nim`, `src/jenova/mathfont.nim`, `src/jenova_core.nim`.
Created `.devdocs/TODOS.md`, `PLANS.md`, `DECISIONS_LOG.md`, `PROGRESS.md`,
`BRIEFING.md`, `SESSION_HANDOFF.md`, `SUMMARIES.md`.

### Decisions

Recorded in `DECISIONS_LOG.md`: the FreeBSD blocked-framing retired; the trackers
recreated without cross-reference labels; five defects executed and two held; the
workspace context bounded at its source rather than by teaching the trimmer to shorten a
system message.

### Verification

`nimble core` and `nimble gui` both build. Nineteen self-tests pass. Twelve new
assertions were added — six in `workspace-selftest`, six in `pipeline-selftest` — and the
`pipeline` gate was **proven to fail with the fix reverted**: four of its six assertions
go red. The other two guard the write-back path rather than the read path and would fail
on the opposite mistake, which is stated rather than claimed as coverage.

`serve-selftest`, `relay-selftest` and the shell suites were **not run** — they bind
listeners and the session was instructed not to run the server or the program. The
`/v1/embeddings` fix therefore has no assertion behind it yet.

### Continued — AGENTS.md kept, coverage debt closed, reports corrected

`AGENTS.md` was restored to the repository root byte-identical to the version deleted in
`c5111ce3`, on instruction. It is untracked until committed.

**The routing fix had shipped without an assertion**, because `classify`'s only coverage
lived in two suites that bind a port. That is why `/v1/embeddings` reached the chat
backend for as long as it did: prefix order is decidable with no socket at all, and
nothing decidable that way was checking it. New `routes-selftest` — nineteen assertions
over `classify` and `pathFromHead`, registered in both `jenova_core.nimble` and `usage()`
so it is discoverable from the binary. **Proven to fail with the fix reverted.**

Report hygiene, applied rather than listed: V-15 closed in report 07 with a note that it
read `open` for two sessions after the fix; Phase 5.1 closed in report 05, with report 06
§4 credited for having had it right throughout; the maths phase restated in reports 02
and 05 — it is unlinked, not unpainted, and the remainder is the import, the fourth block
kind, the branch, *then* the draw; report 04 §4.3 retired along with the OS guards it
describes; and the census, widget-count, module-size and self-test-count figures
re-derived across reports 02, 03, 04, 06 and 07. Report 03 gained a section recording the
five new findings, pointing at `PROGRESS.md` rather than restating them, so the two
cannot drift.

### Verification, second half

`nimble core` and `nimble gui` build. **Twenty of the twenty-two self-tests pass**;
`serve` and `relay` were not run. `routes-selftest` is listed by `--help`.

### Continued — retrieval liveness, the three missing trackers, Phase 0.2

**`rag.query` now filters deleted rows.** Report 03 named this as the shared root of two
of its deferred findings. Unfiling on delete stays and is still the primary mechanism;
this is the backstop under it, and it is needed because every `forget*` call runs inside
`api.indexing`, which swallows failures on purpose — so a skipped unfile left deleted
content answering queries, with the deletion honoured everywhere except in what the model
recalls.

**The first attempt at it was wrong and the existing suite caught it.** Testing
`is_deleted=0` treats an absent row and a deleted row as the same claim, and two of
R-15's assertions — which index a note by title with no matching row — went red. An
absent row is not a deletion: this codebase soft-deletes throughout, so a missing row
means something else entirely. Only an explicit flag drops a hit now.

**The three trackers the Workspace Architecture mandates and nobody had written** —
`BLUEPRINT.md`, `ARCHITECTURE_MAPPING.md`, `TESTS.md` — are in, built from the source
traced this session rather than from the reports, and carrying no line numbers or counts
by design.

**Phase 0.2 is closed.** `AGENTS.md` now carries report 04 §3's budgets and the two
prohibitions that produced the original pollution — no cross-reference labels, no history.
The budgets are the half that keeps getting skipped, and the census shows it: coverage was
added while volume was not cut, and the total moved the wrong way.

### Verification, third part

`nimble core` and `nimble gui` build. **Twenty of the twenty-two self-tests pass.** The
retrieval gate was proven to fail with the filter disabled.

### Next steps

Rule on D5, D6 and V-17. Run the listener suites when permitted. Take the FreeBSD work now
that the host is the target — all of it needs the program run. M-3: import the two maths
modules into `gui.nim`, add `bkMath`, build the branch, then draw.
