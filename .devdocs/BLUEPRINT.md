# BLUEPRINT

Authoritative system architecture: what the product is, what it depends on, and how data
moves through it. `ARCHITECTURE_MAPPING.md` is the file-by-file companion.

---

## What this is

One process that is simultaneously an HTTP server, a supervisor for `llama-server`, a
database owner and a GTK4 desktop window. The window is the product; the browser client
is the LAN surface.

**The central property:** both surfaces are clients of the same `api.nim` and the same
`pipeline.nim`. The window calls them in-process; the Web UI calls them over HTTP. A
behaviour cannot exist on one surface and not the other unless it is drawn there, which
is what makes "the daemon is up" and "the client port answers" incapable of disagreeing.

## Requirements

- **Offline-first.** Inference is local. The only outbound calls are the web-search
  lookup and the embedding server, both named in `docs/privacy.md`.
- **No authentication.** The server does not authenticate and the settings record that as
  deliberate. It is reachable on loopback, and on the LAN only when that is toggled on.
- **Soft deletion throughout.** Rows are flagged, never removed, which is what makes the
  trash and restore possible.
- **A frozen client.** `jca_web` cannot be changed to match a tidier contract, so route
  shapes, query parameters and response bodies are fixed.
- **FreeBSD is the supported and tuned target.** Nothing under `src/jenova/` carries an OS
  conditional; the one platform-shaped dependency is the `sysctl` hardware probe.

## Dependencies

| | |
|---|---|
| Language | Nim 2.2.x |
| Toolkit | GTK4, libadwaita, GtkSourceView, VTE, via **owlkettle pinned to a commit** — `>= 3.0.0` was satisfied by two different trees |
| Storage | libsqlite3, loaded by name at runtime, FTS5 probed rather than assumed |
| Inference | `llama.cpp` / `llama-server`, supervised as a child process |
| Maths metrics | HarfBuzz, already linked through Pango — no new dependency |
| Licence policy | Permissive primary, MIT and BSD preferred, zero proprietary |

## Data flow — a chat turn

1. The window assembles the transcript and calls `pipeline.chatBody`, which appends the
   workspace context and the thinking directive to the system message.
2. It posts to **its own local server** over a raw socket, so the desktop client exercises
   the same path every other client does.
3. `routes.classify` sends the connection to the completion pool.
4. `pipeline.prepare` rewrites the body: intent detected and stripped, retrieval queried
   and injected, web search run for its own intent, editor document read for its own,
   persona chosen, tools stripped where they do not apply, history trimmed, cache key
   hashed **last** over the rewritten body.
5. `server.handle` builds the diagnostic headers, consults the response cache, and hands
   the request to `upstream.forward`.
6. The relay streams bytes back verbatim, splicing the diagnostics into the head at a
   known offset and teeing a bounded copy for the cache.
7. The window's stream thread reads tokens and the diagnostic head, and posts both to the
   GTK thread over a channel carrying only plain values.

## Concurrency model

- **Threads, not an event loop.** Multiplexing every client onto one thread means a single
  blocking call freezes routing and token streaming for everyone.
- **Route classes have isolated pools**, so a saturated class cannot starve another.
- **Only integers cross a thread boundary.** The acceptor passes a socket handle; the
  owning worker parses on its own thread. Values shared with threads are fixed buffers,
  never refcounted strings.
- **One database connection per thread**, in a threadvar, opened lazily.
- **The window's GTK thread is the only writer of window state.** Two persistent workers —
  stream and control — plus a separate hardware worker report back over channels.
- **`--mm:arc` on the GUI only**, deliberately leaking owlkettle's state/event cycles
  rather than letting ORC collect a widget state GTK still holds.

## Invariants that hold, and must keep holding

- The cache key hashes the body **after** rewriting. Hashing the client's original body
  orphans every entry already stored.
- The response cache stores the **upstream's** head, never the spliced one, or one
  request's diagnostics are replayed to another.
- `trimHistory` never drops the system message or the final turn, and never shortens
  content.
- Anything appended to the system message must be bounded at its source, because the
  trimmer will not shorten it.
- A relay that delivered less than a status line is not a reply, and is refused rather
  than counted as complete.
- Static path resolution compares **resolved** against **resolved**, so a symlink cannot
  walk out of the served root.
- The render path never does work proportional to a payload; the memos exist for that and
  are capped.

## Known architectural debts

- **Retrieval is not scoped.** `prepare` accepts a project root and no caller passes one.
  Closing it needs the server to learn which conversation a completion belongs to, and the
  body does not carry that. Awaiting a ruling — see `DECISIONS_LOG.md`.
- **Partial writes differ by surface.** The in-process entry point merges a partial node
  onto the stored row; the HTTP route does not. Awaiting a ruling.
- **The maths engine is not linked into the window.** The parser, layout and font probe
  are written and asserted, and nothing in `gui.nim` can reach them.
- **The render memos are conversation-scaled, not viewport-scaled**, now that the
  transcript virtualises.
