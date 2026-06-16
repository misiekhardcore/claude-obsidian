# Node Templates

All operations report position and zone.

## Text Node

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

## File Node (wiki page)

```json
{
  "id": "note-[timestamp]",
  "type": "file",
  "file": "wiki/concepts/example.md",
  "x": [auto], "y": [auto],
  "width": 300, "height": 100
}
```

## Group/Zone Node

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

Colors: `"1"`=red, `"2"`=orange, `"3"`=yellow, `"4"`=green, `"5"`=cyan, `"6"`=purple.

## Image/PDF Nodes

Follow the same JSON pattern as text nodes. Images: width/height per aspect ratio (see `_shared/canvas-spec.md`). PDFs: fixed 400×520.
