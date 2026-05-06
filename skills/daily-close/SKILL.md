---
name: daily-close
description: >
  Synthesize a day's full capture record into a polished prose summary with
  optional follow-ups, appended to the daily file. Reads the daily log,
  date-matched inbox notes, date-matched wiki pages, hot cache, and index.
  Synthesis only — does not triage or clear the inbox.
  Triggers on: "/daily-close", "close today", "wrap up today", "synthesize today".
allowed-tools: Bash Read Glob
---

# daily-close: End-of-Day Synthesis

Synthesize `<vault_root>/daily/YYYY-MM-DD.md` into a polished prose summary with optional follow-ups. Reads the day's captures, any inbox notes and wiki pages dated to that day, plus `wiki/hot.md` and `wiki/index.md` for cross-reference context. Appends a `## Summary` section (and optional `## Follow-ups`) to the daily file. Re-running replaces the prior summary — idempotent.

## Vault I/O

This skill reads the daily file, dated inbox notes, dated wiki pages, `wiki/hot.md`, and `wiki/index.md`, then writes the synthesized result back to the daily file. All operations go through the `obsidian` CLI: `read` for reads, `properties path=<file>` for date-matched frontmatter scans, and `create overwrite=true` for the atomic synthesis write. See `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md` for verb syntax, multiline `content=` escapes, and the `overwrite` flag semantics.

---

## Vault path

See [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). If no vault is configured, abort with:

```text
No vault configured — run /wiki init first.
```

---

## Steps

1. **Resolve vault** per [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). Abort with `No vault configured — run /wiki init first.` if unresolved.

2. **Parse date argument:**
   - No argument → use today's date as `YYYY-MM-DD`.
   - Argument provided → validate it matches `YYYY-MM-DD` format. Abort with `Invalid date: <arg>. Expected YYYY-MM-DD.` if not parseable.
   - Once parsed, check whether the date is in the future. Abort with `Cannot close a future date: <date>.` if future.

3. **Check daily file existence:** call `obsidian read path=daily/YYYY-MM-DD.md`. Treat exit 1 with `Error: File "..." not found.` as the file-missing branch and abort with `No daily file for YYYY-MM-DD.` (do not auto-create).

4. **Check for empty day:** Scan for content worth synthesizing:
   - Count bullets under `## Captures` in the daily file content from step 3.
   - If zero bullets, scan for date-matched activity:
     - Glob `<vault_root>/notes/*.md` and call `obsidian properties path=notes/<file>` per candidate. Match `created: YYYY-MM-DD` OR `updated: YYYY-MM-DD` AND `status: pending`.
     - Glob `<vault_root>/wiki/**/*.md` and call `obsidian properties path=wiki/<file>` per candidate. Match `created: YYYY-MM-DD` OR `updated: YYYY-MM-DD`. Exclude `wiki/hot.md` and `wiki/index.md` (they are always read in full in step 5).
   - If both zero bullets AND no matching notes or wiki pages → abort with `Nothing to synthesize for YYYY-MM-DD.` (no LLM call fired).

5. **Gather synthesis input** (frontmatter-first: bodies read only for matched files):
   - Full daily file (already read in step 3 — reuse the content).
   - Each pending note matched in step 4: `obsidian read path=notes/<file>` (frontmatter + body).
   - Each wiki page matched in step 4: `obsidian read path=wiki/<file>` (frontmatter + body).
   - `obsidian read path=wiki/hot.md` in full.
   - `obsidian read path=wiki/index.md` in full.

6. **Call LLM for synthesis** using the prompt template below. If the call fails, abort with `Synthesis failed: <reason>.` and leave the daily file unchanged.

7. **Construct the updated file content in memory:**
   - No existing `## Summary` section → append the new section after the last bullet in `## Captures`.
   - Existing `## Summary` section → remove from the `## Summary` heading through any immediately following `## Follow-ups` section, stopping at the next level-2 heading that is **not** `## Follow-ups`, or at EOF if none exists; insert the new section in its place. Idempotent.
   - Structure: `## Summary` followed by prose, then optional `## Follow-ups` with bulleted items (omit the heading and bullets entirely when no follow-ups).
   - Bump `updated:` in the frontmatter to today's date (the close-run date, even when closing a past day).

8. **Atomic write back via the CLI:**

   ```bash
   obsidian create \
     path=daily/YYYY-MM-DD.md \
     overwrite=true \
     content="<full updated file content with \n escapes>"
   ```

   The `overwrite` flag replaces the file in one operation; the wrapper keeps Obsidian's index consistent. If the call returns non-zero, abort with the wrapper's error and leave the daily file unchanged (the upstream CLI either succeeds atomically or reports an error before mutating).

9. **Confirm** with exactly one line:

   ```text
   Closed daily/YYYY-MM-DD.md (N follow-ups)
   ```

   Omit the `(N follow-ups)` suffix entirely when there are none:

   ```text
   Closed daily/YYYY-MM-DD.md
   ```

   Do **not** print the synthesis prose, the input context, the reasoning, or any other output. One line only.

---

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

---

## Failure modes

| Condition             | Abort message                                                        |
| --------------------- | -------------------------------------------------------------------- |
| No vault configured   | `No vault configured — run /wiki init first.`                        |
| Invalid date format   | `Invalid date: <arg>. Expected YYYY-MM-DD.`                          |
| Future date           | `Cannot close a future date: <date>.`                                |
| Daily file not found  | `No daily file for YYYY-MM-DD.`                                      |
| Nothing to synthesize | `Nothing to synthesize for YYYY-MM-DD.`                              |
| LLM synthesis fails   | `Synthesis failed: <reason>.` — daily file left unchanged            |
| File write fails      | filesystem error — daily file left in pre-close state (atomic write) |

---

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
