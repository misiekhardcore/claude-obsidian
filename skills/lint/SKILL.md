---
name: lint
description: Wiki health check. Orphans, dead links, frontmatter gaps. Generates canvas maps and Bases dashboards.
allowed-tools: Agent Bash Read
---
# lint

Health check after every 10-15 ingests or weekly. Finds orphans, dead links, frontmatter gaps. Ask before auto-fixing; reports to `wiki/meta/lint-report-YYYY-MM-DD.md`.

## Scan Scope

Deterministic scan script (`scripts/lint-scan.sh`) produces byte-identical JSON (excluding `scan_date`).

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

## Agent Dispatch

On user trigger (`/lint`, "lint the wiki", "health check"):
1. Run `cd "${VAULT_ROOT}" && pwd` then `CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" bash "${CLAUDE_PLUGIN_ROOT}/scripts/lint-scan.sh"` (produces `wiki/meta/lint-data-YYYY-MM-DD.json`).
2. Dispatch `agents/lint.md` with `vault_path=$VAULT_ROOT` and `scope="full"` (or specific folder). Agent performs all 16 checks, drafts report to `wiki/meta/lint-report-YYYY-MM-DD.md`.
3. Present report path and summary to user.
4. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/prune-lint-reports.sh"` to prune old artifacts.

Main thread does not run checks — agent owns that work.

## Lint Checks

Lint agent runs all checks in order. Checks #1, #2, #7, #10 read from JSON; others use `obsidian` CLI or page reads. CLI verbs: `obsidian backlinks path=<page> format=json` (inbound counts), `obsidian unresolved format=json` (dead links).

- **Check #1: Orphan pages**. Source: `orphans` array in `lint-data-YYYY-MM-DD.json`. Wiki pages (`.md` and `.canvas`) with no inbound wikilinks. They exist but nothing points to them. `wiki/trails/*.md` and `notes/` are already excluded from the JSON output — trails are designed-orphan (forward-only model), so they would be flagged in perpetuity.
- **Check #2: Dead links**. Source: `dead_links` array in `lint-data-YYYY-MM-DD.json`. Each entry is `{source_page, link_text}` — a wikilink in `source_page` that does not resolve to any existing page. Canvas dead links are merged into the same array; no separate handling. Findings inside `wiki/trails/*.md` are surfaced for visibility but **never auto-fixed** — trails are run-snapshots frozen at write time; the user repairs manually or accepts the drift (same policy as check #16).

  **Anti-pattern note:** URL-as-wikilink occurrences (e.g. `[[https://...]]`) are in the `anti_patterns` array of the JSON. Report these in a dedicated **Anti-patterns** section; do **not** count them toward the dead-link total.

- **Check #6: Frontmatter gaps**. Pages missing required fields (`type`, `status`, `created`, `updated`, `tags`, `confidence`). Flag missing `evidence:` when `confidence:` is `INFERRED`/`AMBIGUOUS`.
- **Check #7: Empty sections**. Read `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/checks.md#check-7-empty-sections`.
- **Check #8: Stale index entries**. Items in `wiki/index.md` pointing to renamed/deleted pages.
- **Check #9: hot.md size budget**. Read `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/checks.md#check-9-hotmd-size-budget`.
- **Check #10: Backlink density**. Source: `backlinks` map in JSON (pre-computed). Compare inbound count vs. outbound count (`related:` + inline wikilinks). Flag pages where `inbound ≥ 3` **and** `outbound ≤ 1`.
- **Check #11: Hub promotion candidates**. Read `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/checks.md#check-11-hub-promotion-candidates`.
- **Check #12: Hub stale-count drift**. Read `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/checks.md#check-12-hub-stale-count-drift`.
- **Check #13: Hub demotion candidates**. Read `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/checks.md#check-13-hub-demotion-candidates`.
- **Check #14: Notes inbox**. Scoped to `<vault_root>/notes/` only. Two checks:
  - **Frontmatter gaps** — flag any `notes/*.md` (excluding `notes/index.md`) missing one of: `type`, `title`, `created`, `updated`, `source_project`, `status`. The `topic` and `tags` fields are optional and never flagged.
  - **Index drift** — flag any file in `notes/` that is missing from `notes/index.md`, and any row in `notes/index.md` whose title text doesn't match any existing note's frontmatter `title:` field. Match against frontmatter `title:`, not filenames — filenames are slugs that may diverge from display titles after CAPTURE rewrites (AC4).
  - **Explicitly skip** orphan checks, dead-link checks, stale-claim checks, and contradictions for `notes/`. These are wiki-canonical concerns and inappropriate for a transient inbox.
