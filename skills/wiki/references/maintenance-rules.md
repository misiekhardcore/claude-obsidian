# Wiki Maintenance Rules

Ingest, contradiction handling, quality standards, log format. Read before ingest/autoresearch/significant operations.

Cross-skill conventions in `_shared/vault-structure.md`. Frontmatter schema in `_shared/frontmatter.md`.

## Ingest Rules

Step 1: Read full source from `.raw/`. Do not modify.

Step 2: Identify what to create/update. Per source:
1. One source page (wiki/sources/). Always new unless re-ingesting.
2. One+ concept pages (new for novel; update if adds detail/perspective/contradiction).
3. One+ entity pages (people, tools, orgs, repos appearing substantively; skip passing mentions).
4. Zero+ solution pages (only concrete recipes).

Step 3: Cross-references. Every page: ≥2 wikilinks. Source→all concepts/entities. Entities→back to source.

Step 4: Check contradictions before saving. Compare against existing pages. Follow Contradiction Handling if found.

Step 5: Update index files. Add/update entries in index.md. Log entry per Log Format. Update hot.md summary.

Minimum cross-references: sources (≥3 derived), concepts (≥2 other), entities (≥1 source + ≥1 concept/entity).

## Contradiction Handling

Exists when: new source directly conflicts (different numbers, opposite conclusions) OR supersedes prior source (newer/updated/corrected). Do NOT flag: different detail levels, complementary perspectives, additive info.

### Resolve

|Situation|Action|
|-|-|
|New source is newer/authoritative and the old claim is simply wrong|Update the existing page. Add an inline note: `> **Updated [YYYY-MM-DD]:** <new claim>. Prior claim: <old claim>. Source: [[new-source]].`|
|Both claims are defensible but come from different contexts|Add a `## Perspectives` subsection to the concept page listing both claims with their sources. Do not delete either.|
|New source supersedes old source entirely|Mark the old source page with `status: superseded` and add `superseded_by: "[[new-source]]"` to its frontmatter. Update concept pages to use the new source.|
|Contradiction requires more research to resolve|Add an `open_questions` frontmatter field listing the unresolved question. Create a page in `wiki/questions/` if the question is significant.|

Log: include `Contradictions resolved:` line in session entry.

## Quality Standards

Pages carry status field (see _shared/frontmatter.md for values).

Promotion: seed→developing (≥1 section), developing→current (major sections + cross-refs), current→mature (2nd independent source), any→superseded (newer replaces).

Demotion: mature/current→developing only if contradiction removes major section basis.

## Log Format

Every ingest/autoresearch/save/update writes one entry to wiki/log.md (prepended).

```markdown
## [YYYY-MM-DD] <operation> | <description>
- <metric>: <value> | <metric>: <value>
- Trigger: <what started session>
- Pages created: [[page1]], [[page2]]
- Pages updated: [[page3]], [[page4]]
- Contradictions resolved: <description or "none">
- Key findings: (1) <finding>; (2) <finding>
```

Fields: Date (YYYY-MM-DD), Operation (ingest/autoresearch/compound/save/query/lint), Description (source/topic), Metrics (autoresearch: Rounds/Searches/Fetches; ingest: Sources ingested), Trigger, Pages created/updated (wikilinks or "none"), Contradictions resolved, Key findings (1-5 sentences).

Example:
```markdown
## [2026-04-20] ingest | Karpathy LLM Wiki gist
- Sources ingested: 1
- Trigger: user ran `ingest llm-wiki-karpathy-gist.md`
- Pages created: [[llm-wiki-karpathy-gist]], [[LLM Wiki Pattern]], [[Andrej Karpathy]]
- Pages updated: [[index]], [[hot]], [[log]]
- Contradictions resolved: none
- Key findings: (1) pattern from 2024 gist (4.7K forks); (2) schema=product, not content; (3) hot cache saves ~84% tokens
```

Prepended (newest first). Do not edit prior except factual fixes. Superseded findings: add inline `[superseded by [[source]]]`.
