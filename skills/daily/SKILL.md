---
name: daily
description: >
  Append a timestamped bullet to today's daily log in the vault. Each call
  adds one line to <vault_root>/daily/YYYY-MM-DD.md — no inbox, no triage.
  Triggers on: "/daily", "daily note this", "log to today", "log this",
  "add to today's log", "daily log:".
allowed-tools: Read Write Edit Glob Bash
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

1. **Extract arguments** from the user's message. Everything after the trigger phrase, parsed as text snippets and/or file paths. Detect image paths (suffix in `.png`, `.jpg`, `.jpeg`, `.webp`, `.gif`) and text snippets, preserving order.

2. **Image pre-flight.** If any image paths are present: validate per [§5 Supported image types and validation](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#5-attachment-handling-image-input--url-redirect) (abort on error), then ensure `_attachments/` per [§5 Attachment directory](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#5-attachment-handling-image-input--url-redirect).

3. **Vision-LLM processing.** If images are present, follow [§5 Vision-LLM processing](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#5-attachment-handling-image-input--url-redirect). For `/daily`: LLM output is description (concise) and vision-slug (≤40 chars, slug-format). Use description and vision-slug for the bullet.

4. **Resolve** `<vault_root>` per [§1](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution). Abort with `No vault configured — run /wiki init first.` if unresolved.

5. **Compute** today as `YYYY-MM-DD` and current local time as `HH:MM` (24-hour, zero-padded).

6. **Ensure directory:** if `<vault_root>/daily/` does not exist, create it silently.

7. **Ensure file:** if `<vault_root>/daily/YYYY-MM-DD.md` does not exist, create it per [§7 Daily page append shape](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#7-daily-page-append-shape) — frontmatter from [§2](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#2-frontmatter-schema-note--daily) plus an empty `## Captures` section.

8. **Ensure heading:** if the file exists but `## Captures` is missing, append the heading at EOF before the bullet (idempotent — never duplicate).

9. **Image attachment handling (if images present).** Move images and generate embed lines per [§5 Image-to-note naming](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#5-attachment-handling-image-input--url-redirect) and [§5 Embed syntax](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#5-attachment-handling-image-input--url-redirect) (daily shape: embed indented two spaces on the line below the bullet).

10. **Append** bullet(s) under `## Captures`:
    - Text-only: `- HH:MM <verbatim text>`
    - Image input: `- HH:MM <vision-LLM description>` followed by indented embed lines (one per image, in order):
      ```
      - HH:MM description here
        ![[YYYY-MM-DD-vision-slug.png]]
        ![[YYYY-MM-DD-vision-slug-2.png]]
      ```

11. **Bump** `updated:` in frontmatter to today.

12. **Confirm** with exactly one line:
    ```
    Logged to daily/YYYY-MM-DD.md
    ```

Do **not** print the diff, the reasoning, attachment details, or any other output. One line only.

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

**Image input:**
```
user> /daily /path/to/whiteboard-photo.jpg
# vision-LLM processes image, generates description + vision-slug
# image moved to _attachments/2026-04-27-whiteboard-photo.jpg
assistant> Logged to daily/2026-04-27.md
# resulting bullet in daily file:
# - HH:MM Whiteboard notes: architecture diagram, API design sketches
#   ![[2026-04-27-whiteboard-photo.jpg]]
```

**Text + image:**
```
user> /daily standup completed /path/to/burndown-chart.png
# vision-LLM processes text + image
assistant> Logged to daily/2026-04-27.md
# resulting bullet:
# - HH:MM Standup completed, sprint on track per chart
#   ![[2026-04-27-burndown-chart.png]]
```

**Multiple images:**
```
user> /daily /path/to/img1.png /path/to/img2.png
# one bullet with multiple embeds
assistant> Logged to daily/2026-04-27.md
# resulting bullet:
# - HH:MM Scene with two photos
#   ![[2026-04-27-scene-with-two-photos.png]]
#   ![[2026-04-27-scene-with-two-photos-2.png]]
```
