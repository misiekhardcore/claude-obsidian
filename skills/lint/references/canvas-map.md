# Canvas Map Config

Create or update `wiki/meta/overview.canvas` for a visual domain map. Use `wiki/index.md` as the central node:

```json
{
  "nodes": [
    {
      "id": "1",
      "type": "file",
      "file": "wiki/index.md",
      "x": 0,
      "y": 0,
      "width": 300,
      "height": 140,
      "color": "1"
    }
  ],
  "edges": []
}
```

Add one node per domain hub (`wiki/domains/<slug>/_index.md`). Connect hubs that have significant cross-references. Colors: 1=red, 2=orange, 3=yellow, 4=green, 5=cyan, 6=purple (matches `skills/canvas/references/node-templates.md`).
