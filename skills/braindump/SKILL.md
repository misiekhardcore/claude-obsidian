---
name: braindump
description: >
  Split a long-form text stream into atomic thoughts and file each as a
  separate inbox note — without breaking flow. Accepts inline text or a
  file path (vault-relative or absolute). Each chunk goes through the full
  CAPTURE pipeline (MATCH/NEW per chunk). Triage later via /note process.
  Triggers on: "/braindump", "brain dump this", "dump the following thoughts",
  "dump these thoughts", "braindump:", "split this into notes".
allowed-tools: Read Write Edit Glob Grep Bash
---

# braindump: Long-Form → Atomic Notes

Long-form text that shouldn't interrupt flow — planning sessions, retros, design ramblings. `/braindump` splits the stream into atomic thoughts and files each through the standard CAPTURE pipeline. Chunks land in `notes/` indistinguishable from `/note` captures; triage with `/note process`.

---

## Vault path

See [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). If no vault is configured, abort with `No vault configured — run /wiki init first.`

---

## Input parsing

Positional argument(s) — inline text, file path, and/or image paths:

1. Empty or whitespace-only → abort: `/braindump requires text or a file path.`
2. Parse input as space-separated list of text snippets and/or file paths. Detect image paths (suffix in `.png`, `.jpg`, `.jpeg`, `.webp`, `.gif`), text files, and text snippets.
3. For each path argument, resolve: absolute when `<arg>` starts with `/`; otherwise relative to `<vault_root>` (not CWD).
4. Path resolves to a readable regular file:
   - Text if extension is `.md`, `.txt`, or `.markdown` **OR** first 4 KB decodes as UTF-8 → use file contents as body.
   - Image (suffix in `.png`, `.jpg`, `.jpeg`, `.webp`, `.gif`) → collect for processing (see "Split — with images" below).
   - Binary (other) → abort: `Unsupported input type: <ext>. /braindump and capture skills accept text, markdown, and image inputs.`
5. Path does not resolve and does not look like an image → treat `<arg>` verbatim as inline text. No error.
6. **Image validation (all images):** Before split/vision-LLM, validate all image paths: must exist, be readable, and have a supported extension. If any path is missing/unreadable, abort: `Image not found or unreadable: <path>`. If unsupported extension, abort: `Unsupported input type: <ext>. /braindump and capture skills accept text, markdown, and image inputs.`

---

## Split — atomic-thought rubric (with image-to-chunk assignment)

Single LLM reasoning step (think step, not a tool call):

> **Atomic thought** = one self-contained idea, observation, question, or proposal. Think Zettelkasten: one thought per note.
>
> **Split when:** topic, claim, or referent shifts in a way that would warrant a separate note.
>
> **Do not split** mid-claim, mid-example, or mid-argument. **Do not merge** two distinct claims. **Single thought in → single chunk out.**
>
> **Preserve verbatim:** boundaries are chosen, content is unchanged.
>
> **Image-to-chunk assignment** (if images present): For each image, decide which (if any) of the resulting chunks it relates to most strongly. One image assigned to at most one chunk. If no chunk relates strongly, mark image as unassigned. Return assignment map: `{image_path: chunk_index_or_null}`.

Zero chunks (unexpected empty result from the reasoning step) → hard-abort, no retry: `/braindump split returned no chunks. Original text not captured.`

---

## CAPTURE loop

For each chunk in order, re-enumerate `<vault_root>/notes/*.md` fresh (so chunk K can MATCH-append to a note written by chunk K-1). Then:

