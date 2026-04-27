---
name: notes
description: >
  Capture quick inbox notes into the vault without breaking flow. Verbatim
  capture, silent auto-match append on overlap, silent file creation on no
  match. Per-project filtering via source_project. Listing and processing
  flows for triaging the inbox later. Triggers on: "/note", "/dump",
  "note this", "remember this for later", "add to inbox", "todo:",
  "show my inbox", "/note list", "what's in notes",
  "/note process", "process my notes", "process the inbox",
  "triage the inbox".
allowed-tools: Read Write Edit Glob Grep Bash
---

# notes: Inbox Capture for the Vault

Some thoughts shouldn't interrupt the work to write a real wiki page. A bug in tooling. A follow-up for another project. "This didn't work, revisit later." This skill catches them, verbatim, and files them in `<vault_root>/notes/` without prompts. Triage happens later.

The wiki is the polished knowledge base. `notes/` is the inbox. Keep them separate. `/save` files synthesised pages; `/note` files raw thoughts.

---

## Vault path

Resolve `<vault_root>` exactly the same way `wiki` does — project setting `claude-obsidian.vault_path` first, then CWD if it contains `wiki/`, then settings files via `${CLAUDE_PLUGIN_ROOT}/scripts/resolve-vault.sh`. **Always write to `<vault_root>/notes/`** regardless of CWD. The `source_project` field records where the user was when capturing.

If no vault is configured, abort with `No vault configured — run /wiki init first.`

---

## Operations

| User says | Operation | Handled by |
|-----------|-----------|------------|
| `/note <text>`, `/dump <text>`, "note this …", "remember this for later", "add to inbox …", "todo: …" | CAPTURE | this skill |
| `/note list`, "show my inbox", "what's in notes" | LIST | this skill |
| `/note process`, "process my notes", "triage the inbox" | PROCESS | this skill |

Capture, list, and process do not prompt for tags, types, or confirmations beyond the per-note action prompt in PROCESS.

---

## CAPTURE Operation

Goal: persist the user's verbatim text with minimal metadata. No conversation context, no auto-tagging, no questions.

Steps:

1. **Extract** the verbatim text from the user's message. For `/note <text>` and `/dump <text>`, the text is everything after the trigger. For natural-language triggers (`"note this: …"`, `"todo: …"`), extract the substring after the trigger phrase. Preserve the original wording exactly — no rewriting, no summarising.
2. **Resolve** `<vault_root>` (see Vault path). Compute today's date as `YYYY-MM-DD`. Compute `source_project = basename(cwd)`. If `<vault_root>/notes/` does not exist, create the directory and initialise `notes/index.md` from the template in the `## notes/index.md` section below; then continue.
3. **Enumerate** existing notes by listing `<vault_root>/notes/*.md` and reading **frontmatter only** for each (title, topic, tags). Skip bodies — they bloat the prompt and aren't needed for the match decision. Skip `notes/index.md` and any file with `status: deferred`. (Deferred notes are excluded intentionally: the user set them aside; routing new content into them would silently overturn that decision.) Cap candidates at the **20 most recent by `updated:`** — older notes rarely match new captures and inflate the prompt. Use `mcp__obsidian-vault__obsidian_batch_get_file_contents` when the MCP server is available to read frontmatter in one call.
4. **Decide MATCH or NEW** using the prompt template below. The bar is intentionally high; misroutes cost more than duplicates because the user does not see the decision at capture time.
5. **MATCH path** — append to the existing file:
   - Add a separator + the new verbatim chunk to the body:
     ```
     <existing body>

     ---

     <new verbatim text>
     ```
   - If the new content broadens the note's scope, **rewrite `title:`** to a phrase covering the union. Bump `updated:` to today. Frontmatter `topic:` and `tags:` may be widened as needed; never narrowed.
   - **Filename is never renamed.** Drift between filename slug and rewritten `title` is acceptable.
