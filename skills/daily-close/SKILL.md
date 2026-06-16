---
name: daily-close
description: Synthesize a day's captures into a prose summary. Idempotent; re-run replaces prior summary.
allowed-tools: Bash Agent
---
# daily-close

Synthesize `daily/YYYY-MM-DD.md` into prose summary with optional follow-ups. Reads day's captures, dated notes/wiki pages, hot.md, index.md. Appends `## Summary` (and optional `## Follow-ups`). Idempotent.

## Vault I/O

[Instructions on how to interact with the vault](Skill("vault-ops")).

## Vault path

See `Skill("capture-pipeline")` §1 for vault path resolution. If no vault is configured, abort with:

```text
No vault configured — run /wiki init first.
```

## Pipeline

1. **Resolve vault** per `Skill("capture-pipeline")` §1. Abort if unconfigured.
2. **Parse date** (no arg = today, validate `YYYY-MM-DD`, reject future dates).
3. **Read daily file** `obsidian read path=daily/YYYY-MM-DD.md`. Abort if missing (no auto-create).
4. **Scan for content**: count `## Captures` bullets. If zero, list pending notes via `obsidian files dir=notes format=json`; list wiki page candidates via `obsidian files dir=wiki format=json` (returns `{"path": "..."}` only — no frontmatter), then per candidate run `obsidian properties path=<file>` and keep only those whose `created:` or `updated:` value matches the date. Abort if nothing remains.
5. **Gather input**: if >3 matched files, dispatch `agents/gather.md` (max 20); else read each via `obsidian read path=<file>`. Always read `wiki/hot.md` and `wiki/index.md` via `obsidian read path=...`.
6. **LLM synthesis** via template below. Pass gathered content to `{{pending_notes_content_if_any}}` and `{{wiki_pages_content_if_any}}`.
7. **Update in-memory**: insert or replace `## Summary` section (idempotent); add optional `## Follow-ups` with bullets. Bump `updated:` frontmatter.
8. **Atomic write** via `obsidian create path=daily/YYYY-MM-DD.md overwrite=true content=...`
9. **Confirm**: one line only: `Closed daily/YYYY-MM-DD.md` (omit follow-up count if none).

## Prompt template (step 6)

```text
You are synthesizing a daily capture log for {{ date }}.

## Daily Captures
{{ daily_file_content }}

## Related Activity

### Pending Notes
{{ pending_notes_content_if_any }}

### Wiki Pages Updated on {{ date }}
{{ wiki_pages_content_if_any }}

## Context

### Hot Cache
{{ hot_md_content }}

### Wiki Index
{{ index_md_content }}

## Task

Write a prose summary (1–3 paragraphs) of the day's key insights, decisions, and progress. Then, optionally, add a `## Follow-ups` section with bulleted actionable items.

**Requirements:**
- Prose only in the main body; bullets only in `## Follow-ups`.
- Use Obsidian wikilinks (`[[Page title]]` or `[[wiki/path/to/page|alias]]`) to reference any pages mentioned in the input context. Only link pages that are present above; do not invent pages that don't exist.
- If there are no follow-ups, omit the `## Follow-ups` section entirely.

Output only the prose and optional section headers/bullets. Do not include the input summaries.
```

## Abort conditions

Abort if: no vault configured, invalid date, future date, daily file missing, nothing to synthesize, LLM call fails (file left unchanged), file write fails (atomic write preserves pre-close state). See the Examples section below for the exact abort messages.

## Examples

**Close today (no argument):**

```text
user> /daily-close
# Synthesizes daily/2026-04-27.md
assistant> Closed daily/2026-04-27.md (3 follow-ups)
```

**Close a past date:**

```text
user> /daily-close 2026-04-20
# Closes daily/2026-04-20.md; updated: bumped to today (2026-04-27)
assistant> Closed daily/2026-04-20.md
```

**Re-run (replaces prior summary):**

```text
user> /daily-close
# prior ## Summary section removed and replaced
assistant> Closed daily/2026-04-27.md (1 follow-up)
```

**Empty day (no captures, no related activity):**

```text
user> /daily-close 2026-04-15
assistant> Nothing to synthesize for 2026-04-15.
```

**File does not exist:**

```text
user> /daily-close 2026-03-01
assistant> No daily file for 2026-03-01.
```

**Future date:**

```text
user> /daily-close 2026-05-01
assistant> Cannot close a future date: 2026-05-01.
```

**Invalid date format:**

```text
user> /daily-close next Monday
assistant> Invalid date: next Monday. Expected YYYY-MM-DD.
```
