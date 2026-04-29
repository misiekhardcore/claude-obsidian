---
name: daily
description: >
  Append a timestamped bullet to today's daily log in the vault. Each call
  adds one line to <vault_root>/daily/YYYY-MM-DD.md — no inbox, no triage.
  Triggers on: "/daily", "daily note this", "log to today", "log this",
  "add to today's log", "daily log:".
allowed-tools: Bash Read Glob
---

# daily: Chronological Daily Log

Append a timestamped bullet to `<vault_root>/daily/YYYY-MM-DD.md`. No MATCH/NEW decision, no inbox, no triage. Every invocation adds one bullet. Use `/note` for knowledge fragments worth triaging later; use `/daily` for time-anchored observations, progress notes, and anything that belongs to the day.

## Vault I/O

This skill creates and updates `<vault_root>/daily/YYYY-MM-DD.md`. All vault writes go through the `obsidian` CLI (`create`, `read`, `append`, `create overwrite=true` for atomic frontmatter rewrites). See `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md` for verb syntax, multiline `content=` escapes, and the `overwrite` flag.

The local `daily/` directory is filesystem state, not a vault page; create it via `mkdir -p` if missing (the CLI does not create parent directories).

---

## Vault path

See [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). If no vault is configured, abort with:

```
No vault configured — run /wiki init first.
```

---

## Operations

| User says                                                                                                              | Operation |
| ---------------------------------------------------------------------------------------------------------------------- | --------- |
| `/daily <text>`, `"daily note this …"`, `"log to today …"`, `"log this …"`, `"add to today's log …"`, `"daily log: …"` | CAPTURE   |

No LIST, no PROCESS. Daily files are an append-only log — triage and synthesis are handled by `/daily-close`.

---

## CAPTURE Operation

Steps:

1. **Extract arguments** from the user's message. Everything after the trigger phrase. Scan for image-path tokens (any token that resolves to a path or carries a supported image extension); keep them separate. Join the remaining non-path tokens as the verbatim text segment in original order with single spaces. Do not include image-path tokens in the verbatim text.

2. **Image routing.** If any image paths are present → read `${CLAUDE_PLUGIN_ROOT}/_shared/image-capture.md` then `${CLAUDE_PLUGIN_ROOT}/skills/daily/references/image-capture.md`. Use those files to determine the image-specific bullet text and attachment handling only. Then continue with steps 3–9 below for the normal daily append flow — resolve `<vault_root>`, compute date/time, ensure daily directory, probe and write the daily file via the CLI, and confirm.

3. **Resolve** `<vault_root>` per [§1](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). Abort with `No vault configured — run /wiki init first.` if unresolved.

4. **Compute** today as `YYYY-MM-DD` and current local time as `HH:MM` (24-hour, zero-padded).

5. **Ensure directory:** if `<vault_root>/daily/` does not exist, create it silently with `mkdir -p`. (Local directory creation, not a vault page op.)

6. **Probe the file:** call `obsidian read path=daily/YYYY-MM-DD.md`. Treat exit 1 with `Error: File "..." not found.` as the file-missing branch.

7. **File-missing branch:** create the file with frontmatter from [§2](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily) plus an empty `## Captures` section, plus the new bullet, in one atomic write:

   ```bash
   obsidian create \
     path=daily/YYYY-MM-DD.md \
     content="---\ntype: daily\ndate: YYYY-MM-DD\ncreated: YYYY-MM-DD\nupdated: YYYY-MM-DD\n---\n\n## Captures\n- HH:MM <verbatim text>\n"
   ```

8. **File-exists branch:** parse the file content from step 6. If the `## Captures` heading is present, append one bullet under it; if it is missing, append the heading and the bullet at EOF. Bump `updated:` in the frontmatter to today. Then write the full updated content back atomically:

   ```bash
   obsidian create \
     path=daily/YYYY-MM-DD.md \
     overwrite=true \
     content="<full updated file content with \n escapes>"
   ```

   The `overwrite` flag replaces the file in one operation; no temp-file dance is required at the skill layer (Obsidian's index stays consistent through the wrapper).

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
