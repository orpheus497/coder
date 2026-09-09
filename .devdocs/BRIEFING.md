# BRIEFING

**Current as of 2026-09-09T05:31Z.** Overwritten each session.

All eleven trackers the Workspace Architecture mandates now exist.

`AGENTS.md` is restored to the repository root, byte-identical to the version deleted in
`c5111ce3`. It is untracked until committed.

## Where the project is

Both binaries build natively in this workspace and nineteen of the twenty-one self-tests
pass here; `serve` and `relay` were not run this session because they bind listeners and
the session was instructed not to run the server or the program.

**This workspace is the FreeBSD target**, reached through the Linuxulator. The audit
reports were written in a Linux container and record their remaining work as blocked on
a FreeBSD host; that framing is retired. The `sysctl` probe, the `fork`/`setsid`/`execv`
backend path, the D-Bus tray, the Neovim page, GTK 4.20.4 and the GUI screenshots are
outstanding work, not blocked work.

## What this session did

A line-by-line audit of the request path — `pipeline`, `rag`, `db`, `server`, `upstream`,
`routes`, `http`, `api`, `workspace`, `composer`, `markdown`, `mathfont`, `lifecycle` and
the window's send path — against the eight audit reports. Nine defects were found that no
report records. Five were repaired; two are held for a ruling; two are backlogged.

Repaired: attachment turns bypassing the whole pipeline; the workspace context read whole
on the GTK thread and unbounded into a system message the trimmer never drops;
`/v1/embeddings` routed to the chat backend; `queryBlob` truncating on error; thirty font
walks. See `PROGRESS.md`.

Then: a new `routes-selftest` closing the coverage gap that let the routing defect live —
nineteen assertions over `classify` and `pathFromHead`, none of which needs a socket —
and the report-hygiene corrections across reports 02 through 07.

**Twenty of the twenty-two self-tests pass here.** `serve` and `relay` were not run.

## Blockers

Two items need a decision before they can be built — both change a contract rather than
repair a defect. They are stated in `DECISIONS_LOG.md` and sitting in `TODOS.md` Backlog:

- **D5, retrieval scoping.** `prepare` takes a `projectRoot` nothing passes, so every
  query searches every workspace. Closing it needs the server to learn the conversation,
  which the body does not carry.
- **D6, the partial-node merge.** `putEntity` merges; the HTTP route does not, and blanks
  omitted columns. `api.nim` and `gui.nim` document opposite intentions for this.

## Next 3-5 steps

1. Rule on D5 (retrieval scoping) and D6 (the partial-node merge).
2. Rule on V-17 — symbol-bearing citations with a gate, or no line numbers in prose.
3. Run `serve-selftest`, `relay-selftest` and the six shell suites when a listener is
   permitted, so the suite is green end to end rather than green minus two.
4. Take the FreeBSD work now that the host is the target — the `sysctl` probe, the tray
   against a real watcher, the Neovim page, and the `png/gui-*.png` screenshots that gate
   reordering the README. All of it needs the program run, which this session could not do.
5. M-3: import `mathtex` and `mathfont` into `gui.nim`, add `bkMath`, build the branch,
   then draw. Report 08 §5 lists the landing sites and none has been taken.
