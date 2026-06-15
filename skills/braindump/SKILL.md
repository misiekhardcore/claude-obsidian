---
name: braindump
description: Split long-form text into atomic inbox notes. Accepts inline text or file paths. Triage later via /note process.
when_to_use: "/braindump <text or file paths>". Splits text into atomic notes in notes/ inbox.
model: sonnet
effort: medium
user-invocable: true
argument-hint: "[text | filepath ...]"
allowed-tools: Agent Bash Read
---
Split long-form text into atomic inbox notes. Chunks land in `notes/` for later triage via `/note process`.

## I/O
- Input: Space-separated text snippets and/or file paths.
- Output: Atomic notes at `<vault>/notes/YYYY-MM-DD-<slug>.md`, index patch.

## Process
1. **Resolve**: Vault path per `_shared/capture-pipeline.md` §1. Abort if unconfigured.
2. **Parse**: Split input into text vs file arguments. Read files. If images present, read `_shared/image-capture.md`.
3. **Split**: Chunk input into atomic thoughts — one self-contained idea per chunk. Zero chunks → hard abort.
4. **Capture**: Delegate to `Skill("capture-pipeline")` with `CHUNKS`, `VAULT_ROOT`, `SOURCE_PROJECT`, `TODAY`, `ORDER_MATTERS`.

## Rules
- Atomic thought = one self-contained idea. Split when topic/claim/referent shifts. Do not split mid-argument.
- Preserve content verbatim. Only boundaries are chosen.
- Hard abort on zero chunks: `/braindump split returned no chunks. Original text not captured.`