6. **NEW path** — create a new file:
   - **Title.** Derive a one-line summary (≤80 chars) of the verbatim text, stripping leading filler ("we need to", "can we check", "I think we should") so the substance leads. If the verbatim text is itself short, substantive, and one-line, use it as the title.
   - **Slug.** Compute via `bash ${CLAUDE_PLUGIN_ROOT}/scripts/slug.sh "$title" "$body"` — see that script's header for the contract. Do not slugify in-prompt. Exit 1 means both inputs slugify to empty; surface that as an error rather than inventing a name.
   - **Path:** `<vault_root>/notes/YYYY-MM-DD-<slug>.md`. If that filename already exists for today, append a counter suffix `-2`, `-3`, … incrementing. Different days never collide because the date prefix differs.
   - **Frontmatter** from the template below; body is the verbatim text. Topic and tags may be left empty (`""` and `[]`) — they're populated by the user later if needed.
7. **Update `notes/index.md`** — patch in place, no full rewrite:
   - On NEW: prepend a row under `## Pending`.
   - On MATCH: find the existing row by the **pre-rewrite title** (the title the file had before this operation). Bump its date to today; if the title was rewritten, replace the title text. Never add a duplicate row.
   - Format: `- [ ] YYYY-MM-DD [<source_project>] <title>`.
8. **Confirm** with one terse line. Two shapes only:
   - NEW: `Captured to notes/YYYY-MM-DD-<slug>.md`
   - MATCH: `Appended to notes/YYYY-MM-DD-<slug>.md`

Do **not** print the diff, the match reasoning, or the candidate list. Capture is a fire-and-forget action.

### Match prompt template

When CAPTURE step 3 enumerates candidates, run this decision in your head before writing. Output exactly one of `MATCH: <filename> | <reason>` or `NEW`.

```
Existing notes (frontmatter only):
{{for each candidate, render: filename, title, topic, tags}}

New note text:
"""
{{verbatim user text}}
"""

Decide:
- MATCH: <filename> | <one sentence why> — only if a single candidate clearly
  extends or near-duplicates the new content. Required signals (ALL must hold):
    1. (title alignment) OR (topic alignment) — same subject, not just same domain.
    2. (tag overlap ≥ 1) OR (tags empty on both, AND title/topic alignment is strong).
    3. The new content is a logical extension of the existing scope (continuation,
       counter-example, follow-up question on the same thing) — not a new thread.
- NEW — anything ambiguous, weak, cross-cutting, contradictory, or where two
  candidates plausibly fit. The bar is high; default to NEW under doubt.
```

Use `MATCH` only when one candidate stands out clearly. If two candidates both look plausible, output `NEW` — duplicates are recoverable, misroutes are silent.

---

## LIST Operation

Goal: show pending and deferred notes for triage.

Steps:

1. Read `<vault_root>/notes/*.md` frontmatter (title, source_project, status, updated). Skip `notes/index.md`. Use `mcp__obsidian-vault__obsidian_batch_get_file_contents` when available — one batched read beats N sequential ones once the inbox grows past a handful of notes.
2. Sort by `updated` descending.
3. Render flat reverse-chronological bullets:
   ```
   Pending notes (N):

   - [ ] YYYY-MM-DD [source_project] title
   - [ ] YYYY-MM-DD [source_project] title

   Deferred (M):

   - [~] YYYY-MM-DD [source_project] title
   ```
   Glyphs: `[ ]` pending, `[~]` deferred. Always include both sections; show `(none)` under a section that's empty.
4. **Filter `--project=<basename>`** — when present, only show notes whose `source_project` matches. Honour the same flag in natural-language form (`"show my inbox for claude-obsidian"`).

`/note list` includes pending + deferred. `/note process` iterates pending only by default; pass `--include-deferred` to walk both.

---

## PROCESS Operation

Goal: walk pending notes one at a time and route each to `/save`, defer, or delete.

Steps:

1. Enumerate pending notes (skip `status: deferred` unless `--include-deferred`). Sort by `updated` ascending — oldest first. If there are no notes to process, print `Inbox is empty.` and exit.
2. For each note, read full frontmatter + body and display:
   ```
   [N/total] YYYY-MM-DD [source_project]
   title: <title>
   body:
   > <verbatim body, indented as a blockquote>

   Action? [s]ave / [d]efer / [x]delete / [q]uit
   ```
