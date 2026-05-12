# Frontmatter Schema

Flat YAML only. Obsidian Properties UI requires flat structure.

## Universal Fields

Every page:

```yaml
---
type: <source|entity|concept|domain|comparison|question|meta|synthesis|solution|initiative|session|reference|decision|trail>
title: "Human-Readable Title"
created: 2026-04-07
updated: 2026-04-07
tags:
  - <domain-tag>
  - <type-tag>
status: <seed|developing|mature|evergreen>
confidence: INFERRED # EXTRACTED | INFERRED | AMBIGUOUS
evidence:
  - "[[source-page]]"
related:
  - "[[Other Page]]"
sources:
  - "[[.raw/articles/source-file.md]]"
---
```

**status:** `seed` | `developing` | `current` | `mature` | `evergreen` | `superseded`
**confidence:** `EXTRACTED` | `INFERRED` | `AMBIGUOUS` (conflict)
**evidence:** always present; wikilinks required when `confidence` is `INFERRED` or `AMBIGUOUS`; may be empty for `EXTRACTED`.

See `_shared/vault-structure.md` for hub structure and semantics.

## Typed Relationship Fields

Optional; use when semantic is unambiguous. Keep `related:` for general links (graph view uses it).

Allowed fields: `supersedes`, `contradicts`, `uses`, `depends_on`, `caused`, `fixed`, `implements`. Note: `depends_on` uses underscore.

## Type-Specific Additions

### source

- `source_type:` article | video | podcast | paper | book | transcript | data
- `author:`, `date_published:` (YYYY-MM-DD), `url:`
- `source_reliability:` high | medium | low (source's trustworthiness)
- `key_claims:` list of main assertions

Note: `confidence` is always `EXTRACTED`.

### entity

- `entity_type:` person | organization | product | repository | place
- `role:`, `first_mentioned:` (wikilink)

### concept

- `complexity:` basic | intermediate | advanced
- `aliases:` alternative names

Forward-only model; pages don't declare hub membership (see `vault-structure.md`).

### comparison

- `subjects:`, `dimensions:`, `verdict:` (one-line conclusion)

### question

- `question:`, `answer_quality:` draft | solid | definitive

### trail

Autoresearch run-records (one per run, frozen; filename: `Trail: [Topic] (YYYY-MM-DD).md`).

- `topic:`, `research_run:` (YYYY-MM-DD), `synthesis:` (wikilink)
- `confidence` always `EXTRACTED`; `evidence` lists atomic notes
- Run-scoped, not edited post-emission. Lint #16 validates. Excluded from orphan check.

### domain

Hub layer (location: `wiki/domains/<slug>/_index.md`). Forward-only model; leaves don't declare membership.

- `subdomain_of:`, `page_count:`, `owns_folder:` (default false)

## Rules

- Flat YAML only (no nesting).
- Dates: `YYYY-MM-DD` strings; lists: `- item` format.
- Wikilinks in YAML quoted: `"[[Page Name]]"`.
- Update `updated` on every edit.
- New pages: include `confidence:` and `evidence:` (default `INFERRED`).
- Typed relationship fields optional; `related:` is catch-all.
