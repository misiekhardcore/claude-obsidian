# Frontmatter Schema

Every wiki page starts with flat YAML frontmatter. No nested objects. Obsidian's Properties UI requires flat structure.

---

## Universal Fields

Every page, no exceptions:

```yaml
---
type: <source|entity|concept|domain|comparison|question|meta|synthesis|solution|initiative|session|reference|decision>
title: "Human-Readable Title"
created: 2026-04-07
updated: 2026-04-07
tags:
  - <domain-tag>
  - <type-tag>
status: <seed|developing|mature|evergreen>
confidence: INFERRED     # EXTRACTED | INFERRED | AMBIGUOUS
evidence:
  - "[[source-page]]"
related:
  - "[[Other Page]]"
sources:
  - "[[.raw/articles/source-file.md]]"
---
```

**status values:**
- `seed`: exists, barely populated
- `developing`: has real content, not yet complete
- `current`: complete and useful, actively maintained
- `mature`: comprehensive, well-linked, stable
- `evergreen`: structural pages always up to date by definition
- `superseded`: replaced by a newer source; preserved but no longer canonical

**confidence values (Graphify-style):**
- `EXTRACTED`: claims sourced directly from a document; deterministic (conf 1.0)
- `INFERRED`: claims derived by the LLM from sources; variable confidence
- `AMBIGUOUS`: conflicting signals present; requires human review before acting on these claims

**evidence:** flat list of wikilinks to source or concept pages that support the claims on this page. Required when `confidence` is `INFERRED` or `AMBIGUOUS`.

See `${CLAUDE_PLUGIN_ROOT}/skills/wiki/references/maintenance-rules.md` for promotion/demotion criteria. See `${CLAUDE_PLUGIN_ROOT}/_shared/vault-structure.md` for confidence tagging semantics and typed-relationship semantics.

---

## Typed Relationship Fields

All optional. Use these alongside `related:` when the semantic is unambiguous. Keep `related:` for general or untyped links (Obsidian graph view uses it).

```yaml
supersedes:
  - "[[old-page]]"       # this page replaces the listed page(s)
contradicts:
  - "[[conflicting]]"    # this page's claims conflict with the listed page(s)
uses:
  - "[[dependency]]"     # this page/concept depends on or applies the listed page(s)
depends_on:
  - "[[dep]]"            # stronger dependency — can't function without the listed page(s)
caused:
  - "[[effect]]"         # this page describes something that caused the listed outcome(s)
fixed:
  - "[[bug-page]]"       # this page describes a fix for the listed issue(s)
implements:
  - "[[spec]]"           # this page is an implementation of the listed spec/pattern(s)
```

Allowed relationship types: `supersedes`, `contradicts`, `uses`, `depends_on`, `caused`, `fixed`, `implements`.

Note: `depends_on` uses underscore (not hyphen) for idiomatic YAML key naming.

---

## Type-Specific Additions

### source

Add these fields after the universal fields:

```yaml
source_type: article    # article | video | podcast | paper | book | transcript | data
author: ""
date_published: YYYY-MM-DD
url: ""
source_reliability: high  # high | medium | low — reliability of the source itself
key_claims:
  - "First key claim from this source"
  - "Second key claim"
```

Note: `confidence` for source pages is always `EXTRACTED` (the source page summarises what was found in the document, not an inference). `source_reliability` captures how trustworthy the source itself is.

### entity

```yaml
entity_type: person     # person | organization | product | repository | place
role: ""
first_mentioned: "[[Source Title]]"
```

### concept

```yaml
complexity: intermediate  # basic | intermediate | advanced
aliases:
  - "alternative name"
  - "abbreviation"
```

Note: concept (and other leaf) pages do NOT declare hub membership via a `domain:` field. Hub membership is forward-only: hubs declare leaves via `related:`; leaves resolve to hubs via backlinks. See `vault-structure.md` Hub Membership.

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
answer_quality: solid   # draft | solid | definitive
```

### domain

Domain pages are the **hub layer** for cross-folder clusters. They live under `wiki/domains/<slug>/_index.md` and curate leaves via forward-only wikilinks. Leaves do not declare hub membership; the agent traverses leaf→hub via backlinks of `type: domain`.

```yaml
subdomain_of: ""        # leave empty for top-level domains
page_count: 0
owns_folder: false      # true | false — `true` only when the hub also owns the directory of leaves under it (rare)
```

`owns_folder:` defaults to `false` — most hubs curate leaves that live elsewhere in the vault (`concepts/`, `entities/`, `solutions/`, `sources/`).

---

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
