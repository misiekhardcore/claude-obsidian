---
name: daily
description: >
  Append a timestamped bullet to today's daily log in the vault. Each call
  adds one line to <vault_root>/daily/YYYY-MM-DD.md — no inbox, no triage.
  Triggers on: "/daily", "daily note this", "log to today", "log this",
  "add to today's log", "daily log:". Also offers /daily-close to synthesize
  a day's captures into a prose summary with optional follow-ups; triggers on:
  "/daily-close", "close today", "wrap up today", "synthesize today".
allowed-tools: Read Write Edit Bash
---

# daily: Chronological Daily Log

Append a timestamped bullet to `<vault_root>/daily/YYYY-MM-DD.md`. No MATCH/NEW decision, no inbox, no triage. Every invocation adds one bullet. Use `/note` for knowledge fragments worth triaging later; use `/daily` for time-anchored observations, progress notes, and anything that belongs to the day.

---

## Vault path

See [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). If no vault is configured, abort with:

```
No vault configured — run /wiki init first.
```

---

## Operations

| User says | Operation |
|-----------|-----------|
| `/daily <text>`, `"daily note this …"`, `"log to today …"`, `"log this …"`, `"add to today's log …"`, `"daily log: …"` | CAPTURE |
| `/daily-close`, `/daily-close YYYY-MM-DD`, `"close today"`, `"wrap up today"`, `"synthesize today"` | DAILY-CLOSE |

No LIST, no PROCESS. Daily files are an append-only log — triage and synthesis are handled by `/daily-close` (sub-issue C).

---

## CAPTURE Operation

Steps:

