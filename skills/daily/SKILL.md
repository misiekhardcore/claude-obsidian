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

Uses `create-or-append` and `frontmatter-set` (see `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md` §3.1, §3.2). The local `daily/` directory is not a vault page; create it via `mkdir -p` if missing.

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

2. **Image routing.** If any image paths are present → read `${CLAUDE_PLUGIN_ROOT}/_shared/image-capture.md` then `${CLAUDE_PLUGIN_ROOT}/skills/daily/references/image-capture.md`. Use those files to determine the image-specific bullet text and attachment handling only. Then continue with steps 3–8 below for the normal daily append flow — resolve `<vault_root>`, compute date/time, ensure daily directory, probe and write the daily file via the CLI, and confirm.

3. **Resolve** `<vault_root>` per [§1](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). Abort with `No vault configured — run /wiki init first.` if unresolved.

4. **Compute** today as `YYYY-MM-DD` and current local time as `HH:MM` (24-hour, zero-padded).

5. **Ensure directory:** if `<vault_root>/daily/` does not exist, create it silently with `mkdir -p`. (Local directory creation, not a vault page op.)

6. **Append the bullet (atomic, branch-free):** issue exactly one `obsidian create-or-append` call. The wrapper handles both the file-missing and file-exists branches internally — the model never reads, parses, or reconstructs the file body.

   ```bash
   obsidian create-or-append \
     file=daily/YYYY-MM-DD.md \
     template="---\ntype: daily\ndate: YYYY-MM-DD\ncreated: YYYY-MM-DD\nupdated: YYYY-MM-DD\n---\n\n## Captures\n" \
     content="- HH:MM <verbatim text>"
   ```

   The `template` argument is used only when the file is missing; when the file exists, the wrapper appends `content` and ignores `template`. See [§2 frontmatter schema](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily) for the daily template shape.

7. **Bump `updated:` (idempotent):** issue one `obsidian frontmatter-set` call. The wrapper rewrites only the YAML scalar; the body — including the bullet just appended — passes through verbatim.

   ```bash
   obsidian frontmatter-set \
     path=daily/YYYY-MM-DD.md \
     key=updated \
     value=YYYY-MM-DD
   ```

8. **Confirm** with exactly one line:
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
