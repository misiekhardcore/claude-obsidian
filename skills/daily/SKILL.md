---
name: daily
description: >
  Append a timestamped bullet to today's daily log in the vault. Append-only
  chronological capture — no MATCH/NEW decision, no inbox triage. Fast path for
  progress notes, time-anchored observations, and in-the-moment thoughts.
  Triggers on: "/daily", "daily note this", "log to today", "log this",
  "add to today's log", "daily log:".
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
