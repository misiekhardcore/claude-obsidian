---
name: capture-pipeline
description: Protocol skill — run CAPTURE pipeline for verbatim chunks. Called from /braindump.
user-invocable: false
---
Protocol skill for capture surfaces. Handles agent vs inline decision, per-chunk MATCH/NEW, index patching. Not user-invocable; called via `Skill("capture-pipeline")`.

## I/O
- Input: `CHUNKS`, `VAULT_ROOT`, `SOURCE_PROJECT`, `TODAY`, `ORDER_MATTERS` (passed via context).
- Output: Confirmation text, `notes/index.md` patches.

## Process
1. **Decide**: Agent vs inline per decision table in `_shared/capture-pipeline.md`.
2. **Execute**: Inline → re-enumerate notes per chunk, MATCH/NEW via §4, write with §2 frontmatter, patch index per §6. Agent fan-out → verify CWD, dispatch `agents/capture.md` per chunk, collect results, single consolidated index patch.
3. **Confirm**: `Captured N notes: <paths>`. On partial failure: `Failed: K chunks: <reasons>`.

## Rules
- Parallel agents cannot MATCH-append to each other's notes (concurrent). Run inline if chunks would merge.
- Agents do not patch the index — the orchestrator owns that write.
- No NEW/MATCH labels. No diff. No reasoning in output.
