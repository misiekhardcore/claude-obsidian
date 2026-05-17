---
name: save
description: Save conversation/insight/note as structured wiki page. Updates index, log, hot cache.
allowed-tools: Bash Read
---
# save

File conversations into wiki as permanent pages. Determines note type, files it, updates index/log/hot-cache. Wiki compounds; save often.

## Vault I/O
[Instructions on how to interact with the vault](${CLAUDE_PLUGIN_ROOT}/_shared/vault-ops.md).

## Note Type Decision
Determine the best type from the conversation content:

|Type|Folder|Use when|
|-|-|-|
|synthesis|wiki/questions/|Multi-step analysis, comparison, or answer to a specific question|
|concept|wiki/concepts/|Explaining or defining an idea, pattern, or framework|
|source|wiki/sources/|Summary of external material discussed in the session|
|decision|wiki/meta/|Architectural, project, or strategic decision that was made|
|session|wiki/meta/|Full session summary: captures everything discussed|

If the user specifies a type, use that. Default to `synthesis`.

## Save Cycle
1. **Scan & Extract**: Identify valuable content; rewrite in declarative present tense (not "the user asked").
2. **Identify**: Confirm Note Title → derive `slug` via `slug.sh` → determine Type.
3. **Create**: `obsidian create path=wiki/<folder>/slug.md content="frontmatter + body"`
4. **Index**: Insert entry into `wiki/index.md` using `scripts/index-section-insert.sh` based on Type → Section mapping:
   - `concept` → `## Concepts`
   - `source` → `## Sources`
   - `decision` → `## Plans & Decisions`
   - `synthesis` → `## Questions`
5. **Log & Cache**: Prepend to `wiki/log.md` and overwrite `wiki/hot.md` (per `_shared/vault-ops.md`).

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