3. Wait for the user's single-letter action. Loop on invalid input.
4. **`s` (save)** — invoke the `save` skill via the Skill tool, passing the note body, the frontmatter, and an explicit note name: `"Save this as: <title>"` so the save skill's step 2 name-prompt is pre-satisfied and the interactive loop is not broken. On success:
   - Delete `<vault_root>/notes/<filename>`.
   - Remove the corresponding row from `notes/index.md`.
   On `/save` failure, leave the note untouched and surface the error.
5. **`d` (defer)** — patch the note's frontmatter: `status: deferred`, bump `updated:` to today. Move the row in `notes/index.md` from `## Pending` to `## Deferred`.
6. **`x` (delete)** — delete the file unconditionally. Remove the corresponding row from `notes/index.md`.
7. **`q` (quit)** — exit the loop. Remaining notes stay pending.
8. After the loop, print a one-line summary: `Processed N notes: X saved, Y deferred, Z deleted.`

`/save` handoff is the primary off-ramp. Defer is for notes that aren't actionable yet but may be later. Delete is for noise.

---

## Frontmatter Template

```yaml
---
type: note
title: "<one-line summary, ≤80 chars>"
topic: ""
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
source_project: "<cwd basename at capture time>"
status: pending
---
```

- `type: note` — additive value to the schema in `${CLAUDE_PLUGIN_ROOT}/_shared/frontmatter.md`. No schema change required.
- `topic` — optional free-text grouping (e.g. `"vault tooling"`, `"workflow ergonomics"`). Empty by default.
- `tags` — optional. Empty by default. Populated later by the user if useful.
- `source_project` — basename of CWD at capture time. Used by `LIST --project=…`.
- `status` — `pending` | `deferred`. New captures default to `pending`.

The body is the user's verbatim text. No headings, no metadata in the body. On MATCH-append, the separator is a blank line + `---` + blank line, then the new verbatim chunk.

---

## `notes/index.md`

Canonical template lives at `_seed/notes/index.md` (copied during `/wiki init`). Two static sections — `## Pending` and `## Deferred`. No project subgroups.

Row format:

```
- [ ] 2026-04-25 [claude-obsidian] /note process should reuse confidence threshold
- [~] 2026-04-22 [scripts] old idea, deferred — revisit Q3
```

Patch the index on every CAPTURE/PROCESS action — never re-render from scratch. Mirror the patch-in-place pattern used by `/save` and `/ingest`. The index is the single source of truth at this scale; `/wiki lint` is the safety net for drift.

---

## Examples

**Capture (NEW):**
```
user> /note inbox count missing from /wiki status
assistant> Captured to notes/2026-04-25-inbox-count-missing-from-wiki-status.md
```

**Capture (NEW, filler stripped from title):**
```
user> /note we need to check why claude-workflow is not using 'wt' for worktrees but the git cli directly
# title summarised to "claude-workflow uses git CLI instead of wt for worktrees"
# slug exceeds 40 chars; truncated at last `-` before char 40
assistant> Captured to notes/2026-04-26-claude-workflow-uses-git-cli-instead.md
```

**Capture (MATCH-append, scope unchanged):**
```
user> note this: still seeing the same flaky behaviour on macOS
assistant> Appended to notes/2026-04-22-flaky-macos-runner.md
```

**Capture (MATCH-append with title rewrite):**
```
user> /dump same issue now reproduces on Linux too
# existing note title was "flaky macOS runner"; new content broadens scope
assistant> Appended to notes/2026-04-22-flaky-macos-runner.md
# title rewritten to "flaky CI runner (macOS + Linux)", filename unchanged
```

**List, filtered:**
```
user> /note list --project=claude-obsidian
assistant>
Pending notes (2):

- [ ] 2026-04-25 [claude-obsidian] /note process should reuse confidence threshold
- [ ] 2026-04-24 [claude-obsidian] inbox count missing from /wiki status

Deferred (1):

- [~] 2026-04-12 [claude-obsidian] consider auto-tagging from CWD remote name
```

**Process:**
```
user> /note process
assistant>
[1/3] 2026-04-25 [claude-obsidian]
title: /note process should reuse confidence threshold from save
body:
> /note process should reuse confidence threshold from save

Action? [s]ave / [d]efer / [x]delete / [q]uit
user> s
# /save invoked, wiki page created, note removed from notes/
assistant> Saved as [[Confidence threshold reuse]] in wiki/concepts/. Note deleted.
```