1. MATCH/NEW per [§4](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#4-matchnew-heuristic-incl-prompt-template) — skip `notes/index.md` and `status: deferred`; cap at 20 most recent.
2. MATCH or NEW path per [§4](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#4-matchnew-heuristic-incl-prompt-template); slug via [§3](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#3-slug-rule-title-driven).
3. **Image attachment handling (if images assigned to this chunk):**
   - Ensure `<vault_root>/_attachments/` exists (create silently if absent).
   - NEW path: Move images to `<vault_root>/_attachments/<note-slug>.<ext>`, `<note-slug>-2.<ext>`, etc. Add `attachments: [...]` list to frontmatter. Embed images at end of body via `![[filename]]`.
   - MATCH path: Generate new vision-LLM description (if images), append after `---` separator. Move images to `_attachments/` with existing note's slug + collision suffixes. Extend existing note's `attachments:` list.
4. Index patch per [§6](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#6-index-patching-notesindexmd).
5. Record filename + success/failure. On error: append to failure list, continue — never abort the loop.

`source_project` = `basename(cwd)`. Frontmatter: note shape from [§2](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily), no braindump provenance.

**Unassigned images:** After the main loop, if any images were marked unassigned by the split step:
- Move images to `_attachments/` under fallback slug: `<date>-braindump-unassigned-N.<ext>` (date is today, N starts at 1).
- Create one final note with body: `Unassigned images from braindump on YYYY-MM-DD`, embeds listed, `attachments:` field populated.
- Record this note in the confirmation output (see below).

---

## Confirmation output

```
Captured N notes:            ← "note" singular when N=1
- notes/YYYY-MM-DD-<slug>.md
…
```

No NEW/MATCH labels. No diff. No reasoning. Image attachments are invisible in the confirmation output (not listed separately).

If any chunks failed:

```
Captured N notes:
- notes/YYYY-MM-DD-<slug>.md
…

Failed: K chunks.            ← "chunk" singular when K=1
- <one-line reason per failure>
…
```

If unassigned images exist after the main loop, they are included in the notes count and listed in the confirmation (one entry for the unassigned-images note).

---

## Examples

**Multi-thought:**
```
user> /braindump I keep forgetting to check the lint score before PRs. Also need to revisit the hot cache size — it's been growing. And the daily skill confirmation message looks wrong in dark mode.
assistant>
Captured 3 notes:
- notes/2026-04-27-check-lint-score-before-prs.md
- notes/2026-04-27-hot-cache-size-growing.md
- notes/2026-04-27-daily-skill-confirmation-dark-mode.md
```

**Single thought (no spurious split):**
```
user> /braindump The slug truncation rule needs to account for multi-byte unicode characters — right now it can split in the middle of a grapheme cluster, which breaks vault filenames on some filesystems.
assistant>
Captured 1 note:
- notes/2026-04-27-slug-truncation-multibyte-unicode.md
```

**File input (vault-relative):**
```
user> /braindump retro-notes/2026-04-feature-retro.txt
# resolved as <vault_root>/retro-notes/2026-04-feature-retro.txt
assistant>
Captured N notes:
- notes/2026-04-27-…
…
```

**One chunk fails:**
```
assistant>
Captured 2 notes:
- notes/2026-04-27-check-lint-score-before-prs.md
- notes/2026-04-27-daily-skill-confirmation-dark-mode.md

Failed: 1 chunk.
- notes/: permission denied writing 2026-04-27-hot-cache-size-growing.md
```

**Text + images with assignment:**
```
user> /braindump We need better error messages. Also the sidebar performance has regressed lately. And here are the architecture sketches from yesterday's session. /path/to/arch-sketch.jpg /path/to/perf-graph.png
# split produces 3 chunks: "error messages", "sidebar perf", and (implicit) "sketches/graphs"
# image-to-chunk assignment: arch-sketch → chunk 3, perf-graph → chunk 2
assistant>
Captured 3 notes:
- notes/2026-04-27-better-error-messages.md
- notes/2026-04-27-sidebar-performance-regressed.md
- notes/2026-04-27-architecture-sketches-from-session.md
```

**Mixed with unassigned image:**
```
user> /braindump Three thoughts on API design. Plus this random photo. /path/to/design-idea.png /path/to/random-photo.jpg
# split produces 3 chunks; design-idea → chunk 1; random-photo → unassigned
assistant>
Captured 4 notes:
- notes/2026-04-27-api-design-thought-1.md
- notes/2026-04-27-api-design-thought-2.md
- notes/2026-04-27-api-design-thought-3.md
- notes/2026-04-27-unassigned-images-from-braindump.md
```
