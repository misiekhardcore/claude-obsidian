---
name: capture
description: Single CAPTURE-pipeline worker. Takes one chunk and files it as an atomic inbox note. Dispatched by `braindump` for parallel processing when chunks are independent.
model: haiku
maxTurns: 10
tools: Bash
---
File exactly **one** atomic inbox note into the vault. Do NOT patch `notes/index.md` — the braindump orchestrator applies a single consolidated index patch after all agents complete.

## CWD verification (required)

```bash
cd "${VAULT_ROOT}" && pwd
```
Abort if output ≠ `VAULT_ROOT`.

## Inputs

- `CHUNK` — atomic thought text
- `VAULT_ROOT` — vault absolute path
- `SOURCE_PROJECT` — `basename` for frontmatter
- `TODAY` — ISO date `YYYY-MM-DD`

## Process

1. Derive slug: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/slug.sh" "<first-8-words>"`
2. Enumerate existing notes (≤20 recent, exclude `index.md` and `status: deferred`) for MATCH per `_shared/capture-pipeline.md`.
3. **MATCH:** append to the matched filename (carry exact path from enumeration): `obsidian append file=notes/<YYYY-MM-DD-matched-slug>.md content="---\n<chunk>"`. Bump `updated:` via `obsidian frontmatter-set`.
4. **NEW:** create with frontmatter:
   ```bash
   obsidian create path=notes/${TODAY}-<slug>.md content="---
   type: note
   title: \"<first-line>\"
   created: ${TODAY}
   updated: ${TODAY}
   source_project: ${SOURCE_PROJECT}
   status: pending
   ---
   <chunk>"
   ```

## Output

One line: `Filed: notes/YYYY-MM-DD-<slug>.md [<source_project>] <title>` (NEW) or `Appended: notes/YYYY-MM-DD-<slug>.md` (MATCH) or `Error: <reason>`. No chunk/frontmatter/reasoning.
