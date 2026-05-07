---
name: daily
description: Append a timestamped bullet to today's daily log. One line per call.
allowed-tools: Bash Read Glob
---
# daily

Append timestamped bullet to `daily/YYYY-MM-DD.md`. No MATCH/NEW, no inbox, no triage. Use `/note` for knowledge fragments; use `/daily` for time-anchored observations and daily progress.

## Vault I/O

Uses `create-or-append` and `property:set` (see CLI docs). Local `daily/` dir created via `mkdir -p` if missing.

## Vault path

See [§1 Vault path resolution](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). If no vault is configured, abort with:

```text
No vault configured — run /wiki init first.
```

## Operations

|User says|Operation|
|-|-|
|`/daily <text>`, `"daily note this …"`, `"log to today …"`, `"log this …"`, `"add to today's log …"`, `"daily log: …"`|CAPTURE|

No LIST, no PROCESS. Daily files are an append-only log — triage and synthesis are handled by `/daily-close`.

## CAPTURE Operation

Steps:

1. **Extract arguments** from the user's message. Everything after the trigger phrase. Scan for image-path tokens (any token that resolves to a path or carries a supported image extension); keep them separate. Join the remaining non-path tokens as the verbatim text segment in original order with single spaces. Do not include image-path tokens in the verbatim text.

2. **Image routing.** If any image paths are present → read `${CLAUDE_PLUGIN_ROOT}/_shared/image-capture.md` then `${CLAUDE_PLUGIN_ROOT}/skills/daily/references/image-capture.md`. Use those files to determine the image-specific bullet text and attachment handling only. Then continue with steps 3–8 below for the normal daily append flow — resolve `<vault_root>`, compute date/time, ensure daily directory, probe and write the daily file via the CLI, and confirm.

3. **Resolve** `<vault_root>` per [§1](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). Abort with `No vault configured — run /wiki init first.` if unresolved.

4. **Compute** today as `YYYY-MM-DD` and current local time as `HH:MM` (24-hour, zero-padded).

5. **Ensure directory:** if `<vault_root>/daily/` does not exist, create it silently with `mkdir -p`. (Local directory creation, not a vault page op.)

6. **Append the bullet:** issue one `obsidian create-or-append` call. Wrapper handles both branches; model never reads/reconstructs body.

   ```bash
   obsidian create-or-append \
     file=daily/YYYY-MM-DD.md \
     template="---\ntype: daily\ndate: YYYY-MM-DD\ncreated: YYYY-MM-DD\nupdated: YYYY-MM-DD\n---\n\n## Captures\n" \
     content="- HH:MM <verbatim text>"
   ```

   The `template` argument is used only when the file is missing; when the file exists, the wrapper appends `content` and ignores `template`. See [§2 frontmatter schema](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily) for the daily template shape.

7. **Bump `updated:`** issue one `obsidian property:set` call. Obsidian updates only that property; body passes verbatim.

   ```bash
   obsidian property:set \
     name=updated \
     value=YYYY-MM-DD \
     type=date \
     path=daily/YYYY-MM-DD.md
   ```

8. **Confirm** with exactly one line:
   ```text
   Logged to daily/YYYY-MM-DD.md
   ```

One line only. No diff, no reasoning.

### Idempotency and collision rules

Per [§7](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#7-daily-page-append-shape):

- Multiple calls in the same minute land bullets with the same `HH:MM` prefix in file order — no collision handling, no counter.
- No MATCH/NEW decision runs — every call adds a new bullet.

## Frontmatter schema

See [§2 Frontmatter schema — daily shape](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily).

## Examples

**First call of the day (file does not exist):**

```text
user> /daily shipped the /note slug rewrite
# daily/2026-04-27.md created with frontmatter + ## Captures heading
assistant> Logged to daily/2026-04-27.md
```

**Subsequent call (file exists, heading present):**

```text
user> log to today: pairing session with @dana on the wiki lint refactor
# one bullet appended under ## Captures
assistant> Logged to daily/2026-04-27.md
```

**Two calls in the same minute:**

```text
user> /daily standup done
assistant> Logged to daily/2026-04-27.md

user> daily note this: retrospective rescheduled to Thursday
assistant> Logged to daily/2026-04-27.md
# both bullets share the same HH:MM prefix — acceptable
```

**No vault configured:**

```text
user> /daily fixed the flaky test
assistant> No vault configured — run /wiki init first.
```
