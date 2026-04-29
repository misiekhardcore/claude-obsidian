---
name: braindump
description: >
  Split a long-form text stream into atomic thoughts and file each as a
  separate inbox note — without breaking flow. Accepts inline text or a
  file path (vault-relative or absolute). Each chunk goes through the full
  CAPTURE pipeline (MATCH/NEW per chunk). Triage later via /note process.
  Triggers on: "/braindump", "brain dump this", "dump the following thoughts",
  "dump these thoughts", "braindump:", "split this into notes".
allowed-tools: Bash Read Glob Grep
---

# braindump: Long-Form → Atomic Notes

Long-form text that shouldn't interrupt flow — planning sessions, retros, design ramblings. `/braindump` splits the stream into atomic thoughts and files each through the standard CAPTURE pipeline. Chunks land in `notes/` indistinguishable from `/note` captures; triage with `/note process`.

## Vault I/O

This skill writes inbox notes by re-running the per-chunk CAPTURE flow defined in [`_shared/capture-pipeline.md`](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md). All vault writes (note files, `notes/index.md` patches) flow through the `obsidian` CLI per the pipeline contract. `Read` is retained for non-vault input file ingestion (vault-relative or absolute text/markdown paths passed as arguments).

---

## Image routing

If any image paths are present in the argument list → read `${CLAUDE_PLUGIN_ROOT}/_shared/image-capture.md` then `${CLAUDE_PLUGIN_ROOT}/skills/braindump/references/image-capture.md` before parsing input.

---

## Vault path

See [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). If no vault is configured, abort with `No vault configured — run /wiki init first.`

---

## Input parsing

Positional argument(s) — inline text and/or file paths:

1. Empty or whitespace-only → abort: `/braindump requires text or a file path.`
2. Parse input as space-separated text snippets and/or file paths.
3. For each path argument, resolve: absolute when `<arg>` starts with `/`; otherwise relative to `<vault_root>` (not CWD).
4. Path resolves to a readable text file → use file contents as body.
5. Path resolves to a readable file that is neither a supported text file nor a supported image type → abort: `Unsupported input type: <ext>. /braindump accepts text, markdown, and image inputs.`
6. Path does not resolve:
   - If `<arg>` looks like a supported image input by extension → abort: `Image not found or unreadable: <path>`
   - Otherwise → treat `<arg>` verbatim as inline text. No error.

---

## Split — atomic-thought rubric

Single LLM reasoning step (think step, not a tool call):

> **Atomic thought** = one self-contained idea, observation, question, or proposal. Think Zettelkasten: one thought per note.
>
> **Split when:** topic, claim, or referent shifts in a way that would warrant a separate note.
>
> **Do not split** mid-claim, mid-example, or mid-argument. **Do not merge** two distinct claims. **Single thought in → single chunk out.**
>
> **Preserve verbatim:** boundaries are chosen, content is unchanged.

Zero chunks (unexpected empty result from the reasoning step) → hard-abort, no retry: `/braindump split returned no chunks. Original text not captured.`

---

## CAPTURE loop

For each chunk in order, re-enumerate `<vault_root>/notes/*.md` fresh (so chunk K can MATCH-append to a note written by chunk K-1). Then:

1. MATCH/NEW per [§4](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#4-matchnew-heuristic-incl-prompt-template) — skip `notes/index.md` and `status: deferred`; cap at 20 most recent.
2. MATCH or NEW path per [§4](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#4-matchnew-heuristic-incl-prompt-template); slug via [§3](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#3-slug-rule-title-driven).
3. Index patch per [§6](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#6-index-patching-notesindexmd).
4. Record filename + success/failure. On error: append to failure list, continue — never abort the loop.

`source_project` = `basename(cwd)`. Frontmatter: note shape from [§2](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily), no braindump provenance.

---

## Confirmation output

```
Captured N notes:            ← "note" singular when N=1
- notes/YYYY-MM-DD-<slug>.md
…
```

No NEW/MATCH labels. No diff. No reasoning.

If any chunks failed:

```
Captured N notes:
- notes/YYYY-MM-DD-<slug>.md
…

Failed: K chunks.            ← "chunk" singular when K=1
- <one-line reason per failure>
…
```

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
