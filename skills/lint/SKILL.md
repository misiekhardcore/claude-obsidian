---
name: lint
description: Health check the wiki vault. Finds orphans, dead wikilinks, stale claims, and frontmatter gaps. Generates canvas maps and Bases dashboards.
allowed-tools: Bash Read Glob Grep
---

# lint: Wiki Health Check

Run lint after every 10-15 ingests, or weekly. Ask before auto-fixing anything. Output a lint report to `wiki/meta/lint-report-YYYY-MM-DD.md`.

---

## Scan Scope

The deterministic scan script (`scripts/lint-scan.sh`) uses this scope. Two runs on an unchanged vault produce byte-identical JSON (excluding `scan_date`).

**Folders scanned:**
- `wiki/concepts/`, `wiki/entities/`, `wiki/sources/`, `wiki/domains/`, `wiki/comparisons/`, `wiki/questions/`, `wiki/solutions/`
- `wiki/index.md`, `wiki/log.md`, `wiki/hot.md`
- `wiki/canvases/*.canvas` — first-class; treated identically to `.md` in all 16 checks

**Folders excluded (with rationale):**
- `wiki/meta/` — administrative bookkeeping (lint reports, dashboards). Findings pointing into `wiki/meta/` from `wiki/index.md` are still validated by check #15.
- `wiki/trails/` — frozen run-snapshots; surfaced for visibility, never counted toward totals, never auto-fixed.
- `notes/` — transient inbox; only checks #14 (frontmatter gaps) and index drift apply.
- `_archive/`, `_templates/`, `.raw/` — non-wiki storage; never scanned.

**File extensions scanned for wikilinks (sources):** `.md`, `.canvas`

**File extensions valid as wikilink targets (resolver pool):** `.md`, `.canvas`, `.base`, `.png`, `.jpg`, `.jpeg`, `.svg`, `.pdf`

---

## Lint Checks

The lint agent (`agents/lint.md`) runs `scripts/lint-scan.sh` first to produce `wiki/meta/lint-data-YYYY-MM-DD.json`. Checks #1, #2, and #10 read directly from that JSON; the remaining checks use the native `obsidian` CLI verbs or page reads as noted below.

