# /braindump — Image Capture Extension

Read after `_shared/image-capture.md` when images are present in a `/braindump` capture. Read this file **before** input parsing begins.

---

## Input parsing with images

Parse the argument list as space-separated text snippets and image paths. Collect image paths separately from text. Validate all image paths per `_shared/image-capture.md` before the split step.

If a path resolves to a readable text file (`.md`, `.txt`, `.markdown`, or first 4 KB decodes as UTF-8) → use file contents as body text. If it resolves to an image → collect for processing below. If unresolvable → treat as inline text verbatim.

---

## Combined split + image-assignment step

The text split and image-to-chunk assignment happen in a **single LLM reasoning step** (think step, not a tool call):

> Split the text into atomic thoughts (one self-contained idea, observation, question, or proposal per chunk). Simultaneously, for each image decide which chunk it relates to most strongly. One image may be assigned to at most one chunk. If no chunk relates strongly, mark the image as unassigned. Return: the split chunks in order, plus an assignment map `{image_path: chunk_index_or_null}`.

If this combined step fails due to vision processing error → abort:

```
Vision processing failed: <reason>. Image not moved, note not created.
```

Do not enter the CAPTURE loop.

Zero chunks returned → hard-abort, no retry:

```
/braindump split returned no chunks. Original text not captured.
```

---

## Attachment directory timing

Ensure `_attachments/` **once before the CAPTURE loop** — not per chunk. See `_shared/image-capture.md` for the ensure procedure.

---

## Per-chunk image handling (inside CAPTURE loop)

For each chunk:

- If images are assigned to this chunk: follow `_shared/image-capture.md` for move, naming, embed, and `attachments:` frontmatter.
- On MATCH path: generate a vision-LLM description of the assigned images and append it after the `---` separator.
- Use the chunk's note slug + collision suffix for attachment filenames.

---

## Unassigned images

After the main loop, if any images remain unassigned:

1. Move each image to `_attachments/` as `<date>-braindump-unassigned-N.<ext>` (N starts at 1).
2. Create one final note with body: `Unassigned images from braindump on YYYY-MM-DD`. Include embed lines and `attachments:` frontmatter.
3. Include this note in the confirmation count and file list.

---

## Confirmation rule

Image attachments are **invisible** in the confirmation output — do not list them separately. Only note filenames appear in the `Captured N notes:` block.
