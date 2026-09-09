# SUMMARIES

One paragraph per session, pointing at the matching `SESSION_HANDOFF.md` entry.
Newest first.

---

**2026-09-09 (session 3).** Architectural rulings confirmed and documented across the devdocs corpus: D5 established the authoritative RAG retrieval scoping hierarchy (strict down-tree container scoping, with non-workspace chats and unfiled artifacts strictly isolated from workspace folders), D6 resolved to merge omitted row fields inside `api.upsert` to protect existing data from blanking, and V-17 banned all citation and tracking labels inside source code comments. See `SESSION_HANDOFF.md` → *architectural rulings confirmed: D5 retrieval scoping hierarchy, D6 partial-node merge, V-17 citation policy*.

**2026-09-09 (session 2).** Audited `.devdocs/` directly against active Nim logic in `src/` without relying on code comments, correcting false claims and synchronizing trackers. Resolved that `relay-selftest` tests `upstream.spliceHeaders` purely in memory on string buffers and binds zero sockets, meaning 21 of 22 self-tests are socket-free and pass natively. Confirmed `AGENTS.md` is tracked and committed in git (`5606d418`), recorded the runtime environment as a Linux container inside a FreeBSD system, cleared completed plans D1–D8 from `PLANS.md`, and reaffirmed the unlinked state of display math M-3 and the missing chunked decoder in `http.nim`. See `SESSION_HANDOFF.md` → *devdocs audit against active code and correction of false claims*.

**2026-09-09.** Audited the request path against the eight `.devdocs` reports by reading
`src/` rather than by searching it, after a first pass that did the latter and reported
the reports back. Nine defects were found that no report records, the largest being that
any turn carrying an attachment bypassed the whole pipeline — no persona, no retrieval,
no intent detection — because `prepare` read an OpenAI content array with `getStr`. Five
were repaired and gated, two are held for a ruling on contracts they would change, two
are backlogged. Eight report claims were found false, including that the maths engine is
not linked into the window at all and that the FreeBSD build guards the reports work
around no longer exist. The "blocked on a FreeBSD host" framing was retired: this
workspace is that host. See `SESSION_HANDOFF.md` → *source audit against the eight
reports, and five repairs*. The same session then restored `AGENTS.md` to root on
instruction, closed the coverage gap that had let the routing defect live by adding a
socket-free `routes-selftest`, and applied the report-hygiene corrections rather than
listing them — including that the maths engine is not linked into the window at all, which
three documents had described as merely unpainted.