- **Check #15: Misplaced index entries**. For every wikilink in `wiki/index.md`, verify the entry sits under the section matching its target's `type:` frontmatter. Read each linked target via `obsidian read path=<target>` to extract its `type:`, then determine which `## <Section>` heading the entry currently sits under (the nearest preceding H2 in `wiki/index.md`).

  Map `type:` → expected section using this fixed table:

  |`type:`|Expected section|
  |-|-|
  |concept|`## Concepts`|
  |source|`## Sources`|
  |synthesis|`## Plans & Decisions` (or `## Synthesis` if separate)|
  |decision|`## Plans & Decisions`|
  |meta|(no section — sits in the Navigation row, not in the body)|
  |domain|`## Domains`|

  Types not listed above are skipped (no flag) — extend the table when a new type acquires a canonical section.
  - **Strays** — entries with no preceding H2 (above the first heading) flag as `entry above all sections, expected under <Section>`.
  - **Misplacements** — entries under a non-matching section flag as `entry under <Current> but type=<X> expects <Expected>`.

  Role: **safety net**, not the primary placement mechanism. `/save` writes new entries directly under the correct section (see #84), so a healthy vault reports zero findings here. Findings indicate drift — manual edits, pre-fix history, or an agent that picked the wrong section despite the corrected `/save` snippet. Auto-fix policy is **ask-first** (see Before Auto-Fixing).

- **Check #16: Trail integrity**. Scoped to `wiki/trails/*.md`. Trails are run-records emitted by `/autoresearch` and frozen at write time, so integrity checks run against a fixed shape. For each trail page:
  - **Required trail-specific frontmatter** — flag missing `topic:`, `research_run:`, or `synthesis:`. The universal fields (`type`, `title`, `created`, `updated`, `tags`, `status`, `confidence`, plus `evidence` when `confidence` is `INFERRED`/`AMBIGUOUS`) are check #6's responsibility — do not duplicate.
  - **Synthesis link resolves** — the `synthesis:` value is a wikilink-by-title (e.g. `[[Research: Topic]]`), not a vault-relative path, so `read path=` is not the right resolver. Instead, run `obsidian unresolved format=json` once per lint pass and check whether the stripped link text appears in the returned `[{"link": "..."}]` array. Membership in that array means the link is dead — flag `synthesis: [[Research: X]] does not resolve`.
  - **Body is an ordered list** — the trail body (everything below the first H1, excluding a single optional intro paragraph) must be exactly one ordered Markdown list (`1. …`, `2. …`, …). Flag `body is not an ordered list` for trails whose body has no ordered list, multiple top-level lists, prose paragraphs interleaved with list items, or nested lists.
  - **Every list item contains a wikilink and a plain-text annotation** — for each ordered-list item, flag the item if it has zero `[[wikilink]]`s, more than one `[[wikilink]]`, no annotation text after stripping the wikilink (the residue must contain at least one non-whitespace, non-punctuation character), or if the annotation text contains a URL (`https?://` or a Markdown link `[text](url)`) or an additional `[[wikilink]]` — annotation text must be plain text (inline formatting like bold/italic is permitted; links are not).
  - **No minimum link count.** A one-step trail is valid output and must not be flagged.

  Auto-fix policy: **never auto-fix**. Trails are run-snapshots; rewriting them post-emission destroys the run-record property. Findings here are advisory — the user repairs the trail manually or accepts the drift.

## Manual Review

Monthly or after new domain burst. Cannot be automated without NLP. Check for: stale claims (older pages contradicted by newer sources), missing pages (concepts/entities in 3+ pages without own page), missing cross-references (entity names without wikilinks).

## Lint Report Format

Create at `wiki/meta/lint-report-YYYY-MM-DD.md`. Include: Summary (pages scanned, issues found, auto-fixed, needs review), sections for each check type with flagged items and remediation suggestions. Orphans, dead links, frontmatter gaps, backlink density, hub promotion/stale/demotion candidates, hot.md size, notes inbox (frontmatter + index drift), misplaced index entries, trail integrity. Anti-patterns section (URL-as-wikilink `[[https://...]]`) — report separately, not in dead-link count.

## Naming Conventions

Enforce these during lint:

|Element|Convention|Example|
|-|-|-|
|Filenames|Title Case with spaces|`Machine Learning.md`|
|Folders|lowercase with dashes|`wiki/data-models/`|
|Tags|lowercase, hierarchical|`#domain/architecture`|
|Wikilinks|match filename exactly|`[[Machine Learning]]`|

Filenames must be unique across the vault. Wikilinks work without paths only if filenames are unique.

## Writing Style Check

During lint, flag pages that violate the style guide:

- Not declarative present tense ("X basically does Y" instead of "X does Y")
- Missing source citations where claims are made
- Uncertainty not flagged with `> [!gap]`
- Contradictions not flagged with `> [!contradiction]`

## Bases Dashboard

Read `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/dashboard.md` for Bases dashboard config template and embedding syntax.

## Canvas Map

Read `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/canvas-map.md` for canvas map config template.

## Before Auto-Fixing

Show report first; ask "Auto-fix or review each?" Safe to auto-fix: missing frontmatter, stubs, wikilinks. Review first: deletions, contradictions, merges, misplaced entries (per-entry safer). Never auto-fix check #16 (trail integrity) — trails frozen at write-time; user repairs or accepts drift.

## After Lint

If auto-fixes modified pages: update hot.md per `_shared/hot-cache-protocol.md`. If advisory only: skip hot.md update.

## Report Rotation

Prune old artifacts after agent finishes: `bash $CLAUDE_PLUGIN_ROOT/scripts/prune-lint-reports.sh`. Keeps 3 most recent by default; pass count to override.
