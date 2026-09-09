# ARCHITECTURE MAPPING

What lives where, and why. Update when a file is added, removed or relocated.

**No line numbers and no counts, deliberately.** A citation nothing re-derives is a
citation that rots, which is the defect report 07 tracks as V-17. Files are named; their
contents are not pinned to positions.

---

## Entry points

| File | Role |
|---|---|
| `src/jenova_core.nim` | The headless binary. Resolves paths and configuration, starts the HTTP server, owns the database and the filesystem mirror, and proxies inference. **Every self-test lives here** — each runs against a scratch database and asserts a property of a module below it. |
| `src/jenova_gui.nim` | The desktop binary. Thin: it hands off to `jenova/gui`. |

## The request path

Ordered as a request travels it.

| File | Role |
|---|---|
| `jenova/http.nim` | HTTP/1.1 request parsing and response writing — no more of the protocol than this server speaks. Owns the body cap and `resolveStatic`'s containment check. |
| `jenova/routes.nim` | Which thread pool a connection is handed to, decided from the path alone so the acceptor can peek without consuming. Pure. |
| `jenova/server.nim` | The threaded server: acceptor threads classify, per-class worker pools handle. Owns the completion handler, the response-cache lookup and the diagnostic headers. |
| `jenova/pipeline.nim` | Everything done to a completion request between client and backend: intent detection, retrieval injection, web search, persona, tool stripping, history trimming, the cache key. Also the attachment classifier and the outbound chat body, kept here so both are assertable without a window. |
| `jenova/upstream.nim` | The streaming relay to `llama-server`. Splices response headers at a known offset, tees a bounded copy for the cache, and distinguishes complete from truncated. |
| `jenova/prompts.nim` | The personas and the `Intent` enum the pipeline switches on. |

## Persistence and the workspace

| File | Role |
|---|---|
| `jenova/db.nim` | SQLite bound directly. One connection per thread in a threadvar, WAL, a bounded prepared-statement cache. The schema lives here. |
| `jenova/api.nim` | The `/api/db`, `/api/fs` and `/api/storage` routes **and** the in-process entry points the window uses for the same operations. Generic entity handling, cascade deletes, restore, fork, import and export. |
| `jenova/fssync.nim` | The filesystem mirror: notes and file assets written to disk beside their rows, the trash tree and its sidecars, and the storage-path resolver. |
| `jenova/workspace.nim` | The notes and files belonging to a conversation's scope, assembled into the block the model is shown. Depends only on `db`, which is what makes the scoping ladder assertable. |
| `jenova/rag.nim` | Hybrid retrieval — BM25 over FTS5 plus vectors in a BLOB column. Chunking, indexing, the backfills, and the query. |

## Backend supervision

| File | Role |
|---|---|
| `jenova/lifecycle.nim` | Starting, stopping and watching the `llama-server` processes. Owns the fork/exec handshake, the cross-process start lock, log rotation and the health-probing watchdog. |
| `jenova/models.nim` | Discovering `.gguf` files and switching the active model slot. |
| `jenova/hardware.nim` | Machine detection and profile scoring. The one platform-shaped dependency — it asks `sysctl`. |
| `jenova/config.nim` | The configuration keys the program reads. An unlisted key is a key nothing consumes. |
| `jenova/paths.nim` | Path resolution for the install tree and the data tree, and the attachment-cache sweep. |

## The window

| File | Role |
|---|---|
| `jenova/gui.nim` | The GTK4/libadwaita window. The chat surface and the control surface both. |
| `jenova/theme.nim` | The stylesheet, as a string handed to GTK. |
| `jenova/canvas.nim` | The neural canvas, drawn straight onto Cairo. |
| `jenova/sourceview.nim` | GtkSourceView binding and the syntax schemes. |
| `jenova/vte.nim` | VTE terminal binding, for the embedded editor page. |
| `jenova/nvimctl.nim` | Talking to a running Neovim, and the live-document read the `Editor:` intent uses. |
| `jenova/tray.nim` | The D-Bus `StatusNotifierItem`, sharing the GTK main loop rather than a thread. |
| `jenova/dbus.nim` | The D-Bus binding the tray sits on. |
| `jenova/shortcuts.nim` | One window-level `GtkShortcutController`, so bindings are declared in one place. |
| `jenova/settings.nim` | The settings definitions, their defaults and their persistence. |
| `jenova/composer.nim` | The composer's decisions — send-or-newline, and the long-paste rule — kept out of the widget so they can be asserted. |
| `jenova/assetview.nim` | Classifying a stored file asset into something the viewer can show. |
| `jenova/inspect.nim` | The diagnostic headers, encoded and parsed. The pipeline and retrieval inspectors read this. |

## Rendering

| File | Role |
|---|---|
| `jenova/markdown.nim` | Splits a reply into blocks and turns inline markdown into Pango markup. Carries the inline maths pass and the `markupBalanced` guard. |
| `jenova/mathtex.nim` | The maths parser and box layout, over TeXbook Appendix G rules. Pure: no GTK, no Cairo, no owlkettle. **Not yet imported by `gui.nim`.** |
| `jenova/mathfont.nim` | The maths font probe and the OpenType MATH constants reader. Fills `mathtex`'s own constants type. **Not yet imported by `gui.nim`.** |
| `jenova/convmd.nim` | Conversations to and from markdown, for export and import. |
| `jenova/pdf.nim` | Text extraction from a PDF. No rasteriser. |

## Support

| File | Role |
|---|---|
| `jenova/sha256.nim` | The hash the cache key and the attachment cache are built on. |
| `jenova/zlib.nim` | Decompression, for PDF streams. |
| `jenova/websearch.nim` | The DuckDuckGo instant-answer lookup the web-search intent uses. |
| `jenova/pkgconfig.nim` | `pkg-config` with a failure path, so a missing package names itself instead of splicing prose into the linker. |
| `jenova/version.nim` | The version and copyright, in one place. |
| `jenova/dbselftest.nim` | The concurrency self-test, large enough to live apart. |
| `jenova/serverselftest.nim` | The server self-test and its fake upstream. |

## Tests

| Path | Role |
|---|---|
| `tests/gui_check.sh` | Type-checks the window. |
| `tests/gui_build.sh` | Builds, links, maps the window and drives it. The only harness that has ever done so. |
| `tests/test_*.sh` | Shell suites over the running server. |
| `tests/nvimctl_check.nim` | Driver for the Neovim control test. |

## Out of scope for this map

`jca_web/` (frozen Web UI), `jvim/`, `external/`, `hardware-profiles/`, `docs/`, `png/`.
