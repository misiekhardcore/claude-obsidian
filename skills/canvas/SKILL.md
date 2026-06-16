---
name: canvas
description: Visual layer of the wiki. Add images, text cards, PDFs, and wiki pages to canvas files with zones.
allowed-tools: Bash Read Write
---
# canvas

Visual layer of the wiki. Add images, text cards, PDFs, wiki pages to infinite visual boards. Read `${CLAUDE_PLUGIN_ROOT}/_shared/canvas-spec.md` before editing canvas JSON (follows JSON Canvas 1.0 standard).

## Vault I/O

[Instructions on how to interact with the vault](Skill("vault-ops")). `Write` here is permitted only for the bypass paths (`*.canvas`, `_attachments/**`); all other vault writes must use the `obsidian` CLI via Bash (hook-enforced).

## Operations

**Reading canvas content**

To read an existing canvas for context, use the wrapper verb — it strips layout noise and emits structured plain text (groups as `##` sections, edges as a flat resolved list). Use raw JSON only for write operations (position data needed to avoid collisions).

```bash
obsidian read-canvas path=wiki/canvases/<name>.canvas
```

**Status & Create**

- **`/canvas`**: List `find wiki/canvases -name "*.canvas"`. If exactly one canvas exists, read it via `obsidian read-canvas`. If multiple, list them and ask which one. Report node counts and zone labels.
- **`/canvas new [name]`**: Slugify name, create `wiki/canvases/[slug].canvas`, append to `wiki/meta/dashboard.md`.

**Add to Canvas**

- **`add image [path|url]`**:
  - URL (starts `http`): `curl -sL [url] -o _attachments/images/canvas/[filename]`. Derive filename from URL or use `img-[timestamp].jpg`.
  - Local path outside vault: `cp [path] _attachments/images/canvas/`.
  - Already vault-relative: use as-is.
  - Detect aspect ratio via PIL or `identify`. Position via auto-layout. Report zone and position.

- **`add text [content]`**: Create text node (width 300, height 120, color 4). Position via auto-layout. Report zone and position.

- **`add pdf [path]`**: Copy to `_attachments/pdfs/canvas/` if outside vault. Fixed size 400×520. Report page count if determinable.

- **`add note [page]`**: Search `wiki/` for case-insensitive partial match. Create file node (300×100, no color). Position via auto-layout.

- **`zone [name] [color]`**: Create group node at max_y + 60 (or 280 if no nodes). Width 1000, height 400. Colors: `"1"`=red, `"2"`=orange, `"3"`=yellow, `"4"`=green, `"5"`=cyan, `"6"`=purple.

- **`list`**: `find wiki/canvases -name "*.canvas"` (via Bash). For each, read JSON and count nodes by type. Report as: `path . N nodes (X images, Y text, Z file, W group)`.

- **`from banana`**: (if banana-claude installed) Check `wiki/canvases/.recent-images.txt` first. Fallback: `find` images modified in last 10 min. Show 5 most recent if none found. Prompt user to confirm additions.

All operations report position and zone. Node templates: `references/node-templates.md`.

## Implementation Details

**Auto-positioning**: Read canvas, find target zone, collect existing nodes in zone, flow left-to-right with row wrapping. Full spec: `_shared/canvas-spec.md`.

**ID generation**: Never reuse IDs. Pattern: `[type]-[content-slug]-[unix-timestamp-10-digits]`. Examples: `img-cover-1744032823`, `text-note-1744032845`, `zone-branding-1744032901`. On collision, append `-2`, `-3`, etc.

**Images**: Detect aspect ratio via PIL or `identify`; use size table in canvas-spec.md.

**Nodes**: Always read canvas before writing. Parse JSON, append new node, write atomically. Update `wiki/index.md` for new canvases only.

## Session Log (optional hook)

If `wiki/canvases/.recent-images.txt` exists, append any new image path written to `_attachments/images/` during this session (one path per line, keep last 20).

`/canvas from banana` reads this file first, making it instant without filesystem search.

## Banana Integration (if the banana-claude plugin is installed)

After any `/banana` run in the same session, if the user says "add to canvas" or "put on canvas", treat it as `/canvas from banana`.

When `/banana` finishes generating images, suggest:

> "Add generated images to canvas? Run `/canvas from banana`"

## Summary

1. Read canvas-spec.md before editing.
2. Read canvas before writing; parse nodes to avoid collisions.
3. Create `_attachments/images/canvas/` for images.
4. Update `wiki/index.md` on new canvases.
5. Report position and zone after every add.
