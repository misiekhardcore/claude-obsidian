---
name: obsidian-bases
description: Obsidian Bases (.base files) — dynamic tables, cards, lists, filters, formulas.
allowed-tools: Bash Read
---
# obsidian-bases

Obsidian Bases: turn vault notes into queryable views (tables, cards, lists, maps). Core feature; no plugin needed. Docs: https://help.obsidian.md/bases/syntax

## Vault I/O

This skill creates and edits `.base` files inside the vault. All reads and writes go through the `obsidian` CLI:

- Read an existing base: `obsidian read path=wiki/meta/<name>.base`
- List existing bases: `obsidian bases`
- Create a new base: `obsidian create path=wiki/meta/<name>.base content="<yaml with \n escapes>"`
- Replace an existing base: `obsidian create path=... overwrite=true content=...` (read first, modify in memory, write atomically)

See `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md` for verb syntax, multiline `content=` escapes, and the `overwrite` flag.

## File Format

`.base` files contain valid YAML. The root keys are `filters`, `formulas`, `properties`, `summaries`, and `views`.

```yaml
# Global filters: apply to ALL views
filters:
  and:
    - file.hasTag("wiki")
    - 'status != "archived"'

# Computed properties
formulas:
  age_days: "(now() - file.ctime).days.round(0)"
  status_icon: 'if(status == "mature", "✅", "🔄")'

# Display name overrides for properties panel
properties:
  status:
    displayName: "Status"
  formula.age_days:
    displayName: "Age (days)"

# One or more views
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

Filters select which notes appear (globally or per-view). Operators: `==` `!=` `>` `<` `>=` `<=`. Single string or nested objects:

```text
filters: 'status == "current"'                          # single condition
filters: { and: [...] }                                 # all must be true
filters: { or: [...] }                                  # any can be true
filters: { not: [...] }                                 # exclude matches
filters: { and: [cond1, { or: [cond2, cond3] }] }    # nested
```

Common functions: `file.hasTag("x")`, `file.inFolder("path/")`, `file.hasLink("Note")`, `file.ext`, `file.name`, `file.mtime`, `file.size`, `file.ctime`, `file.tags`, `file.folder`.

## Properties

Three types of properties:
- **Note properties** (frontmatter): `status`, `type`, `updated`, custom fields
- **File properties** (metadata): `file.name`, `file.mtime`, `file.size`, `file.ctime`, `file.tags`, `file.folder`
- **Formula properties** (computed): `formula.age_days`, custom formulas from `formulas:` section

Use `properties:` block to override display names: `formula.age_days: {displayName: "Age (days)"}`.

## Formulas

Defined in `formulas:`, referenced as `formula.name` in `order:` and `properties:`.

**Key rule**: Subtracting two dates returns a `Duration`, not a number. Always access `.days` first:
```yaml
# CORRECT
age: '(now() - file.ctime).days'

# WRONG (crashes)
age: '(now() - file.ctime).round(0)'
```

**Always guard nullable properties with `if()`**:
```yaml
days_left: 'if(due_date, (date(due_date) - today()).days, "")'
```

Examples: See [references/examples.md](${CLAUDE_PLUGIN_ROOT}/skills/obsidian-bases/references/examples.md) for common formulas (age, conditional icons, word estimates, etc.).

## View Types

- **Table**: `type: table`. Order columns, optionally group and limit.
- **Cards**: `type: cards`. Order displayed properties.
- **List**: `type: list`. Single-line display per item, ordered.

Each view has: `name`, optional `limit`, `order: [properties]`, optional `groupBy: {property, direction}`, optional view-level `filters`.

Sort direction (ASC/DESC) cannot be encoded per-property in YAML; click column headers in Obsidian to toggle.

## Wiki Vault Templates

Common patterns for wiki dashboards. See [references/examples.md](${CLAUDE_PLUGIN_ROOT}/skills/obsidian-bases/references/examples.md) for full templates:
- **Wiki content dashboard** (all non-meta pages with age formula)
- **Entity index** (people, orgs, repos grouped by entity_type)
- **Recent ingests** (sources grouped by source_type)
- **View type examples** (table, cards, list)

## Embedding in Notes

```markdown
![[MyBase.base]]

![[MyBase.base#View Name]]
```

## Where to Save

Store `.base` files in `wiki/meta/` for vault dashboards:

- `wiki/meta/dashboard.base`: main content view
- `wiki/meta/entities.base`: entity tracker
- `wiki/meta/sources.base`: ingestion log

## YAML Quoting Rules

- Formulas with double quotes → wrap in single quotes: `'if(done, "Yes", "No")'`
- Strings with colons or special chars → wrap in double quotes: `"Status: Active"`
- Unquoted strings with `:` break YAML parsing

## Do NOT

- Do not use `from:` or `where:` (Dataview syntax, not Bases)
- Do not use `sort:` at root; sort per-view via `order:` and `groupBy:`
- Do not put `.base` files outside vault
- Do not reference `formula.X` in `order:` without defining X in `formulas:`
