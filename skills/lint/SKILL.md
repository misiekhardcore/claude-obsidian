---
name: lint
description: >
  Health check the Obsidian wiki vault. Finds orphan pages, dead wikilinks, stale claims,
  missing cross-references, frontmatter gaps, and empty sections. Creates or updates
  Bases dashboards. Generates canvas maps. Triggers on: "lint", "health check",
  "clean up wiki", "check the wiki", "wiki maintenance", "find orphans", "wiki audit".
allowed-tools: Bash Read Glob Grep
---

# lint: Wiki Health Check

Run lint after every 10-15 ingests, or weekly. Ask before auto-fixing anything. Output a lint report to `wiki/meta/lint-report-YYYY-MM-DD.md`.

---

## Lint Checks

Use the native `obsidian` CLI verbs for efficient data gathering:
- Orphan pages: `obsidian orphans` (returns one path per line)
- Dead links: `obsidian deadends` (returns one path per line)
- Unresolved links: `obsidian unresolved format=json` (returns `[{"link": "..."}]`)
- Inbound links per page: `obsidian backlinks path=<page> format=json` (returns `[{"file": "<path>"}]`; count entries for the inbound-link count)

Work through these in order:

1. **Orphan pages**. Use `obsidian orphans` to enumerate. Wiki pages with no inbound wikilinks. They exist but nothing points to them.
2. **Dead links**. Use `obsidian deadends` to enumerate. Wikilinks that reference a page that does not exist.
3. **Stale claims**. Assertions on older pages that newer sources have contradicted or updated.
4. **Missing pages**. Concepts or entities mentioned in multiple pages but lacking their own page.
5. **Missing cross-references**. Entities mentioned in a page but not linked.
6. **Frontmatter gaps**. Pages missing required fields (type, status, created, updated, tags).
7. **Empty sections**. Headings with no content underneath.
8. **Stale index entries**. Items in `wiki/index.md` pointing to renamed or deleted pages.
9. **hot.md size budget**. Count words in `wiki/hot.md`.
   - **WARN** if word count > 500 (spec limit per `_shared/hot-cache-protocol.md`).
   - **FAIL** if word count > 750 (50 % buffer exceeded).
   - Remediation: move entries older than 2 weeks to `wiki/log.md`; trim `## Last Updated` to the 3–5 most recent items.
10. **Backlink density**. For every page under `wiki/` (skip `wiki/meta/` and `notes/`), compute the inbound count via `obsidian backlinks path=<page>` and the outbound count from the page's frontmatter `related:` length plus inline wikilinks. Flag pages where `inbound ≥ 3` **and** `outbound ≤ 1` — heavily cited but weakly linking. These pages are retrieval-late under the forward-only `related:` model, so surfacing them prompts targeted cross-linking. Compute on demand; no backlink index is persisted.
11. **Hub promotion candidates**. Group all leaves under `wiki/concepts/`, `wiki/entities/`, `wiki/solutions/`, `wiki/sources/` by their primary tag (the first non-type tag in `tags:`). For each tag-cluster of **≥ 10 leaves**, check whether `wiki/domains/<cluster-tag>/_index.md` exists. If it does not, surface the cluster as a **promotion candidate** — recommend running `/wiki promote <tag>` to scaffold a domain hub. Threshold rationale: clusters below ~10 leaves are noisy; LYT MOC heuristics put the mental-squeeze trigger around this size.
12. **Hub stale-count drift**. For every `wiki/domains/<slug>/_index.md`, compare the hub's frontmatter `page_count:` to the actual inbound count returned by `obsidian backlinks path=wiki/domains/<slug>/_index.md format=json`. Flag drift **> 20 %** (in either direction). Suggest resync — either update `page_count:` to the live count or re-curate the `related:` list to match reality.
13. **Hub demotion candidates**. For every `wiki/domains/<slug>/_index.md`, count the leaves linked from the hub's `related:` field. If **< 5**, surface the hub as a **demotion candidate** — its cluster is below the hub-worthwhile threshold and the hub may be churn rather than signal. Recommend either growing the cluster or merging the hub into a sibling.
14. **Notes inbox**. Scoped to `<vault_root>/notes/` only. Two checks:
    - **Frontmatter gaps** — flag any `notes/*.md` (excluding `notes/index.md`) missing one of: `type`, `title`, `created`, `updated`, `source_project`, `status`. The `topic` and `tags` fields are optional and never flagged.
    - **Index drift** — flag any file in `notes/` that is missing from `notes/index.md`, and any row in `notes/index.md` whose title text doesn't match any existing note's frontmatter `title:` field. Match against frontmatter `title:`, not filenames — filenames are slugs that may diverge from display titles after CAPTURE rewrites (AC4).
    - **Explicitly skip** orphan checks, dead-link checks, stale-claim checks, and contradictions for `notes/`. These are wiki-canonical concerns and inappropriate for a transient inbox.

---

## Lint Report Format

Create at `wiki/meta/lint-report-YYYY-MM-DD.md`:

