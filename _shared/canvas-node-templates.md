# Canvas Node Templates

## Default Canvas (main.canvas)

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
  "file": "wiki/concepts/LLM Wiki Pattern.md",
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

Valid colors: `"1"`=red, `"2"`=orange, `"3"`=yellow, `"4"`=green, `"5"`=cyan, `"6"`=purple

## Image/PDF Nodes

Images/PDFs follow same pattern as text nodes. Images: width/height per aspect ratio (see `canvas-spec.md`). PDFs: fixed 400×520.
