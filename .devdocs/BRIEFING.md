# BRIEFING

**Current as of 2026-09-09T23:22Z.** Overwritten each session.

All eleven trackers the Workspace Architecture mandates exist and are synchronized.

`AGENTS.md` is present at the repository root and tracked in git (`5606d418`).

## Where the project is

Both binaries (`bin/jenova-core` and `bin/jenova`) build natively in this workspace.

**Twenty-one of the twenty-two self-tests are socket-free and pass natively.**
Only `serve-selftest` binds a listener (port 18642) to drive load against a fake upstream;
an earlier claim that `relay-selftest` also binds a listener was false — its source in
`src/jenova_core.nim` tests `upstream.spliceHeaders` purely in memory on a fixed string buffer.
Neither `serve-selftest` nor the shell suites were run under the standing instruction not to bind listeners.

**This workspace is a Linux container hosted on a FreeBSD system.**
Kernel-level inspections, `sysctl` probes, and hardware detection paths must account for
container isolation. The `sysctl` probe, the `fork`/`setsid`/`execv` backend path, the
D-Bus tray, the Neovim page, and the GUI screenshots remain outstanding functional work.

## What this session accomplished

1. **D6 (Partial-node merge in `api.upsert`):**
   - Moved column merge logic into `api.upsert`, ensuring omitted columns in HTTP `POST /api/db/*`
     partial updates preserve existing stored fields (e.g. note content).
   - Simplified `api.putEntity` to delegate directly to `upsert`.
   - Verified with 2 new assertions in `workspace-selftest` (77 passing assertions).
2. **D5 (Hierarchical retrieval scoping & `X-Jenova-Scope` wire contract):**
   - Implemented down-tree container ladder in `rag.nim` (`inScope` and `query`):
     - Non-workspace queries strictly isolate from all workspace folders.
     - Workspace queries search workspace and all descendant projects and folders.
     - Project queries search project and child folders.
     - Folder queries isolate strictly to that folder.
   - Wired `X-Jenova-Scope: folder=<id>;project=<id>;workspace=<id>` across `http.nim`, `server.nim`,
     `pipeline.nim`, and `gui.nim`.
   - Verified with 16 new assertions in `rag-selftest` (all passing).
3. **D9 (Pure HTTP chunked body parsing):**
   - Implemented pure, socket-free `parseChunkedBody` in `http.nim` enforcing `MaxBodyBytes`.
   - Connected streaming socket chunk reading into `parseRequest`.
   - Verified with 9 new assertions in `routes-selftest` (28 passing assertions).
4. **Review fixes & hardening (AGENTS.md, rag.nim, gui.nim, http.nim):**
   - Standardized `AGENTS.md` to canonical UTC ISO-8601 (`YYYY-MM-DDTHH:MMZ`) with explicit `Z` sourced from harness tooling/clock; replaced cross-reference label with direct approval wording; removed prescriptive shell execution commands.
   - Preloaded container scope dictionaries (`noteContainers()`, `fileContainers()`, `conversationContainers()`) in `rag.nim` to eliminate candidate-by-candidate SQLite queries; reordered vector scanning to evaluate `dotBlob` and `SemanticFloor` before checking scope; added CRLF sanitization to `formatScope`.
   - Added send-site CRLF injection protection to `gui.nim` for `scopeHeader`.
   - Implemented stateful `ChunkParser` in `http.nim` with incremental payload streaming without buffer re-allocation, strictly measuring `MaxBodyBytes` against decoded payload bytes with bounded chunk header guards.
   - Verified with 4 new assertions in `routes-selftest` (32 passing assertions, all 21 socket-free self-tests green).
5. **Chunk Parser Memory & Overflow Hardening (`http.nim`):**
   - Validated declared chunk sizes against remaining allowable body bytes before waiting for complete chunk data or reading from socket, rejecting oversized declarations immediately.
   - Replaced `dataEnd + 2 > raw.len` with subtraction (`raw.len - dataEnd < 2`) to eliminate 64-bit integer overflow.
   - Updated `parser.pos` on zero-chunk completion to point past chunk trailers.
   - Restructured socket read loop in `http.parseRequest` to prune consumed bytes from `raw` after each `feed` call, reset `parser.pos = 0`, and preserve unconsumed framing bytes without buffer bloat.
   - Gated by 4 new assertions in `routes-selftest` (36 passing assertions, all 21 socket-free self-tests green).
6. **Tracker & architectural hygiene:**
   - All completed items moved through `PLANS.md` -> `PROGRESS.md`, cleared from `TODOS.md` Active.
   - Core architectural invariants updated in `BLUEPRINT.md`.

## Blockers

None. Standing instruction: do not bind listeners (`serve-selftest` or shell test suites).

## Next 3-5 steps

1. Progress M-3: add `bkMath` to `markdown.BlockKind`, parse `$$...$$` display math blocks, and wire `mathtex`/`mathfont` Cairo rendering into `gui.nim`.
2. Phase 2.2: reduce the three render memos (`BlockMemo`, `ParseMemo`, `thumbCache`) to viewport scale rather than conversation scale.
3. Concurrency design for retrieval layer: address the two deferred races from report 03 (`forgetMessage` against restore-and-update indexing, and descendant discovery against fork creation).
4. Phase 4.3: implement the command palette in the desktop GUI.
