# Bases Dashboard Config

Create or update `wiki/meta/dashboard.base`. One file, four views over the wiki:

```yaml
filters:
  and:
    - file.inFolder("wiki/")
    - not:
        - file.inFolder("wiki/meta")

views:
  - type: table
    name: "Recent Activity"
    limit: 15
    order:
      - file.name
      - type
      - status
      - updated

  - type: list
    name: "Seed Pages (Need Development)"
    filters: 'status == "seed"'
    order:
      - file.name
      - updated

  - type: list
    name: "Entities Missing Sources"
    filters:
      and:
        - file.inFolder("wiki/entities/")
        - or:
            - "!sources"
            - "length(sources) == 0"
    order:
      - file.name

  - type: list
    name: "Open Questions"
    filters:
      and:
        - file.inFolder("wiki/questions/")
        - 'answer_quality == "draft"'
    order:
      - file.name
      - created
```

**Note on sort direction:** Bases YAML does not encode per-property sort direction in `order:`. After Obsidian renders the view, click a column header to flip ASC/DESC; the choice persists. Use `groupBy.direction:` for grouping order if needed.

**Embedding:** add `![[dashboard.base]]` (or `![[dashboard.base#Recent Activity]]` for a single view) inside any wiki page to surface the dashboard.