```markdown
---
type: meta
title: "Lint Report YYYY-MM-DD"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [meta, lint]
status: developing
---

# Lint Report: YYYY-MM-DD

## Summary
- Pages scanned: N
- Issues found: N
- Auto-fixed: N
- Needs review: N

## Orphan Pages
- [[Page Name]]: no inbound links. Suggest: link from [[Related Page]] or delete.

## Dead Links
- [[Missing Page]]: referenced in [[Source Page]] but does not exist. Suggest: create stub or remove link.

## Missing Pages
- "concept name": mentioned in [[Page A]], [[Page B]], [[Page C]]. Suggest: create a concept page.

## Frontmatter Gaps
- [[Page Name]]: missing fields: status, tags

## Stale Claims
- [[Page Name]]: claim "X" may conflict with newer source [[Newer Source]].

## Cross-Reference Gaps
- [[Entity Name]] mentioned in [[Page A]] without a wikilink.

## Backlink Density
- [[Page Name]]: N inbound, M outbound. Heavily cited, weakly linking. Suggest: add `related:` entries on this page to its top citers, or thread it into a domain hub.

## Hub Promotion Candidates
- `<tag>`: N leaves share this tag, no `wiki/domains/<tag>/_index.md`. Suggest: `/wiki promote <tag>` to scaffold a hub.

## Hub Stale-Count Drift
- [[domains/<slug>/_index]]: `page_count: N` in frontmatter, M inbound backlinks (drift: ±X%). Suggest: update `page_count:` or re-curate `related:`.

## Hub Demotion Candidates
- [[domains/<slug>/_index]]: only N leaves linked. Below threshold (5). Suggest: grow the cluster or merge into a sibling hub.

## Hot Cache Size
- hot.md: N words (spec: 500, delta: +N). Status: OK | WARN | FAIL
  - Suggest: move entries older than 2026-XX-XX to [[log]], trim ## Last Updated to top 3–5 items.

## Notes Inbox

Scope: `notes/` only. Frontmatter gaps and index drift; no orphan/dead-link/stale checks.

### Frontmatter gaps
- `notes/<filename>.md`: missing fields: <field>, <field>

### Index drift
- File missing from index: `notes/<filename>.md` (no row in `notes/index.md`)
- Index row missing file: `notes/index.md` references "<title>" but no file resolves to it
```

---

## Naming Conventions

Enforce these during lint:

| Element | Convention | Example |
|---------|-----------|---------|
| Filenames | Title Case with spaces | `Machine Learning.md` |
| Folders | lowercase with dashes | `wiki/data-models/` |
| Tags | lowercase, hierarchical | `#domain/architecture` |
| Wikilinks | match filename exactly | `[[Machine Learning]]` |

Filenames must be unique across the vault. Wikilinks work without paths only if filenames are unique.

---

## Writing Style Check

During lint, flag pages that violate the style guide:

- Not declarative present tense ("X basically does Y" instead of "X does Y")
- Missing source citations where claims are made
- Uncertainty not flagged with `> [!gap]`
- Contradictions not flagged with `> [!contradiction]`

---

## Bases Dashboard

Create or update `wiki/meta/dashboard.base` (a Bases file — see `skills/obsidian-bases/SKILL.md` for syntax). One file, four views over the wiki:

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

---

## Canvas Map

Create or update `wiki/meta/overview.canvas` for a visual domain map. Use `wiki/index.md` as the central node:

```json
{
  "nodes": [
    {
      "id": "1",
      "type": "file",
      "file": "wiki/index.md",
      "x": 0, "y": 0,
      "width": 300, "height": 140,
      "color": "1"
    }
  ],
  "edges": []
}
```

Add one node per domain hub (`wiki/domains/<slug>/_index.md`). Connect hubs that have significant cross-references. Colors map to the CSS scheme: 1=blue, 2=purple, 3=yellow, 4=orange, 5=green, 6=red.

---

## Before Auto-Fixing

Always show the lint report first. Ask: "Should I fix these automatically, or do you want to review each one?"

Safe to auto-fix:
- Adding missing frontmatter fields with placeholder values
- Creating stub pages for missing entities
- Adding wikilinks for unlinked mentions

Needs review before fixing:
- Deleting orphan pages (they might be intentionally isolated)
- Resolving contradictions (requires human judgment)
- Merging duplicate pages

---

## After Lint

If the lint run applied any auto-fixes that modified wiki pages (new stubs, added frontmatter, added wikilinks), update `wiki/hot.md` before closing the session. Note which pages were touched under `## Recent Changes` and summarize the lint outcome under `## Last Updated`.

For the full hot-cache protocol (when to read, when to update, sub-agent discipline), see `${CLAUDE_PLUGIN_ROOT}/_shared/hot-cache-protocol.md`.

If the lint report is advisory only (no auto-fixes applied), skip the hot.md update — reports live at `wiki/meta/lint-report-*.md` and do not count as wiki content changes.