1. **Extract** the verbatim text from the user's message. Everything after the trigger phrase, preserved exactly — no rewriting, no summarising.
2. **Resolve** `<vault_root>` per [§1](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). Abort with `No vault configured — run /wiki init first.` if unresolved.
3. **Compute** today as `YYYY-MM-DD` and current local time as `HH:MM` (24-hour, zero-padded).
4. **Ensure directory:** if `<vault_root>/daily/` does not exist, create it silently.
5. **Ensure file:** if `<vault_root>/daily/YYYY-MM-DD.md` does not exist, create it per [§7 Daily page append shape](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#7-daily-page-append-shape) — frontmatter from [§2](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily) plus an empty `## Captures` section.
6. **Ensure heading:** if the file exists but `## Captures` is missing, append the heading at EOF before the bullet (idempotent — never duplicate).
7. **Append** one bullet under `## Captures`:
   ```
   - HH:MM <verbatim text>
   ```
8. **Bump** `updated:` in frontmatter to today.
9. **Confirm** with exactly one line:
   ```
   Logged to daily/YYYY-MM-DD.md
   ```

Do **not** print the diff, the reasoning, or any other output. One line only.

### Idempotency and collision rules

Per [§7](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#7-daily-page-append-shape):

- Multiple calls in the same minute land bullets with the same `HH:MM` prefix in file order — no collision handling, no counter.
- No MATCH/NEW decision runs — every call adds a new bullet.

---

## Frontmatter schema

See [§2 Frontmatter schema — daily shape](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily).

---

## Examples

**First call of the day (file does not exist):**
```
user> /daily shipped the /note slug rewrite
# daily/2026-04-27.md created with frontmatter + ## Captures heading
assistant> Logged to daily/2026-04-27.md
```

**Subsequent call (file exists, heading present):**
```
user> log to today: pairing session with @dana on the wiki lint refactor
# one bullet appended under ## Captures
assistant> Logged to daily/2026-04-27.md
```

**Two calls in the same minute:**
```
user> /daily standup done
assistant> Logged to daily/2026-04-27.md

user> daily note this: retrospective rescheduled to Thursday
assistant> Logged to daily/2026-04-27.md
# both bullets share the same HH:MM prefix — acceptable
```

**No vault configured:**
```
user> /daily fixed the flaky test
assistant> No vault configured — run /wiki init first.
```

---

## DAILY-CLOSE Operation

Synthesize a day's full capture record into a polished prose summary with optional follow-ups. Synthesis only — does not triage or clear the inbox.

### Steps

1. **Resolve vault** per [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). Abort with `No vault configured — run /wiki init first.` if unresolved.

2. **Parse date argument:**
   - No argument → use today's date in `YYYY-MM-DD`.
   - Argument provided → validate it is in `YYYY-MM-DD` format. Abort with `Invalid date: <arg>. Expected YYYY-MM-DD.` if not parseable.
   - Once parsed, check whether the date is in the future. Abort with `Cannot close a future date: <date>.` if future.

3. **Check daily file existence:** If `<vault_root>/daily/YYYY-MM-DD.md` does not exist, abort with `No daily file for YYYY-MM-DD.` (do not auto-create).

4. **Check for empty day:** Read the daily file and check if there is any content to synthesize:
   - Scan the file for bullets under `## Captures`. Count them.
   - If `## Captures` has zero bullets, scan for inbox and wiki activity dated to the close date:
     - List `<vault_root>/notes/*.md` and read **frontmatter only** (do not read bodies yet). Look for `created: YYYY-MM-DD` OR `updated: YYYY-MM-DD` AND `status: pending`.
     - List `<vault_root>/wiki/**/*.md` and read **frontmatter only**. Look for `created: YYYY-MM-DD` OR `updated: YYYY-MM-DD`.
   - If both `## Captures` is empty AND there are no matching notes or wiki pages, abort with `Nothing to synthesize for YYYY-MM-DD.` (do not fire an LLM call).

5. **Gather synthesis input** (frontmatter-first pattern per AC-10):
   - Read the full daily file (`daily/YYYY-MM-DD.md`, frontmatter + captures).
   - For each pending note matching the date (from step 4), read the full file (frontmatter + body).
   - For each wiki page matching the date (from step 4), read the full file (frontmatter + body).
   - Read `wiki/hot.md` in full.
   - Read `wiki/index.md` in full.
   - **Only include in LLM context files that matched the date scan in step 4; do not read irrelevant pages.**

6. **Call LLM for synthesis:** Send a prompt to synthesize the day into prose summary + optional follow-ups. The prompt must include:
   - All input from step 5.
   - Instructions to produce: one or more prose paragraphs summarizing the day's key insights, decisions, and progress; optionally a `## Follow-ups` subsection (bulleted) for actionable next steps.
   - Instructions: Use Obsidian wikilinks (`[[Page title]]` or `[[wiki/concepts/foo|short alias]]`) for any references to existing vault pages. Only link pages that appear in the input context (do not invent pages).
   - If the LLM call fails, abort with `Synthesis failed: <reason>.` and do not modify the daily file.

7. **Write synthesized section** to the daily file:
   - If the file has no `## Summary` section: append `## Summary` after the last bullet in `## Captures`, followed by the synthesis prose and optional `## Follow-ups` subsection (omit entirely if no follow-ups).
   - If the file already has a `## Summary` section: remove the prior `## Summary` section (and any `## Follow-ups` beneath it) and write the new one in its place (replace, not append). Idempotent — re-running `/daily-close` on the same day replaces the prior synthesis.

8. **Bump `updated:` frontmatter:** Update the daily file's `updated:` field to today's date (the date the close operation is run, not the date being closed). If closing a past day, `updated:` still reflects today.

9. **Confirm** with exactly one line:
   ```
   Closed daily/YYYY-MM-DD.md (N follow-ups)
   ```
   where N is the count of follow-up bullets. If there are no follow-ups, omit the `(N follow-ups)` suffix entirely:
   ```
   Closed daily/YYYY-MM-DD.md
   ```

   Do **not** print the synthesis prose, the input context, the reasoning, or any other output. One line only.

### Prompt template (for step 6)

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

### Failure modes

- **No vault:** abort with `No vault configured — run /wiki init first.`
- **Invalid date format:** abort with `Invalid date: <arg>. Expected YYYY-MM-DD.`
- **Future date:** abort with `Cannot close a future date: <date>.`
- **File not found:** abort with `No daily file for YYYY-MM-DD.`
- **Empty day:** abort with `Nothing to synthesize for YYYY-MM-DD.`
- **LLM synthesis fails:** abort with `Synthesis failed: <reason>.` Daily file left unchanged.
- **File write fails:** abort with the filesystem error. Daily file left in pre-close state (atomic write).

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
