---
name: daily-close
description: >
  Synthesize a day's full capture record into a polished prose summary with
  optional follow-ups, appended to the daily file. Reads the daily log,
  date-matched inbox notes, date-matched wiki pages, hot cache, and index.
  Synthesis only — does not triage or clear the inbox.
  Triggers on: "/daily-close", "close today", "wrap up today", "synthesize today".
allowed-tools: Read Write Edit Glob Bash
---

# daily-close: End-of-Day Synthesis

Synthesize `<vault_root>/daily/YYYY-MM-DD.md` into a polished prose summary with optional follow-ups. Reads the day's captures, any inbox notes and wiki pages dated to that day, plus `wiki/hot.md` and `wiki/index.md` for cross-reference context. Appends a `## Summary` section (and optional `## Follow-ups`) to the daily file. Re-running replaces the prior summary — idempotent.

---

## Vault path

See [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). If no vault is configured, abort with:

```
No vault configured — run /wiki init first.
```

---

## Steps

1. **Resolve vault** per [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). Abort with `No vault configured — run /wiki init first.` if unresolved.

2. **Parse date argument:**
   - No argument → use today's date as `YYYY-MM-DD`.
   - Argument provided → validate it matches `YYYY-MM-DD` format. Abort with `Invalid date: <arg>. Expected YYYY-MM-DD.` if not parseable.
   - Once parsed, check whether the date is in the future. Abort with `Cannot close a future date: <date>.` if future.

3. **Check daily file existence:** If `<vault_root>/daily/YYYY-MM-DD.md` does not exist, abort with `No daily file for YYYY-MM-DD.` (do not auto-create).

4. **Check for empty day:** Scan for content worth synthesizing:
   - Count bullets under `## Captures` in the daily file.
   - If zero bullets, scan for date-matched activity:
     - List `<vault_root>/notes/*.md` and read **frontmatter only**. Match `created: YYYY-MM-DD` OR `updated: YYYY-MM-DD` AND `status: pending`.
     - List `<vault_root>/wiki/**/*.md` and read **frontmatter only**. Match `created: YYYY-MM-DD` OR `updated: YYYY-MM-DD`.
   - If both zero bullets AND no matching notes or wiki pages → abort with `Nothing to synthesize for YYYY-MM-DD.` (no LLM call fired).

5. **Gather synthesis input** (frontmatter-first: bodies read only for matched files):
   - Full daily file (`daily/YYYY-MM-DD.md`, frontmatter + captures).
   - Each pending note matched in step 4 (frontmatter + body).
   - Each wiki page matched in step 4 (frontmatter + body).
   - `wiki/hot.md` in full.
   - `wiki/index.md` in full.

6. **Call LLM for synthesis** using the prompt template below. If the call fails, abort with `Synthesis failed: <reason>.` and leave the daily file unchanged.

7. **Write synthesized section** to the daily file:
   - No existing `## Summary` section → append after the last bullet in `## Captures`.
   - Existing `## Summary` section → remove it (and any `## Follow-ups` beneath it) and write the new one in its place. Idempotent.
   - Structure: `## Summary` followed by prose, then `## Follow-ups` with bulleted items (omit the heading and bullets entirely when no follow-ups).

8. **Bump `updated:`** in the daily file's frontmatter to today's date (the close-run date, even when closing a past day).

9. **Confirm** with exactly one line:
   ```
   Closed daily/YYYY-MM-DD.md (N follow-ups)
   ```
   Omit the `(N follow-ups)` suffix entirely when there are none:
   ```
   Closed daily/YYYY-MM-DD.md
   ```

   Do **not** print the synthesis prose, the input context, the reasoning, or any other output. One line only.

---

## Prompt template (step 6)

```
You are synthesizing a daily capture log for {{ date }}.

## Daily Captures
{{ daily_file_content }}

## Related Activity

### Pending Notes
{{ pending_notes_content_if_any }}

### Wiki Pages Updated Today
{{ wiki_pages_content_if_any }}

## Context

### Hot Cache
{{ wiki/hot.md }}

### Wiki Index
{{ wiki/index.md }}

## Task

Write a prose summary (1–3 paragraphs) of the day's key insights, decisions, and progress. Then, optionally, add a `## Follow-ups` section with bulleted actionable items.

**Requirements:**
- Prose only in the main body; bullets only in `## Follow-ups`.
- Use Obsidian wikilinks (`[[Page title]]` or `[[wiki/path/to/page|alias]]`) to reference any pages mentioned in the input context. Only link pages that are present above; do not invent pages that don't exist.
- If there are no follow-ups, omit the `## Follow-ups` section entirely.

Output only the prose and optional section headers/bullets. Do not include the input summaries.
```

---

## Failure modes

| Condition | Abort message |
|-----------|---------------|
| No vault configured | `No vault configured — run /wiki init first.` |
| Invalid date format | `Invalid date: <arg>. Expected YYYY-MM-DD.` |
| Future date | `Cannot close a future date: <date>.` |
| Daily file not found | `No daily file for YYYY-MM-DD.` |
| Nothing to synthesize | `Nothing to synthesize for YYYY-MM-DD.` |
| LLM synthesis fails | `Synthesis failed: <reason>.` — daily file left unchanged |
| File write fails | filesystem error — daily file left in pre-close state (atomic write) |

---

## Examples

**Close today (no argument):**
```
user> /daily-close
# Synthesizes daily/2026-04-27.md
assistant> Closed daily/2026-04-27.md (3 follow-ups)
```

**Close a past date:**
```
user> /daily-close 2026-04-20
# Closes daily/2026-04-20.md; updated: bumped to today (2026-04-27)
assistant> Closed daily/2026-04-20.md
```

**Re-run (replaces prior summary):**
```
user> /daily-close
# prior ## Summary section removed and replaced
assistant> Closed daily/2026-04-27.md (1 follow-up)
```

**Empty day (no captures, no related activity):**
```
user> /daily-close 2026-04-15
assistant> Nothing to synthesize for 2026-04-15.
```

**File does not exist:**
```
user> /daily-close 2026-03-01
assistant> No daily file for 2026-03-01.
```

**Future date:**
```
user> /daily-close 2026-05-01
assistant> Cannot close a future date: 2026-05-01.
```

**Invalid date format:**
```
user> /daily-close next Monday
assistant> Invalid date: next Monday. Expected YYYY-MM-DD.
```
