# Image Capture — Common Mechanics

All capture skills that accept image input follow this contract. Read this file when images are present in the user's argument list. For skill-specific output contracts and integration details, also read your skill's `references/image-capture.md`.

---

## Image validation

Validate ALL image paths before any vision-LLM call or file move:

- Path exists and is a readable regular file → continue.
- Path exists but unsupported extension:
  ```text
  Unsupported input type: <ext>. /braindump and capture skills accept text, markdown, and image inputs.
  ```
- Path missing, unreadable, or not a regular file:
  ```text
  Image not found or unreadable: <path>
  ```

Abort on any error. No vision-LLM call, no file move occurs in either error case.

---

## Attachment directory

Before moving any images:

1. Resolve `<vault_root>` per [§1](${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md#1-vault-path-resolution).
2. Ensure `<vault_root>/_attachments/` exists. Create silently if absent.

For `/braindump`: ensure `_attachments/` **once before the CAPTURE loop** — not per chunk.

---

## Vision-LLM invocation

Single LLM call including all images + any text argument in the user's input.

- Do not call vision-LLM more than once per CAPTURE operation.
- On MATCH path: use the description from the initial call — do not re-invoke.

On failure:

```text
Vision processing failed: <reason>. Image not moved, note not created.
```

Never move files if vision processing fails.

---

## Attachment move and naming

Move (not copy) images from their source path to `<vault_root>/_attachments/`. Naming:

- **Note — NEW path:** `<note-slug>.<ext>` for primary image; `<note-slug>-2.<ext>`, `<note-slug>-3.<ext>`, … for additional images in the same note.
- **Note — MATCH path:** use the existing note's slug + collision suffix where N continues from the existing attachment count.
- **Daily:** `<YYYY-MM-DD>-<vision-slug>.<ext>`; collisions: `<YYYY-MM-DD>-<vision-slug>-2.<ext>`, etc.
- **Braindump unassigned:** `<date>-braindump-unassigned-N.<ext>` (N starts at 1, one per unassigned image).

---

## Embed syntax

Embed images in note body using Obsidian embed syntax:

```text
![[filename.png]]
```

- `/note` and `/braindump`: embeds appear at the end of the body, after the vision-LLM description, in input order.
- `/daily`: embed is indented two spaces on the next line within the bullet (see `daily/references/image-capture.md`).

---

## `attachments:` frontmatter field

For `/note` and `/braindump` notes: add (or extend) an `attachments:` list in frontmatter when images are present:

```yaml
attachments: ["filename1.png", "filename2.png"]
```

`/daily` does NOT include an `attachments:` field — daily files are append-only logs, not structured knowledge objects.

---

## MATCH path with images

When MATCH is decided and the input includes images:

1. Use the vision-LLM description from the initial call — do not re-invoke.
2. Append the new description after the `---` separator (per §4 MATCH shape).
3. Move images to `_attachments/` with the existing note's slug + collision indices.
4. Extend the existing `attachments:` frontmatter list with the new filenames.
5. Apply the normal MATCH title behavior: keep the existing `title:` unless the newly appended content broadens the note's scope, in which case rewrite `title:` to cover the union. A title rewrite does **not** change the existing note slug used for attachment filenames.
