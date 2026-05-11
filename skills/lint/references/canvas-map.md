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

Add one node per domain hub (`wiki/domains/<slug>/_index.md`). Connect hubs that have significant cross-references. Colors map to the CSS scheme: 1=blue, 2=purple, 3=yellow, 4=orange, 5=green, 6=red.
