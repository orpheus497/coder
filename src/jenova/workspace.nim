## Script function and purpose: the notes and files belonging to a
## conversation's workspace, project or folder, rendered so the model answers
## with them in view. Depends on `db` and `std` and nothing else, which is what
## lets the self-test assert the whole scoping ladder with no window and no
## backend.
##
## Three scoping rules carry the behaviour and none is obvious from the code:
## a FOCUS note applies across its entire workspace tree, so a rule written at
## the root reaches a chat three levels down; regular notes at folder level are
## strictly isolated from sibling folders, widening to the project's folders at
## project level and to everything nested at workspace level; and files have no
## FOCUS concept at all.
##
## The assembled block is bounded by `MaxContextBytes` and its bodies are read
## one at a time, for rows the scoping kept. Both matter: the block enters the
## system message, which `pipeline.trimHistory` never drops, and this runs on
## the window's own thread on every send.

import std/[strutils, tables]
import ./db

const
  ## Literal because it is a format the model has already been taught; a
  ## reworded heading is a different prompt.
  ContextHeading* = "[CURRENT WORKSPACE ARTIFACTS (Notes & Files)]:"

  ## The ceiling on one assembled block. It is appended to the system message,
  ## and `pipeline.trimHistory` never drops a system message — so without a
  ## bound here a large workspace makes every turn drop the entire conversation
  ## and still exceed the context, with the trim counted against a history that
  ## was not the cause.
  MaxContextBytes* = 64 * 1024

type
  Note* = object
    ## `content` is empty on a row read for scoping alone; `id` is what fetches
    ## it once the scoping has decided the row is wanted.
    id*: string
    title*, content*: string
    folderId*, projectId*, workspaceId*: string
    isFocus*: bool

  FileAsset* = object
    id*: string
    name*, kind*, content*: string
    folderId*, projectId*, workspaceId*: string

## Function purpose: exported because the window reads the same column when it
## opens a note, and two copies of this test would drift the moment either was
## widened — leaving a note FOCUS to the context builder and not to the toggle
## showing it. The column is written by three surfaces with three notions of a
## boolean, so all four falsehoods are named rather than assumed away.
proc isFocusValue*(raw: string): bool =
  raw notin ["", "0", "null", "false"]

## Function purpose: deleted rows are excluded here rather than at each call
## site. A soft-deleted note is in the trash, and the model quoting it back
## makes the deletion look ignored exactly where the user would notice.
proc allNotes*(): seq[Note] =
  for r in db.query("SELECT id, title, content, folderId, projectId, " &
                    "workspaceId, isFocusNote FROM notes WHERE is_deleted=0"):
    result.add Note(
      id: r[0], title: r[1], content: r[2], folderId: r[3], projectId: r[4],
      workspaceId: r[5], isFocus: isFocusValue(r[6]))

## Function purpose: the file half of the same rule, excluded the same way.
proc allFiles*(): seq[FileAsset] =
  for r in db.query("SELECT id, name, type, content, folderId, projectId, " &
                    "workspaceId FROM fileAssets WHERE is_deleted=0"):
    result.add FileAsset(
      id: r[0], name: r[1], kind: r[2], content: r[3], folderId: r[4],
      projectId: r[5], workspaceId: r[6])

## Function purpose: the same rows without their bodies, which is what the
## scoping below actually reads. Selecting `content` for every live row
## materialises every note and every uploaded document in the database, and
## `contextFor` runs on the window's own thread on every send.
proc noteScopes*(): seq[Note] =
  for r in db.query("SELECT id, title, folderId, projectId, workspaceId, " &
                    "isFocusNote FROM notes WHERE is_deleted=0"):
    result.add Note(
      id: r[0], title: r[1], folderId: r[2], projectId: r[3],
      workspaceId: r[4], isFocus: isFocusValue(r[5]))

## Function purpose: the file half of the same rule.
proc fileScopes*(): seq[FileAsset] =
  for r in db.query("SELECT id, name, type, folderId, projectId, " &
                    "workspaceId FROM fileAssets WHERE is_deleted=0"):
    result.add FileAsset(
      id: r[0], name: r[1], kind: r[2], folderId: r[3], projectId: r[4],
      workspaceId: r[5])

