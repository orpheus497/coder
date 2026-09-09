# TESTS

Test specs, validation criteria and expected outcomes.

---

## The standard this project holds itself to

**An assertion that has not been proven to fail is not a gate.** The record is explicit
about this — a check that states a property it does not test passes whatever the code
does, and one such assertion shipped and was caught only by reverting the fix underneath
it. So: after writing an assertion, revert the fix, run it, confirm it goes red, restore.
Record which assertions actually moved, not how many were added.

**Vary the data, not the code.** A test that constructs its own fixture through raw SQL
cannot see a defect in the write path the product uses. Where a property depends on the
shared write path, drive it through that path.

## Layers, and what each can and cannot see

| Layer | Command | Sees | Cannot see |
|---|---|---|---|
| Type check | `nimble core`, `nimble gui` | Type errors, owlkettle API misuse | Anything the C compiler decides; anything about a running window |
| Self-tests | `bin/jenova-core <name>-selftest` | Pure logic, database behaviour, the request path against scratch state | Widget behaviour, allocation, keystrokes |
| Window type check | `sh tests/gui_check.sh` | `gui.nim` semantic analysis | Header conflicts between an `importc` and owlkettle's own prototype — `nim check` runs no C compiler |
| Shell suites | `tests/test_*.sh` | The routes against a running server | Anything in the window |
| Mapped window | `sh tests/gui_build.sh` | Build, link, allocation, real keystrokes | FreeBSD-specific process and D-Bus behaviour when run elsewhere |

**A type check is not a build, and a build is not a run.** Each of the three has caught a
defect the one below it could not.

## Self-test inventory

Registered in `jenova_core.nimble` and listed by `usage()`. A test registered in one and
not the other is undiscoverable from the binary, which has happened.

`db` · `sha256` · `markdown` · `error` · `tree` · `attach` · `workspace` · `nvim-env` ·
`models` · `fs` · `hardware` · `composer` · `convmd` · `asset` · `lifecycle` · `relay` ·
`inspect` · `math` · `pipeline` · `rag` · `routes` · `serve`

### Which of them bind a listener

`serve` stands up a socket (port 18642). `relay` does not stand up a socket — its assertions
test `upstream.spliceHeaders` purely on in-memory string buffers. All other 21 self-tests are socket-free
and can run under a constraint that forbids running a server. `routes` exists precisely because the routing
table was previously assertable only through `serve` — a property decidable with no socket
had no socket-free test, and a routing defect lived in the gap.

## Validation criteria

**A change to the request path** must show a passing `pipeline`, `routes` and `rag`, and
the assertion covering it must have been proven to fail without the fix.

**A change to the database or the mirror** must show `db`, `fs`, `workspace` and `asset`.

**A change to backend supervision** must show `lifecycle`. Note that its assertions drive
`start` against a real file with no execute bit, which is the one shape of an `execve`
failure reproducible without a backend.

**A change to `gui.nim`** is not validated by a type check. It needs `nimble gui` and then
the window run. This is the standing rule and the one most often skipped.

**A change to a self-test's own fixture** is suspect: an assertion adjusted until it
passes is the defect it was written to catch, in a new place.

## Known-fragile assertions

- `db-selftest`'s concurrency overlap is a wall-clock measurement. Its metric was corrected
  once — overlap is scored against the shorter of the two spans, not the reader's own — but
  it remains timing-sensitive on a loaded host.
- `serve-selftest`'s static-asset phase requires `public/` to exist, which only the `web`
  task builds. `suites` depends on `web` for this reason.
- `gui_build.sh`'s screen probes measure a maximum over frames rather than over pixels,
  because a blinking caret reaches the top of a per-pixel range.

## Current state

Twenty-one of the twenty-two self-tests are socket-free and pass in this workspace.
`serve-selftest` binds a listener and has not been run under the standing instruction
not to run the server; nothing currently in the tree depends on it for its own coverage,
but the suite is not green end to end until it is run.

The shell suites and `gui_build.sh` have likewise not been run here.
