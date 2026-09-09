# SUMMARIES

One paragraph per session, pointing at the matching `SESSION_HANDOFF.md` entry.
Newest first.

---

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
