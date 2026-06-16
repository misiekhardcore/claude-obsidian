---
name: braindump
description: Split long-form text into atomic inbox notes. Accepts inline text or file paths. Triage later via /note process.
when_to_use: Does NOT process notes — use /note process for that.
allowed-tools: Agent Bash Read
---
# braindump

Split long-form text into atomic thoughts. Chunks land in `notes/` for later triage via `/note process`. All vault writes flow through the CAPTURE pipeline (`Skill("capture-pipeline")`). The `Read` tool is used only for non-vault input file ingestion.

## Vault I/O

[Instructions on how to interact with the vault](Skill("vault-ops")).

## Image routing

If any image paths are present: invoke `Skill("image-capture")` before parsing.

## Vault path & input parsing

Vault path: See `Skill("capture-pipeline")` §1. Abort if unconfigured: `No vault configured — run /wiki init first.`

Input: space-separated text snippets and/or file paths.
- Empty → abort: `/braindump requires text or a file path.`
- Paths: absolute (starts `/`) or vault-relative. Dirs excluded. Unsupported types → abort.
- Image paths in args → invoke `Skill("image-capture")` first.
- Unresolvable args treated as inline text (no error).

## Split — atomic-thought rubric

Atomic thought = one self-contained idea. Split when topic/claim/referent shifts. Do not split mid-argument or merge distinct claims. Preserve content verbatim; only boundaries are chosen.

Zero chunks (unexpected empty result from the reasoning step) → hard-abort, no retry: `/braindump split returned no chunks. Original text not captured.`

## CAPTURE loop

### When to dispatch agents vs. run inline

|Chunks|Input order matters?|Mode|
|-|-|-|
|1|n/a|**Inline** — run CAPTURE directly on the main thread.|
|2–4|yes (sequential argument)|**Inline** — chunks must run in order so K can MATCH-append to K-1.|
|2–4|no (independent thoughts)|**Agent fan-out** — dispatch one `agents/capture.md` per chunk in parallel.|
|5+|no|**Agent fan-out** — always parallel for 5+ chunks.|
|5+|yes|**Inline** — sequential order must be preserved; run in order.|

Order matters for numbered lists, narratives, build-on-each-other arguments. Independent observations/questions/tasks can run parallel.

### Inline CAPTURE (sequential)

For each chunk in order, re-enumerate `<vault_root>/notes/*.md` fresh (so chunk K can MATCH-append
to a note written by chunk K-1). Then:

1. MATCH/NEW per `Skill("capture-pipeline")` §4 — skip `notes/index.md` and `status: deferred`; cap at 20 most recent.
2. MATCH or NEW path per `Skill("capture-pipeline")` §4; slug via `Skill("capture-pipeline")` §3.
3. Index patch per `Skill("capture-pipeline")` §6.
4. Record filename + success/failure. On error: append to failure list, continue — never abort the loop.

### Agent fan-out (parallel)

When dispatching agents, verify CWD first:

```bash
cd "${VAULT_ROOT}" && pwd   # confirm vault root before agent fan-out
```

Dispatch one `agents/capture.md` per independent chunk. Pass each agent:
- `CHUNK` — the verbatim chunk text
- `VAULT_ROOT` — `$VAULT_ROOT`
- `SOURCE_PROJECT` — `basename(cwd)`
- `TODAY` — ISO date `YYYY-MM-DD`

Wait for all agents to complete. Collect their `Filed:` / `Appended:` / `Error:` lines.

**Note:** parallel agents cannot MATCH-append to each other's notes (they run concurrently). If two chunks would logically MATCH the same note, run them inline in order instead.

**After all agents finish:** apply a single consolidated `notes/index.md` patch. For each `Filed:` line, prepend one checkbox row under `## Pending`:
```
- [ ] YYYY-MM-DD [<source_project>] <title>
```
Agents do not patch the index; the orchestrator owns that write.

`source_project` = `basename(cwd)`. Frontmatter: note shape from `Skill("capture-pipeline")` §2, no braindump provenance.

## Confirmation output

```text
Captured N notes:            ← "note" singular when N=1
- notes/YYYY-MM-DD-<slug>.md
…
```

No NEW/MATCH labels. No diff. No reasoning.

If any chunks failed:

```text
Captured N notes:
- notes/YYYY-MM-DD-<slug>.md
…

Failed: K chunks.            ← "chunk" singular when K=1
- <one-line reason per failure>
…
```

## Examples

**Multi-thought:**

```text
user> /braindump I keep forgetting to check the lint score before PRs. Also need to revisit the hot cache size — it's been growing. And the daily skill confirmation message looks wrong in dark mode.
assistant>
Captured 3 notes:
- notes/2026-04-27-check-lint-score-before-prs.md
- notes/2026-04-27-hot-cache-size-growing.md
- notes/2026-04-27-daily-skill-confirmation-dark-mode.md
```

**Single thought (no spurious split):**

```text
user> /braindump The slug truncation rule needs to account for multi-byte unicode characters — right now it can split in the middle of a grapheme cluster, which breaks vault filenames on some filesystems.
assistant>
Captured 1 note:
- notes/2026-04-27-slug-truncation-multibyte-unicode.md
```

**File input (vault-relative):**

```text
user> /braindump retro-notes/2026-04-feature-retro.txt
# resolved as <vault_root>/retro-notes/2026-04-feature-retro.txt
assistant>
Captured N notes:
- notes/2026-04-27-…
…
```

**One chunk fails:**

```text
assistant>
Captured 2 notes:
- notes/2026-04-27-check-lint-score-before-prs.md
- notes/2026-04-27-daily-skill-confirmation-dark-mode.md

Failed: 1 chunk.
- notes/: permission denied writing 2026-04-27-hot-cache-size-growing.md
```