## Function purpose: one body, fetched only once the scoping has decided the row
## belongs in the prompt.
proc noteBody*(id: string): string =
  if id.len == 0: return ""
  let rows = db.query("SELECT content FROM notes WHERE id=?", id)
  if rows.len > 0 and rows[0].len > 0: rows[0][0] else: ""

## Function purpose: the file half of the same rule.
proc fileBody*(id: string): string =
  if id.len == 0: return ""
  let rows = db.query("SELECT content FROM fileAssets WHERE id=?", id)
  if rows.len > 0 and rows[0].len > 0: rows[0][0] else: ""

## Function purpose: built once per call rather than queried per note, because
## the scoping below asks the same question of every row.
proc folderParents*(): Table[string, string] =
  for r in db.query("SELECT id, projectId FROM folders WHERE is_deleted=0"):
    result[r[0]] = r[1]

## Function purpose: the other half of the ladder, kept separate so a caller
## scoping to a project need not load the folder table at all.
proc projectParents*(): Table[string, string] =
  for r in db.query("SELECT id, workspaceId FROM projects WHERE is_deleted=0"):
    result[r[0]] = r[1]

## Function purpose: the level is the deepest container the *note* carries, not
## the chat asking. That is what tells the model whether a rule is workspace-wide
## or local, and deriving it from the asker would invert the meaning.
proc focusLevel(n: Note): string =
  if n.folderId.len > 0: "Folder"
  elif n.projectId.len > 0: "Project"
  else: "Workspace"

