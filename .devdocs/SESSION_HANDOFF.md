# SESSION HANDOFF

Newest entry at the top.

---

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

### Next steps

Rule on D5, D6 and V-17. Run the listener suites when permitted. Take the FreeBSD work now
that the host is the target — all of it needs the program run. M-3: import the two maths
modules into `gui.nim`, add `bkMath`, build the branch, then draw.
