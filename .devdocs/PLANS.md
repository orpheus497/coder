# PLANS

Forward-looking implementation plans. An item here has a matching `TODOS.md` Active
entry; on execution it moves to `PROGRESS.md`.

---

## D1 — read a turn's text whichever shape its content took

**Where:** `src/jenova/pipeline.nim`, `prepare`.

`contentFor` answers a JSON array whenever a turn carries an attachment, and `getStr`
on an array answers the empty string. Every enrichment in `prepare` sits behind
`if lastUser.len > 0`, so an attachment turn reaches the model with no persona, no
retrieval, no web search, no editor document, and its intent prefix neither detected
nor stripped.

**Approach.** A `userText` helper that reads a `JString` directly and joins the `text`
parts of a `JArray`. The prefix write-back cannot assign a string over an array — that
would destroy the attachments — so it replaces the text of the first text part instead,
leaving every other part untouched.

**Gate.** `pipeline-selftest`, asserting that an array-shaped turn detects its intent,
strips the prefix from the first part only, and keeps its image part.

---

## D2/D3 — bound the workspace context and stop reading whole tables for it

**Where:** `src/jenova/workspace.nim`.

`allNotes` and `allFiles` select the `content` column for every live row and the caller
filters afterwards, so one send materialises every note and every uploaded document in
the database. `gui.postConversation` calls it on the GTK thread. The result is appended
to the system message, and `pipeline.trimHistory` is written never to drop a system
message — so once the dump alone exceeds the budget, every turn discards the whole
conversation and is still over budget, while `X-Jenova-Trimmed` blames the history.

**Approach.** Two changes in one place:

1. Select identity and scoping columns for every row, do the scoping on those, then read
   the `content` of only the rows that survived, one at a time. The same rule the
   retrieval backfill already follows.
2. A byte budget on the assembled block. FOCUS notes are filled first because they are
   rules rather than material, then notes, then files; when the budget is reached the
   block says how many artefacts it omitted rather than stopping silently.

Bounding the input is the fix rather than teaching `trimHistory` to drop system content:
the system message carries the persona and the injected blocks, and dropping it changes
who is answering.

**Gate.** `workspace-selftest`, asserting the scoping ladder is unchanged, that a body
over the budget is omitted with a count, and that the whole-table read is gone.

---

## D4 — route `/v1/embeddings` to the embedding backend

**Where:** `src/jenova/routes.nim`, `classify`.

`/v1/` is tested before `/embed`, so the OpenAI-standard embeddings path classifies as a
completion and is forwarded to the chat backend. Internal retrieval is unaffected —
`rag.embed` calls the embedding port directly — so this is the external surface only.

**Approach.** Test the embed prefixes, including `/v1/embeddings`, before the `/v1/`
completion prefix.

**Gate.** `routes` assertions in `jenova_core.nim`.

---

## D7 — a step error must not read as end of rows

**Where:** `src/jenova/db.nim`, `queryBlob`.

`query` raises on a step code that is neither `ROW` nor `DONE`; `queryBlob` breaks out of
its loop and returns the rows it happened to collect. Its only caller is the retrieval
vector scan, so a locked or erroring database silently degrades ranking.

**Approach.** Match `query`: `DONE` ends the loop, anything else raises.

**Gate.** `db-selftest`.

---

## D8 — walk the font roots once, not once per candidate

**Where:** `src/jenova/mathfont.nim`, `chooseFont`.

The candidate loop encloses the root loop, which encloses `walkDirRec`, so six candidates
over five roots is thirty recursive walks of the system font tree. Nothing calls this
yet, which is why it has cost nothing; it is on the path M-3 lands on.

**Approach.** One walk per existing root collecting the candidate basenames it holds,
then probe in preference order. Preference order and the three-question test are
unchanged.

**Gate.** `math-selftest`.
