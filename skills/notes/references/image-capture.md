# /note — Image Capture Extension

Read after `_shared/image-capture.md` when images are present in a `/note` capture.

---

## Vision-LLM output contract

For `/note`, the vision-LLM call must return:
- `title` — ≤80 chars, plain text
- `topic` — subject grouping (may be empty)
- `description` — verbatim OCR content + scene description
- `tags` — array of relevant tags (may be empty)

---

## MATCH/NEW integration

Use the LLM-generated `title`, `topic`, and `tags` as the input to the MATCH/NEW heuristic (§4 of `capture-pipeline.md`). Raw image data is not used for matching.

On MATCH path: use the LLM description from the initial call as the appended body content. Do not re-invoke vision-LLM.

---

## Note body shape

The note body is the LLM-generated `description`. Embed lines appear at the end, in input order:

```
<LLM description>

![[note-slug.png]]
![[note-slug-2.png]]
```

---

## URL detection (text-only input, no images)

When the extracted argument is a single URL and no images are present:

1. Prompt exactly once: `Detected URL: <url>. Ingest via /ingest? [y/n]`
2. If `y` → invoke `/ingest` with the URL. On success: `Ingested via /ingest: <wiki-page>`. Exit; do not create a note.
3. If `n` → proceed to standard CAPTURE, treating the URL as verbatim text.

`/daily` and `/braindump` receive URLs → no prompt; captured verbatim.
