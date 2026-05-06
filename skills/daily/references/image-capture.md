# /daily — Image Capture Extension

Read after `_shared/image-capture.md` when images are present in a `/daily` capture.

---

## Vision-LLM output contract

For `/daily`, the vision-LLM call must return:

- `description` — concise description of image content (≤140 chars preferred)
- `vision-slug` — ≤40 chars, slug-format; used as the attachment filename stem

---

## Bullet and embed shape

The bullet under `## Captures` uses the LLM description, with embeds indented two spaces on the next line(s):

```text
- HH:MM <description>
  ![[<YYYY-MM-DD>-<vision-slug>.png]]
  ![[<YYYY-MM-DD>-<vision-slug>-2.png]]
```

Multiple images: all embeds appear indented under the same bullet, in input order.

---

## Frontmatter

`/daily` does NOT add an `attachments:` field to frontmatter. Daily files are append-only logs, not structured knowledge objects.