When invoking CLI verbs directly (checks #6–#9, #11–#16):
- Inbound links per page: `obsidian backlinks path=<page> format=json` (returns `[{"file": "<path>"}]`; count entries for the inbound-link count) — only needed if the JSON backlinks map is not available.
- Unresolved links: `obsidian unresolved format=json` (returns `[{"link": "..."}]`)

Work through these in order:

1. **Orphan pages**. Source: `orphans` array in `lint-data-YYYY-MM-DD.json`. Wiki pages (`.md` and `.canvas`) with no inbound wikilinks. They exist but nothing points to them. `wiki/trails/*.md` and `notes/` are already excluded from the JSON output — trails are designed-orphan (forward-only model), so they would be flagged in perpetuity.
2. **Dead links**. Source: `dead_links` array in `lint-data-YYYY-MM-DD.json`. Each entry is `{source_page, link_text}` — a wikilink in `source_page` that does not resolve to any existing page. Canvas dead links are merged into the same array; no separate handling. Findings inside `wiki/trails/*.md` are surfaced for visibility but **never auto-fixed** — trails are run-snapshots frozen at write time; the user repairs manually or accepts the drift (same policy as check #16).

    **Anti-pattern note:** URL-as-wikilink occurrences (e.g. `[[https://...]]`) are in the `anti_patterns` array of the JSON. Report these in a dedicated **Anti-patterns** section; do **not** count them toward the dead-link total.
6. **Frontmatter gaps**. Pages missing required fields (`type`, `status`, `created`, `updated`, `tags`, `confidence`). Additionally, flag missing `evidence:` when `confidence:` is `INFERRED` or `AMBIGUOUS` (per `_shared/frontmatter.md` rule 7 — `evidence:` is required for those confidence levels).
7. **Empty sections**. Headings with no content underneath.
8. **Stale index entries**. Items in `wiki/index.md` pointing to renamed or deleted pages.
9. **hot.md size budget**. Count words in `wiki/hot.md`.
   - **WARN** if word count > 500 (spec limit per `_shared/hot-cache-protocol.md`).
   - **FAIL** if word count > 750 (50 % buffer exceeded).
   - Remediation: move entries older than 2 weeks to `wiki/log.md`; trim `## Last Updated` to the 3–5 most recent items.
10. **Backlink density**. Source: `backlinks` map in `lint-data-YYYY-MM-DD.json` (pre-computed by `lint-scan.sh`; do **not** call `obsidian backlinks` per page). For every in-scope page (`.md` and `.canvas`, per the scope definition above), use the precomputed inbound count and compare against the outbound count from the page's frontmatter `related:` length plus inline wikilinks. Flag pages where `inbound ≥ 3` **and** `outbound ≤ 1` — heavily cited but weakly linking. These pages are retrieval-late under the forward-only `related:` model, so surfacing them prompts targeted cross-linking.
11. **Hub promotion candidates**. Group all leaves under `wiki/concepts/`, `wiki/entities/`, `wiki/solutions/`, `wiki/sources/` by their primary tag (the first non-type tag in `tags:`). For each tag-cluster of **≥ 10 leaves**, check whether `wiki/domains/<cluster-tag>/_index.md` exists. If it does not, surface the cluster as a **promotion candidate** — recommend running `/wiki promote <tag>` to scaffold a domain hub. Threshold rationale: clusters below ~10 leaves are noisy; LYT MOC heuristics put the mental-squeeze trigger around this size.
12. **Hub stale-count drift**. For every `wiki/domains/<slug>/_index.md`, compare the hub's frontmatter `page_count:` to the actual inbound count returned by `obsidian backlinks path=wiki/domains/<slug>/_index.md format=json`. Flag drift **> 20 %** (in either direction). Suggest resync — either update `page_count:` to the live count or re-curate the `related:` list to match reality.
13. **Hub demotion candidates**. For every `wiki/domains/<slug>/_index.md`, count the leaves linked from the hub's `related:` field. If **< 5**, surface the hub as a **demotion candidate** — its cluster is below the hub-worthwhile threshold and the hub may be churn rather than signal. Recommend either growing the cluster or merging the hub into a sibling.
14. **Notes inbox**. Scoped to `<vault_root>/notes/` only. Two checks:
    - **Frontmatter gaps** — flag any `notes/*.md` (excluding `notes/index.md`) missing one of: `type`, `title`, `created`, `updated`, `source_project`, `status`. The `topic` and `tags` fields are optional and never flagged.
    - **Index drift** — flag any file in `notes/` that is missing from `notes/index.md`, and any row in `notes/index.md` whose title text doesn't match any existing note's frontmatter `title:` field. Match against frontmatter `title:`, not filenames — filenames are slugs that may diverge from display titles after CAPTURE rewrites (AC4).
    - **Explicitly skip** orphan checks, dead-link checks, stale-claim checks, and contradictions for `notes/`. These are wiki-canonical concerns and inappropriate for a transient inbox.
15. **Misplaced index entries**. For every wikilink in `wiki/index.md`, verify the entry sits under the section matching its target's `type:` frontmatter. Read each linked target via `obsidian read path=<target>` to extract its `type:`, then determine which `## <Section>` heading the entry currently sits under (the nearest preceding H2 in `wiki/index.md`).

    Map `type:` → expected section using this fixed table:

    | `type:` | Expected section |
    |---|---|
    | concept | `## Concepts` |
    | source | `## Sources` |
    | synthesis | `## Plans & Decisions` (or `## Synthesis` if separate) |
    | decision | `## Plans & Decisions` |
    | meta | (no section — sits in the Navigation row, not in the body) |
    | domain | `## Domains` |

    Types not listed above are skipped (no flag) — extend the table when a new type acquires a canonical section.

    - **Strays** — entries with no preceding H2 (above the first heading) flag as `entry above all sections, expected under <Section>`.
    - **Misplacements** — entries under a non-matching section flag as `entry under <Current> but type=<X> expects <Expected>`.

    Role: **safety net**, not the primary placement mechanism. `/save` writes new entries directly under the correct section (see #84), so a healthy vault reports zero findings here. Findings indicate drift — manual edits, pre-fix history, or an agent that picked the wrong section despite the corrected `/save` snippet. Auto-fix policy is **ask-first** (see Before Auto-Fixing).

16. **Trail integrity**. Scoped to `wiki/trails/*.md`. Trails are run-records emitted by `/autoresearch` and frozen at write time, so integrity checks run against a fixed shape. For each trail page:
    - **Required trail-specific frontmatter** — flag missing `topic:`, `research_run:`, or `synthesis:`. The universal fields (`type`, `title`, `created`, `updated`, `tags`, `status`, `confidence`, plus `evidence` when `confidence` is `INFERRED`/`AMBIGUOUS`) are check #6's responsibility — do not duplicate.
    - **Synthesis link resolves** — the `synthesis:` value is a wikilink-by-title (e.g. `[[Research: Topic]]`), not a vault-relative path, so `read path=` is not the right resolver. Instead, run `obsidian unresolved format=json` once per lint pass and check whether the stripped link text appears in the returned `[{"link": "..."}]` array. Membership in that array means the link is dead — flag `synthesis: [[Research: X]] does not resolve`.
    - **Body is an ordered list** — the trail body (everything below the first H1, excluding a single optional intro paragraph) must be exactly one ordered Markdown list (`1. …`, `2. …`, …). Flag `body is not an ordered list` for trails whose body has no ordered list, multiple top-level lists, prose paragraphs interleaved with list items, or nested lists.
    - **Every list item contains a wikilink and a plain-text annotation** — for each ordered-list item, flag the item if it has zero `[[wikilink]]`s, more than one `[[wikilink]]`, no annotation text after stripping the wikilink (the residue must contain at least one non-whitespace, non-punctuation character), or if the annotation text contains a URL (`https?://` or a Markdown link `[text](url)`) or an additional `[[wikilink]]` — annotation text must be plain text (inline formatting like bold/italic is permitted; links are not).
    - **No minimum link count.** A one-step trail is valid output and must not be flagged.

    Auto-fix policy: **never auto-fix**. Trails are run-snapshots; rewriting them post-emission destroys the run-record property. Findings here are advisory — the user repairs the trail manually or accepts the drift.

---

## Manual Review

The following checks require entity-extraction or semantic contradiction detection that cannot be automated without NLP infrastructure. They are not run by the lint agent. Perform them as a periodic human review (suggested: monthly, or after a burst of ingests from a new domain).

- **Stale claims.** Look for assertions on older pages that newer sources may have contradicted or updated. Focus on pages with `confidence: INFERRED` or `AMBIGUOUS` and compare their claims against recently ingested sources in the same domain.
- **Missing pages.** Look for concepts or entities mentioned in three or more pages that lack their own wiki page. Use the hot cache and index as a starting point; search for recurring noun phrases that have no `[[wikilink]]` target.
- **Missing cross-references.** Look for entity names mentioned in page prose without a `[[wikilink]]`. Focus on high-traffic entities visible in the backlink density report (check #10).

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

## Frontmatter Gaps
- [[Page Name]]: missing fields: status, tags

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

## Misplaced Index Entries
- `[[<slug>]]`: under `<Current>`, expected `<Expected>` (type=<x>). Suggest: move under `<Expected>`.
- `[[<slug>]]`: above all sections (stray). Suggest: move under `<Expected>`.

## Trail Integrity

Scope: `wiki/trails/*.md`. Run-record snapshots; never auto-fixed.

- `[[Trail: Topic (YYYY-MM-DD)]]`: missing trail frontmatter: <field>, <field>
- `[[Trail: Topic (YYYY-MM-DD)]]`: synthesis link `[[Research: Topic]]` does not resolve.
- `[[Trail: Topic (YYYY-MM-DD)]]`: body is not an ordered list (found: <prose paragraph | nested list | multiple top-level lists | no list>).
- `[[Trail: Topic (YYYY-MM-DD)]]`: step N has <no wikilink | multiple wikilinks | no annotation | URL in annotation | extra wikilink in annotation>.

## Anti-patterns

Source: `anti_patterns` array from `wiki/meta/lint-data-YYYY-MM-DD.json`.
Not counted toward dead-link total. Each entry is `[[https://...]]` used as a wikilink.

- `[[Source Page]]`: URL-as-wikilink `[[https://example.com]]`. Suggest: convert to a plain `[text](url)` Markdown link.
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
- Moving misplaced index entries (check #15). Rationale: low expected volume in a healthy vault makes batch auto-move offer little value over per-entry confirmation, and a misclassification (e.g., a concept intentionally filed under a different section) is harder to undo than to confirm.

Never auto-fix:
- Trail integrity findings (check #16). Trails are frozen-at-write-time run-snapshots; rewriting them post-emission destroys the run-record property. Surface the finding and let the user repair manually or accept the drift.

---

## After Lint

If the lint run applied any auto-fixes that modified wiki pages (new stubs, added frontmatter, added wikilinks), update `wiki/hot.md` before closing the session. Note which pages were touched under `## Recent Changes` and summarize the lint outcome under `## Last Updated`.

For the full hot-cache protocol (when to read, when to update, sub-agent discipline), see `${CLAUDE_PLUGIN_ROOT}/_shared/hot-cache-protocol.md`.

If the lint report is advisory only (no auto-fixes applied), skip the hot.md update — reports live at `wiki/meta/lint-report-*.md` and do not count as wiki content changes.

---

## Report Rotation

After writing the new report, prune older lint artifacts (both `.md` reports and `.json` data files):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/prune-lint-reports.sh"
```

The script keeps the most recent 3 of each artifact type by default. Pass a count to override (`prune-lint-reports.sh 5`). See the script header for rationale.
