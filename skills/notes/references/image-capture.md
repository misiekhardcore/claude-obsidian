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

For the §4 MATCH/NEW decision, use the LLM-generated `description` as the `New note text` input. Do not substitute the separate `title`, `topic`, or `tags` fields into the §4 decision prompt — those are used for the note's frontmatter only. Raw image data is not used for matching.

On MATCH path: use the LLM description from the initial call as the appended body content. Do not re-invoke vision-LLM.

---

## Note body shape

The note body is the LLM-generated `description`. Embed lines appear at the end, in input order:

```text
<LLM description>

![[note-slug.png]]
![[note-slug-2.png]]
```

---

## URL detection (text-only input, no images)

When the extracted argument is a single URL and no images are present:

1. Prompt exactly once: `Detected URL: <url>. Ingest via /ingest? [y/n]`
2. Read one response only. Treat case-insensitive `y` or `yes` as consent. Treat any other response (including `n`, `no`, empty input, or arbitrary text) as "no". Do not re-prompt.
3. If consent → invoke `/ingest` with the URL. On success: `Ingested via /ingest: <wiki-page>`. Exit; do not create a note.
4. Otherwise → proceed to standard CAPTURE, treating the URL as verbatim text.

`/daily` and `/braindump` receive URLs → no prompt; captured verbatim.
