---
name: canvas
description: Visual layer of the wiki. Add images, text cards, PDFs, and wiki pages to canvas files with zones.
allowed-tools: Bash Read
---
# canvas

Visual layer of the wiki. Add images, text cards, PDFs, wiki pages to infinite visual boards. Read `${CLAUDE_PLUGIN_ROOT}/_shared/canvas-spec.md` before editing canvas JSON (follows JSON Canvas 1.0 standard).

## Default Canvas

`wiki/canvases/main.canvas`

If it does not exist, create it:

```json
{
  "nodes": [
    {
      "id": "title",
      "type": "text",
      "text": "# Visual Reference\n\nDrop images, PDFs, and notes here.",
      "x": -400,
      "y": -300,
      "width": 400,
      "height": 120,
      "color": "6"
    },
    {
      "id": "zone-default",
      "type": "group",
      "label": "General",
      "x": -400,
      "y": -140,
      "width": 800,
      "height": 400,
      "color": "4"
    }
  ],
  "edges": []
}
```

## Operations

### open / status (`/canvas` with no args)

1. Check if `wiki/canvases/main.canvas` exists.
2. If yes: read it, count nodes by type, list all group node labels (zone names). Report: "Canvas has N nodes: X images, Y text cards, Z wiki pages. Zones: [list]"
3. If no: create it with the starter structure above. Report: "Created main.canvas with a General zone."
4. Tell user: "Open `wiki/canvases/main.canvas` in Obsidian to view."

### new (`/canvas new [name]`)

1. Slugify the name: lowercase, spaces → hyphens, strip special chars.
2. Create `wiki/canvases/[slug].canvas` with the starter structure, title updated to `# [Name]`.
3. Append a row to the `wiki/meta/dashboard.md` "## Canvases" section. Do not modify `wiki/index.md`. It uses a fixed section schema (Domains, Entities, Concepts, Sources, Questions, Comparisons).
4. Report: "Created wiki/canvases/[slug].canvas"

### add image (`/canvas add image [path or url]`)

**Resolve the image:**

- If URL (starts with `http`): download with `curl -sL [url] -o _attachments/images/canvas/[filename]` Derive filename from URL path, or use `img-[timestamp].jpg` if unclear.
- If local path outside vault: `cp [path] _attachments/images/canvas/`
- If already vault-relative: use as-is.

Create `_attachments/images/canvas/` if it doesn't exist.

**Detect aspect ratio with PIL or identify. See `${CLAUDE_PLUGIN_ROOT}/_shared/canvas-spec.md` for aspect-ratio → size table (single source of truth).

**Position using auto-layout** (see Auto-Positioning section below).

**Append node to canvas JSON and write.**

Report: "Added [filename] to [zone] zone at position ([x], [y])."

### add text (`/canvas add text [content]`)

Create a text node:

```json
{
  "id": "text-[timestamp]",
  "type": "text",
  "text": "[content]",
  "x": [auto], "y": [auto],
  "width": 300, "height": 120,
  "color": "4"
}
```

Position using auto-layout. Write and report.

### add pdf (`/canvas add pdf [path]`)

Same as add image. Obsidian renders PDFs natively as file nodes.

- Copy to `_attachments/pdfs/canvas/` if outside vault.
- Fixed size: width=400, height=520.
- Report page count if you can determine it.

### add note (`/canvas add note [wiki-page]`)

1. Search `wiki/` for a file matching the page name (case-insensitive, partial match ok).
2. Use the vault-relative path as the `file` field.
   - Use `"type": "file"` (not `"type": "link"`): `.md` files use file nodes, not link nodes.
   - `"type": "link"` takes a `url: "https://..."`: it is for web URLs only.
3. Create a file node: width=300, height=100.
4. Position using auto-layout.

```json
{
  "id": "note-[timestamp]",
  "type": "file",
  "file": "wiki/concepts/LLM Wiki Pattern.md",
  "x": [auto], "y": [auto],
  "width": 300, "height": 100
}
```

### zone (`/canvas zone [name] [color]`)

1. Read canvas JSON.
2. Find max_y: `max(node.y + node.height for all nodes) + 60`. Use 280 if no nodes (leaves room above the starter title node).
3. Create a group node:

```json
{
  "id": "zone-[slug]",
  "type": "group",
  "label": "[name]",
  "x": -400,
  "y": [max_y],
  "width": 1000,
  "height": 400,
  "color": "[color or '3']"
}
```

Valid colors: `"1"`=red `"2"`=orange `"3"`=yellow `"4"`=green `"5"`=cyan `"6"`=purple

Write and report.

### list (`/canvas list`)

1. `glob wiki/canvases/*.canvas`
2. For each canvas: read JSON, count nodes by type.
3. Report:

```text
wiki/canvases/main.canvas      . 14 nodes (8 images, 3 text, 2 file, 1 group)
wiki/canvases/design-ideas.canvas. 42 nodes (30 images, 4 text, 8 groups)
```

### from banana (`/canvas from banana`) (if the banana-claude plugin is installed)

1. Check `wiki/canvases/.recent-images.txt` first (session log of newly written images).
2. If not found or empty: use `find` with correct precedence (parentheses required. Without them `-newer` only binds to the last `-name` clause):
   ```bash
   python3 -c "import time,os; open('/tmp/ten-min-ago','w').close(); os.utime('/tmp/ten-min-ago',(time.time()-600,time.time()-600))"
   find _attachments/images -newer /tmp/ten-min-ago \( -name "*.png" -o -name "*.jpg" \)
   ```
   Note: `/banana` is an optional external skill not shipped in this plugin. If the user has it installed, the `.recent-images.txt` log will be populated. If not, the `find` command above is the fallback.
3. If still none: show the 5 most recently modified images.
4. Present list: "Found N recent images: [list]. Add to canvas? Which zone? (zone name / 'new [name]' / 'skip')"
5. On confirmation: add each using the add image logic.

## Auto-Positioning Algorithm

Read `${CLAUDE_PLUGIN_ROOT}/_shared/canvas-spec.md` for coordinate system and pseudocode. Implementation finds zone, collects nodes inside, flows left-to-right with row wrapping.

## ID Generation

Read the canvas, collect all existing IDs. Never reuse one.

Safe ID pattern: `[type]-[content-slug]-[full-unix-timestamp]`

Use the full Unix timestamp (10 digits) to avoid collisions in batch operations.

Examples: `img-cover-1744032823`, `text-note-1744032845`, `zone-branding-1744032901`

If a collision is detected (ID already exists in the canvas), append `-2`, `-3`, etc.

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
