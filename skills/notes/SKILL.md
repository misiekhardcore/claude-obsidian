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

See [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). Always write to `<vault_root>/notes/` regardless of CWD. If no vault is configured, abort with `No vault configured — run /wiki init first.`

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

1. **Extract arguments** from the user's message. For `/note <args>` and `/dump <args>`, parse everything after the trigger as a space-separated list of text snippets, image paths, and/or URLs. Preserve order.

2. **URL detection (text-only case).** If the extracted argument is a single URL and contains no images:
   - Prompt exactly once: `Detected URL: <url>. Ingest via /ingest? [y/n]`
   - If user responds `y`: invoke `/ingest` with the URL via the Skill tool. On success, display: `Ingested via /ingest: <wiki-page>`. Exit; do not create a note.
   - If user responds `n`: proceed to step 3 (standard CAPTURE), treating the URL as verbatim text.

3. **Image validation.** If any image paths are present, validate per [§5 Supported image types and validation](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#5-attachment-handling-image-input--url-redirect). Abort on error.

4. **Vision-LLM processing.** If images are present, follow [§5 Vision-LLM processing](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#5-attachment-handling-image-input--url-redirect). For `/note`: LLM output is title (≤80 chars), topic, description (verbatim OCR + scene), tags. Use LLM title/topic/tags for MATCH/NEW; use LLM description as note body (embeds appended at end).

5. **Extract text for MATCH/NEW.** If no images, extract the verbatim text from the user's message. For `/note <text>` and `/dump <text>`, the text is everything after the trigger. For natural-language triggers (`"note this: …"`, `"todo: …"`), extract the substring after the trigger phrase. Preserve the original wording exactly — no rewriting, no summarising. If images are present and step 4 succeeded, the "text for MATCH/NEW" is the LLM-generated description.
6. **Resolve** `<vault_root>` per [§1](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). Compute today's date as `YYYY-MM-DD`. Compute `source_project = basename(cwd)`. If `<vault_root>/notes/` does not exist, create the directory and initialise `notes/index.md` from the template at `_seed/notes/index.md`; then continue. Ensure `_attachments/` per [§5 Attachment directory](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#5-attachment-handling-image-input--url-redirect).

7. **Enumerate** existing notes and decide MATCH or NEW per [§4 MATCH/NEW heuristic](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#4-matchnew-heuristic-incl-prompt-template). Use the LLM-generated title/topic/tags (if images present) or the extracted verbatim text (text-only input) for the decision.

8. **Image attachment handling.** Follow [§5](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#5-attachment-handling-image-input--url-redirect) for naming, embed syntax, `attachments:` frontmatter, and MATCH path mechanics. On the MATCH path, use the LLM description from step 4 — do not call vision-LLM again.

9. **MATCH path** or **NEW path** — follow [§4](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#4-matchnew-heuristic-incl-prompt-template) exactly. Slug computation uses [§3 Slug rule](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#3-slug-rule-title-driven). Frontmatter shape from [§2](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily); body is verbatim text or LLM-generated description (with embeds appended if images present).

10. **Update `notes/index.md`** per [§6 Index patching](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#6-index-patching-notesindexmd).

11. **Confirm** with one terse line. Two shapes only:
   - NEW: `Captured to notes/YYYY-MM-DD-<slug>.md`
   - MATCH: `Appended to notes/YYYY-MM-DD-<slug>.md`

Do **not** print the diff, the match reasoning, the candidate list, or attachment details. Capture is a fire-and-forget action.

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

## Frontmatter schema

See [§2 Frontmatter schema — note shape](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily).

The body is the user's verbatim text. No headings, no metadata in the body. On MATCH-append, the separator is a blank line + `---` + blank line, then the new verbatim chunk.

---

## `notes/index.md`

See [§6 Index patching](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#6-index-patching-notesindexmd). Canonical template lives at `_seed/notes/index.md` (copied during `/wiki init`).

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

**URL redirect (yes):**
```
user> /note https://example.com/article
assistant> Detected URL: https://example.com/article. Ingest via /ingest? [y/n]
user> y
# /ingest invoked, wiki page created, URL processed
assistant> Ingested via /ingest: [[Article Title]]
```

**URL redirect (no):**
```
user> /note https://example.com/article
assistant> Detected URL: https://example.com/article. Ingest via /ingest? [y/n]
user> n
# standard CAPTURE proceeds, URL captured as text
assistant> Captured to notes/2026-04-27-example-article-url.md
```

**Image input (single image, new note):**
```
user> /note /path/to/screenshot.png
# vision-LLM processes image, generates title + description
# image moved to _attachments/screenshot.png
assistant> Captured to notes/2026-04-27-screenshot.md
```

**Mixed text + image:**
```
user> /note ideas from the whiteboard session /path/to/photo.jpg
# vision-LLM sees text + image, generates combined title + description
# image moved to _attachments/ideas-from-whiteboard-session.jpg
assistant> Captured to notes/2026-04-27-ideas-from-whiteboard-session.md
```

**Multi-image input:**
```
user> /note /path/to/img1.png /path/to/img2.png /path/to/img3.png
# single note created, vision-LLM sees all 3 images
# images moved to _attachments/multi-image.png, multi-image-2.png, multi-image-3.png
assistant> Captured to notes/2026-04-27-multi-image.md
```
