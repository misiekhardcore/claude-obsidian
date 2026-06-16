# Obsidian Bases Syntax

## File Format

`.base` files contain valid YAML. Root keys: `filters`, `formulas`, `properties`, `summaries`, `views`.

```yaml
filters:
  and:
    - file.hasTag("wiki")
    - 'status != "archived"'
formulas:
  age_days: "(now() - file.ctime).days.round(0)"
  status_icon: 'if(status == "mature", "✅", "🔄")'
properties:
  status:
    displayName: "Status"
  formula.age_days:
    displayName: "Age (days)"
views:
  - type: table
    name: "All Pages"
    order:
      - file.name
      - type
      - status
      - updated
      - formula.age_days
```

## Filters

Operators: `==` `!=` `>` `<` `>=` `<=`. Single string or nested objects:

```yaml
filters: 'status == "current"'                  # single
filters: { and: [...] }                          # all match
filters: { or: [...] }                           # any match
filters: { not: [...] }                          # exclude
filters: { and: [cond1, { or: [cond2, cond3] }] }   # nested
```

Common functions: `file.hasTag("x")`, `file.inFolder("path/")`, `file.hasLink("Note")`, `file.ext`, `file.name`, `file.mtime`, `file.size`, `file.ctime`, `file.tags`, `file.folder`.

## Properties

Three types:
- **Note properties** (frontmatter): `status`, `type`, `updated`, custom fields
- **File properties** (metadata): `file.name`, `file.mtime`, `file.size`, `file.ctime`, `file.tags`, `file.folder`
- **Formula properties** (computed): `formula.age_days`, custom formulas from `formulas:` block

Override display names in `properties:` block:
```yaml
formula.age_days: {displayName: "Age (days)"}
```

## View Types

- **Table**: `type: table`. Order columns, optionally group and limit.
- **Cards**: `type: cards`. Order displayed properties.
- **List**: `type: list`. Single-line display per item.

Each view has: `name`, optional `limit`, `order: [properties]`, optional `groupBy: {property, direction}`, optional view-level `filters`. Sort direction (ASC/DESC) cannot be encoded per-property in YAML; click column headers in Obsidian to toggle.

## Embedding in Notes

```markdown
![[MyBase.base]]
![[MyBase.base#View Name]]
```

## YAML Quoting Rules

- Formulas with double quotes → wrap in single quotes: `'if(done, "Yes", "No")'`
- Strings with colons or special chars → wrap in double quotes: `"Status: Active"`
- Unquoted strings with `:` break YAML parsing
