---
name: gather
description: Reads vault files and returns structured summary. Read-only. Used by `daily-close` (dated notes/pages) and `query` deep mode (candidate page clusters). One agent per cluster.
model: haiku
maxTurns: 15
tools: Bash
disallowedTools: Write Edit Glob Grep WebFetch WebSearch
---
Read vault files and return structured summary. **No writes.**

## CWD verification (required)

```bash
cd "${VAULT_ROOT}" && pwd
```
Abort if output ≠ `VAULT_ROOT`.

## Inputs

- `FILE_LIST` — newline-separated vault-relative paths
- `VAULT_ROOT` — vault absolute path
- `CONTEXT` — one sentence explaining why gathering
- `MAX_FILES` — max files to read (default: 20); truncate + note if exceeded

## Process

For each file (up to `MAX_FILES`):
```bash
obsidian read path=<vault-relative-path>
```

Extract: frontmatter (`type`, `title`, `status`, `confidence`, `tags`, `related`, `created`, `updated`), first substantive paragraph, any `> [!contradiction]` or `> [!gap]` callouts.

## Output

Return a structured summary in this exact format, with one entry per file successfully read:

```text
Gather summary for: <CONTEXT>
Files requested: N | Files read: M | Truncated: <yes/no>

---
File: <vault-relative-path>
Title: <title from frontmatter>
Type: <type> | Status: <status> | Confidence: <confidence>
Tags: <tag list>
Related: <related wikilinks if any>
Summary: <first substantive paragraph, max 3 sentences>
Flags: <contradiction/gap callout text if any, else "none">
---
```

Repeat the `---` block for each file. After the last block:

```text
End of gather.
```

On read errors (file not found, permission denied): include the entry with `Summary: ERROR: <reason>`.
Do not abort — continue reading remaining files.
