# Note Type Decision

## Type Selection

|Type|Folder|Use when|
|-|-|-|
|synthesis|wiki/questions/|Multi-step analysis, comparison, or answer to a specific question|
|concept|wiki/concepts/|Explaining or defining an idea, pattern, or framework|
|source|wiki/sources/|Summary of external material discussed in the session|
|decision|wiki/meta/|Architectural, project, or strategic decision that was made|
|session|wiki/meta/|Full session summary: captures everything discussed|

If the user specifies a type, use that. Default to `synthesis`.

## Type → Index Section Mapping

- `concept` → `## Concepts`
- `decision` → `## Plans & Decisions`
- `session` → `## Plans & Decisions`
- `source` → `## Sources`
- `synthesis` → `## Questions`

Use `scripts/index-section-insert.sh` with the mapped section heading.

## Frontmatter Template

```yaml
---
type: synthesis|concept|source|decision|session
title: "Note Title"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - relevant-tag
status: developing
related:
  - "[[Page]]"
sources:
  - "[[.raw/source.md]]"
---
```

- **Questions**: add `question: "..."` and `answer_quality: solid`.
- **Decisions**: add `decision_date: YYYY-MM-DD` and `status: active`.
- **Forward-only Hubs**: Do NOT write a `domain:` field on leaves. Hub membership is managed by the hub (`wiki/domains/slug/_index.md`).

## Writing Style

- **Declarative present tense.** "X works by Y," not "Claude explained X."
- **Self-contained.** Future sessions should read the page cold.
- **Hyperlinked.** Link every concept/entity/wiki page.

## Scope

- **Save**: Non-obvious synthesis, rationale, research findings.
- **Skip**: Mechanical Q&A, documented setup, temporary debugging. Update existing pages instead.
