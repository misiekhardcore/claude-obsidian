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

**confidence:** `EXTRACTED` (from document) | `INFERRED` (LLM-derived) | `AMBIGUOUS` (conflict present)

**evidence:** wikilinks supporting claims. Required for `INFERRED` or `AMBIGUOUS`.

See `_shared/vault-structure.md` for hub structure and semantics.

## Typed Relationship Fields

All optional. Use these alongside `related:` when the semantic is unambiguous. Keep `related:` for general or untyped links (Obsidian graph view uses it).

```yaml
supersedes:
  - "[[old-page]]" # this page replaces the listed page(s)
contradicts:
  - "[[conflicting]]" # this page's claims conflict with the listed page(s)
uses:
  - "[[dependency]]" # this page/concept depends on or applies the listed page(s)
depends_on:
  - "[[dep]]" # stronger dependency — can't function without the listed page(s)
caused:
  - "[[effect]]" # this page describes something that caused the listed outcome(s)
fixed:
  - "[[bug-page]]" # this page describes a fix for the listed issue(s)
implements:
  - "[[spec]]" # this page is an implementation of the listed spec/pattern(s)
```

Allowed: `supersedes`, `contradicts`, `uses`, `depends_on`, `caused`, `fixed`, `implements`. Note: `depends_on` uses underscore.

## Type-Specific Additions

### source

Add these fields after the universal fields:

```yaml
source_type: article # article | video | podcast | paper | book | transcript | data
author: ""
date_published: YYYY-MM-DD
url: ""
source_reliability: high # high | medium | low — reliability of the source itself
key_claims:
  - "First key claim from this source"
  - "Second key claim"
```

Note: `confidence` is always `EXTRACTED` for source pages. `source_reliability` is the source's trustworthiness.

### entity

```yaml
entity_type: person # person | organization | product | repository | place
role: ""
first_mentioned: "[[Source Title]]"
```

### concept

```yaml
complexity: intermediate # basic | intermediate | advanced
aliases:
  - "alternative name"
  - "abbreviation"
```

Note: concept pages do NOT declare hub membership; forward-only model only. See `vault-structure.md`.

### comparison

```yaml
subjects:
  - "[[Thing A]]"
  - "[[Thing B]]"
dimensions:
  - "performance"
  - "cost"
  - "ease of use"
verdict: "One-line conclusion."
```

### question

```yaml
question: "The original query as asked."
answer_quality: solid # draft | solid | definitive
```

### trail

Autoresearch run-records: atomic notes in argument order with one-line role annotations. One per run, frozen at write time. Filename: `Trail: [Topic] (YYYY-MM-DD).md` (date-suffix distinguishes multiple runs).

```yaml
topic: "<slug>"
research_run: YYYY-MM-DD
synthesis: "[[Research: Topic]]"
```

Notes: `confidence` is `EXTRACTED`. `evidence` lists atomic notes. Run-scoped; not edited post-emission. Lint #16 validates. Excluded from orphan check; dead-link findings surfaced but not auto-fixed.

### domain

Hub layer for cross-folder clusters. Location: `wiki/domains/<slug>/_index.md`. Forward-only model: leaves don't declare membership.

```yaml
subdomain_of: ""
page_count: 0
owns_folder: false
```

`owns_folder` defaults false (most hubs curate leaves elsewhere).

## Rules

1. Use flat YAML only. Never nest objects.
2. Dates as `YYYY-MM-DD` strings, not ISO datetime.
3. Lists always use the `- item` format, not inline `[a, b, c]`.
4. Wikilinks in YAML fields must be quoted: `"[[Page Name]]"`.
5. Keep `related` and `sources` as wikilinks, not plain URLs.
6. Update `updated` every time you edit the page content.
7. Every new page must include `confidence:` and `evidence:`. Default to `INFERRED` when uncertain.
8. Typed relationship fields are optional — only add them when the semantic is genuinely unambiguous.
9. `related:` remains the catch-all for links that don't fit a typed field.