## Function purpose: scoped by the deepest container id the conversation
## carries, and empty when there is nothing to say, so a caller can test `.len`
## without knowing the format.
##
## Action purpose: the branches are ordered folder, project, workspace, global,
## and global means artifacts belonging to nothing at all rather than to
## everything.
proc contextFor*(folderId, projectId, workspaceId: string,
                 maxBytes = MaxContextBytes): string =
  let notes = noteScopes()
  let files = fileScopes()
  let folderOf = folderParents()
  let projectOf = projectParents()

  var regular, focus: seq[Note]
  for n in notes:
    if n.isFocus: focus.add n else: regular.add n

  var targetNotes, targetFocus: seq[Note]
  var targetFiles: seq[FileAsset]

  ## The workspace a scope sits in and everything beneath it. FOCUS notes are
  ## gathered against this whole set at every level, which is how a FOCUS note
  ## escapes the level it was written at.
  proc treeOf(wsId: string): tuple[projects, folders: seq[string]] =
    for pid, wid in projectOf:
      if wid == wsId: result.projects.add pid
    for fid, pid in folderOf:
      if pid.len > 0 and pid in result.projects: result.folders.add fid

  ## `projectNeedsNoFolder` narrows a project-level FOCUS note to one that names
  ## no folder, which the folder and project branches need and the workspace
  ## branch does not.
  proc gatherFocus(wsId: string, projects, folders: seq[string],
                   projectNeedsNoFolder: bool) =
    for n in focus:
      let atRoot = n.workspaceId == wsId and n.projectId.len == 0 and
                   n.folderId.len == 0
      let inProject = n.projectId.len > 0 and n.projectId in projects and
                      (not projectNeedsNoFolder or n.folderId.len == 0)
      let inFolder = n.folderId.len > 0 and n.folderId in folders
      if atRoot or inProject or inFolder:
        targetFocus.add n

  if folderId.len > 0:
    # Strictly this folder: a sibling folder's notes are deliberately invisible.
    for n in regular:
      if n.folderId == folderId: targetNotes.add n
    for f in files:
      if f.folderId == folderId: targetFiles.add f
    let pid = folderOf.getOrDefault(folderId, "")
    let wsId = projectOf.getOrDefault(pid, "")
    if wsId.len > 0:
      let tree = treeOf(wsId)
      gatherFocus(wsId, tree.projects, tree.folders, true)

  elif projectId.len > 0:
    var childFolders: seq[string]
    for fid, pid in folderOf:
      if pid == projectId: childFolders.add fid
    for n in regular:
      if n.projectId == projectId or
         (n.folderId.len > 0 and n.folderId in childFolders): targetNotes.add n
    for f in files:
      if f.projectId == projectId or
         (f.folderId.len > 0 and f.folderId in childFolders): targetFiles.add f
    let wsId = projectOf.getOrDefault(projectId, "")
    if wsId.len > 0:
      let tree = treeOf(wsId)
      gatherFocus(wsId, tree.projects, tree.folders, true)

  elif workspaceId.len > 0:
    let tree = treeOf(workspaceId)
    for n in regular:
      if n.workspaceId == workspaceId or
         (n.projectId.len > 0 and n.projectId in tree.projects) or
         (n.folderId.len > 0 and n.folderId in tree.folders): targetNotes.add n
    for f in files:
      if f.workspaceId == workspaceId or
         (f.projectId.len > 0 and f.projectId in tree.projects) or
         (f.folderId.len > 0 and f.folderId in tree.folders): targetFiles.add f
    # Action purpose: no folder guard on the project clause here, unlike the two
    # branches above. A workspace chat already sees everything below it, so the
    # narrower test would exclude nothing and only diverge.
    gatherFocus(workspaceId, tree.projects, tree.folders, false)

  else:
    # Action purpose: only what belongs to nothing. An unassigned chat seeing
    # every workspace's notes is how a rule from one project ends up answering a
    # question about another.
    for n in regular:
      if n.folderId.len == 0 and n.projectId.len == 0 and
         n.workspaceId.len == 0: targetNotes.add n
    for f in files:
      if f.folderId.len == 0 and f.projectId.len == 0 and
         f.workspaceId.len == 0: targetFiles.add f
    # And no FOCUS notes: a focus note is a rule for a workspace, and a global
    # chat is in none.

  # Action purpose: bodies are read here, one at a time, and only for rows the
  # scoping above kept. The budget is spent in the order FOCUS, notes, files
  # because a FOCUS note is a rule and the other two are material — losing a
  # rule changes how everything else is read.
  #
  # An entry that does not fit is skipped and counted rather than truncated: a
  # shortened note reads as a whole one and is answered as though it were.
  var spent = 0
  var omitted = 0

  proc room(n: int): bool =
    if spent + n > maxBytes:
      inc omitted
      return false
    spent += n
    true

  if targetFocus.len > 0:
    var any = false
    var block1 = "--- FOCUS / RULES ---\n"
    for n in targetFocus:
      # An empty focus note contributes nothing rather than a bare heading.
      let body = noteBody(n.id)
      if body.strip.len == 0: continue
      let entry = "[" & n.focusLevel & "] " & n.title & "\n" & body & "\n\n"
      if not room(entry.len): continue
      any = true
      block1.add entry
    if any: result.add block1

  if targetNotes.len > 0:
    var any = false
    var block2 = "--- NOTES ---\n"
    for n in targetNotes:
      let entry = "Title: " & n.title & "\nContent: " & noteBody(n.id) & "\n\n"
      if not room(entry.len): continue
      any = true
      block2.add entry
    if any: result.add block2

  if targetFiles.len > 0:
    var any = false
    var block3 = "--- FILES ---\n"
    for f in targetFiles:
      let body = fileBody(f.id)
      var entry = "File: " & f.name & " (Type: " & f.kind & ")\n"
      if body.len > 0:
        entry.add "Content:\n" & body & "\n\n"
      else:
        entry.add "(Binary file, content not available for direct reading)\n\n"
      if not room(entry.len): continue
      any = true
      block3.add entry
    if any: result.add block3

  # Named rather than silent: a model answering without an artefact the user can
  # see in the sidebar is the one failure they cannot diagnose from the window.
  if omitted > 0:
    result.add "--- " & $omitted & " further workspace artefact" &
               (if omitted == 1: "" else: "s") &
               " omitted to fit the context budget ---\n"
