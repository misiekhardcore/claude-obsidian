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

`/note` is for one thought at a time. `/braindump` is for when you couldn't stop to format — planning sessions, end-of-feature retros, design ramblings. It takes the whole stream, splits it into atomic thoughts via a single LLM reasoning step, and feeds each chunk through the standard CAPTURE pipeline. The chunks land in `notes/` like any `/note` capture. Triage them later with `/note process`.

---

## Vault path

See [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). If no vault is configured, abort with:

```
No vault configured — run /wiki init first.
```

---

## Input parsing

The argument to `/braindump` is positional — either inline text or a file path. Resolution order:

1. If `<arg>` is empty or whitespace-only → abort:
   ```
   /braindump requires text or a file path.
   ```
2. Resolve as a path: absolute when `<arg>` starts with `/`; otherwise relative to `<vault_root>` (not CWD).
3. If the resolved path points to a readable regular file:
   - **Text test:** file extension is `.md`, `.txt`, or `.markdown` **OR** the first 4 KB decodes as valid UTF-8.
   - Text file → use the file's contents as the dump body.
   - Binary file → abort:
     ```
     Binary inputs not supported in /braindump — wait for sub-issue E (rich capture inputs).
     ```
4. Otherwise (path does not resolve, or looks like a path but isn't) → treat `<arg>` verbatim as inline text. No error — text-that-looks-like-a-path is valid input.

---

## Split — atomic-thought rubric

Pass the dump body to a **single LLM reasoning step** (think step, not a separate tool call) with this rubric:

> **Atomic thought** = one self-contained idea, observation, question, or proposal. Think Zettelkasten: one thought per note.
>
> **Split when:** topic, claim, or referent shifts in a way that would warrant a separate note.
>
> **Do not split:** mid-claim, mid-example, or mid-argument. Don't break a single idea into pieces just because it is long.
>
> **Do not merge:** two distinct claims or questions into one chunk, even if they share a domain.
>
> **Preserve verbatim:** boundaries are chosen, content is unchanged. Each chunk preserves the user's exact wording for that thought — no rewriting, no summarising.
>
> **Single thought in → single chunk out.** Do not introduce spurious splits.

Output: an ordered list of chunks (strings). Each chunk is a verbatim excerpt from the original dump.

**If split returns zero chunks** (unexpected empty result from the reasoning step, or the body is blank after parsing) → hard-abort immediately, no retry:
```
/braindump split returned no chunks. Original text not captured.
```
Never silently lose the dump.

---

## CAPTURE loop

For each chunk in order:

1. **Resolve vault** and enumerate `<vault_root>/notes/*.md` fresh (read frontmatter only). Candidates include notes written by earlier chunks in this same `/braindump` call — re-reading per chunk implements AC-14 (chunk K can MATCH-append to a chunk K-1 NEW note) for free.
2. **MATCH/NEW decision** per [§4 MATCH/NEW heuristic](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#4-matchnew-heuristic-incl-prompt-template). Skip `notes/index.md` and `status: deferred` notes; cap candidates at 20 most recent by `updated:`.
3. **MATCH path** or **NEW path** exactly per [§4](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#4-matchnew-heuristic-incl-prompt-template), slug via [§3](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#3-slug-rule-title-driven).
4. **Index patch** per [§6 Index patching](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#6-index-patching-notesindexmd).
5. **Record** the resulting filename and a success/failure flag in an ordered list.
6. **On per-chunk write or index error:** append to failure list, continue remaining chunks. Never abort the loop on a single failure.

`source_project` for each chunk = `basename(cwd)` at invoke time, same as `/note`.

---

## Confirmation output

After the loop completes:

```
Captured N notes:
- notes/YYYY-MM-DD-<slug>.md
- notes/YYYY-MM-DD-<slug2>.md
…
```

Use `note` (singular) when N=1, `notes` (plural) otherwise. Filenames in chunk order. No NEW/MATCH labels — silent routing principle. No diff. No reasoning.

If any chunks failed (per AC-13):

```
Captured N notes:
- notes/YYYY-MM-DD-<slug>.md
…

Failed: K chunks.
- <one-line reason for failure 1>
- <one-line reason for failure 2>
…
```

Use `chunk` (singular) when K=1, `chunks` (plural) otherwise.

---

## Frontmatter schema

Chunks use the note shape (`type: note`) per [§2 Frontmatter schema](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily). No special braindump provenance or metadata — chunks are indistinguishable from `/note` captures once filed. This means `/note process` can triage them without any special handling.

---

## Examples

**Inline text, multi-thought:**
```
user> /braindump I keep forgetting to check the lint score before PRs. Also need to revisit the hot cache size — it's been growing. And the daily skill confirmation message looks wrong in dark mode.
# Split: 3 chunks (3 distinct observations)
assistant>
Captured 3 notes:
- notes/2026-04-27-check-lint-score-before-prs.md
- notes/2026-04-27-hot-cache-size-growing.md
- notes/2026-04-27-daily-skill-confirmation-dark-mode.md
```

**Single thought (no spurious split):**
```
user> /braindump The slug truncation rule needs to account for multi-byte unicode characters — right now it can split in the middle of a grapheme cluster, which breaks vault filenames on some filesystems.
# Split: 1 chunk (single atomic idea, just long)
assistant>
Captured 1 note:
- notes/2026-04-27-slug-truncation-multibyte-unicode.md
```

**File input (vault-relative):**
```
user> /braindump retro-notes/2026-04-feature-retro.txt
# File resolved as <vault_root>/retro-notes/2026-04-feature-retro.txt
# Contents split into N chunks
assistant>
Captured N notes:
- notes/2026-04-27-…
…
```

**No vault:**
```
user> /braindump some thoughts
assistant> No vault configured — run /wiki init first.
```

**Empty body:**
```
user> /braindump
assistant> /braindump requires text or a file path.
```

**Binary file:**
```
user> /braindump _attachments/diagram.png
assistant> Binary inputs not supported in /braindump — wait for sub-issue E (rich capture inputs).
```

**One chunk fails (filesystem error):**
```
assistant>
Captured 2 notes:
- notes/2026-04-27-check-lint-score-before-prs.md
- notes/2026-04-27-daily-skill-confirmation-dark-mode.md

Failed: 1 chunk.
- notes/: permission denied writing 2026-04-27-hot-cache-size-growing.md
```
