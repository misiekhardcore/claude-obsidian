# Node Templates

All operations report position and zone.

### `add image [path|url]`
- URL → `curl -sL` to `_attachments/images/canvas/[filename]`
- Local path → `cp` to `_attachments/images/canvas/`
- Vault-relative → use as-is
- Detect aspect ratio via PIL or `identify`

### `add text [content]`
- Width 300, height 120, color 4
- Content is raw text

### `add pdf [path]`
- Copy to `_attachments/pdfs/canvas/` if outside vault
- Fixed size 400×520

### `add note [page]`
- Search `wiki/` for case-insensitive partial match
- File node 300×100, no color

### `zone [name] [color]`
- Group node at max_y + 60 (or 280 if empty)
- Width 1000, height 400
- Colors: `"1"`=red, `"2"`=orange, `"3"`=yellow, `"4"`=green, `"5"`=cyan, `"6"`=purple
