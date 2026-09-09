# PROGRESS

Milestone ledger. One line per completed, superseded or removed feature or bug.
Newest first.

- 2026-09-09T05:14Z — `pipeline.prefixedTextPart` replaces `firstTextPart`: the strip edits the
  text part that actually carries the intent prefix, not the first one. `userText` joins every
  text part and `detectIntent` strips leading whitespace off the join, so an empty leading part
  left the marker in the second and sent it to the model. Four assertions, one proven to fail
  with the fix reverted.
- 2026-09-09T05:14Z — `AGENTS.md` documentation standard resolved to one scope and one format:
  new and touched code only, never retroactive, and the three prefixes required rather than
  optional. The two paragraphs previously contradicted each other on both axes.
- 2026-09-09T05:14Z — `AGENTS.md` Command Laws now require UTC timestamps carrying an explicit
  `Z`. The host is +1000, so every local stamp already written was ten hours ambiguous; the
  existing `.devdocs/` entries are converted.
- 2026-09-09T04:49Z — Report hygiene: V-15 closed in report 07, Phase 5.1 closed in report 05,
  the maths phase restated in reports 02 and 05 as unlinked rather than unpainted, report 04 §4.3
  retired with the OS guards it describes, and the census, widget-count, module-size and
  self-test-count figures re-derived across reports 02, 03, 04, 06 and 07.
- 2026-09-09T04:49Z — `AGENTS.md` restored to the repository root, byte-identical to the version
  deleted in `c5111ce3`.
- 2026-09-09T04:49Z — New `routes-selftest`: nineteen assertions over `routes.classify` and
  `pathFromHead`, registered in `jenova_core.nimble` and `usage()`. Closes the coverage gap that
  let `/v1/embeddings` reach the wrong backend — the property is decidable with no socket, and
  nothing decidable that way was checking it. Proven to fail with the fix reverted.
- 2026-09-09T04:33Z — `mathfont.chooseFont` walks each font root once and probes the
  collected basenames in preference order, replacing thirty recursive walks of the
  system font tree with one per root.
- 2026-09-09T04:33Z — `db.queryBlob` raises on a step error instead of breaking, so a
  failing database can no longer return a truncated vector scan as a complete one.
- 2026-09-09T04:33Z — `routes.classify` tests the embed prefixes before `/v1/`, so
  `/v1/embeddings` reaches the embedding backend rather than the chat backend.
- 2026-09-09T04:33Z — `workspace.contextFor` reads bodies one at a time for the rows the
  scoping kept, and bounds the assembled block at `MaxContextBytes`, naming what it
  omitted. Gated by six assertions in `workspace-selftest`.
- 2026-09-09T04:33Z — `pipeline.prepare` reads a turn's text through `userText`, so a turn
  carrying an attachment is enriched like any other; the prefix strip edits the first
  text part rather than replacing the content array. Gated by six assertions in
  `pipeline-selftest`, four proven to fail with the fix reverted.
- 2026-09-09T04:24Z — `.devdocs/` trackers created per the Workspace Architecture:
  `TODOS.md`, `PLANS.md`, `DECISIONS_LOG.md`, `PROGRESS.md`, `BRIEFING.md`,
  `SESSION_HANDOFF.md`, `SUMMARIES.md`.
