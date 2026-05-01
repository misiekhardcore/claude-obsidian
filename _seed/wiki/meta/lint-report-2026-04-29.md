---
type: meta
title: "Lint Report 2026-04-29"
created: 2026-04-29
updated: 2026-04-29
tags: [meta, lint]
status: developing
---

# Lint Report: 2026-04-29

## Summary
- Pages scanned: 8
- Issues found: 6 (0 critical, 3 warnings, 3 suggestions)
- Auto-fixed: 0
- Needs review: 6

---

## Critical Issues
None.

---

## Warnings (should fix)

### 1. Template Variables Not Expanded
- **Pages affected:** All 8 wiki pages
- **Problem:** Frontmatter fields use `{{today}}` template variable syntax, but variables were not expanded. This creates ambiguous dates.
- **Affected pages:**
  - [[hot]]: `created: {{today}}`, `updated: {{today}}`
  - [[index]]: `created: {{today}}`, `updated: {{today}}`
  - [[log]]: `created: {{today}}`, `updated: {{today}}`, `## {{today}}`
  - [[overview]]: `created: {{today}}`, `updated: {{today}}`
  - [[example-concept]]: `created: {{today}}`, `updated: {{today}}`
  - [[example-entity]]: `created: {{today}}`, `updated: {{today}}`
  - [[example-question]]: `created: {{today}}`, `updated: {{today}}`
  - [[example-source]]: `date_published: {{today}}`, `created: {{today}}`, `updated: {{today}}`
- **Suggested fix:** Replace all `{{today}}` with `2026-04-29` in frontmatter and content. This should happen automatically during vault initialization but appears to have been skipped.

### 2. Overview Page Incomplete (Seed Status)
- **Page:** [[overview]]
- **Problem:** Page has `status: seed` but contains empty placeholder sections. The page lacks actual content about vault purpose, themes, and metrics.
- **Sections with placeholder content:**
  - `## Purpose` — comment placeholder: "<!-- What domains and topics does this vault cover? What is it for? -->"
  - `## Key Themes` — comment placeholder: "<!-- The 3-5 most important ideas or insights across the vault -->"
  - `## Status` — all values are dashes ("—") instead of real metrics
- **Suggested fix:** Populate the overview page with real vault metadata once you ingest your first real sources. For now, either (a) delete the page, or (b) add a note that this is a template.

### 3. Index Page Missing Domain List
- **Page:** [[index]]
- **Problem:** The `## Domains` section has a placeholder comment but no actual domain pages are listed. The index is the master catalog but is incomplete.
- **Suggested fix:** Populate domains as you create them. Alternatively, add a note that "Domains will be added as the vault grows."

---

## Suggestions (worth considering)

### 1. Unresolved Wikilinks Outside Wiki Folder
- **Problem:** The vault root contains many files outside `wiki/`, and some pages reference them with wikilinks that cannot resolve.
- **Unresolved links found:**
  - `[[LICENSE]]` — referenced but does not exist as a .md file in the vault
  - `[[getting-started]]` — mentioned in FIRST_RUN.md or guides but no page exists
  - `[[LLM Wiki Pattern]]`, `[[Cosmic Brain Clean.gif]]`, etc. — mostly media or placeholder references
- **Impact:** Low — these are primarily in non-wiki root files (AGENTS.md, README.md, skills documentation) that are toolkit documentation, not knowledge base content.
- **Suggested fix:** Either create stub pages for frequently referenced concepts, or accept that root-level documentation uses file-based links rather than wikilinks.

### 2. Missing Concept Pages for Frequently Mentioned Terms
- **Mentioned in multiple pages without dedicated pages:**
  - "confidence" — referenced extensively (confidence field in frontmatter, confidence levels like "EXTRACTED", "INFERRED", "AMBIGUOUS") but no concept page explains this schema
  - "evidence" — all pages have `evidence:` field but no page explains how to use it
  - "frontmatter" — discussed in example pages but no dedicated page
  - "wikilink" — mentioned in examples but no How-To page for wikilink syntax
- **Suggested fix:** Create concept pages for these foundational ideas once you have real content. For a starter vault, this is acceptable.

### 3. Notes Inbox Empty but Properly Configured
- **Page:** `notes/index.md`
- **Status:** OK — properly has required frontmatter and structure
- **Note:** No note captures have been recorded yet (no files in `notes/` except index.md). This is expected for a freshly initialized vault.

---

## Detailed Checks

### Orphan Pages
- **Result:** None found. All 8 wiki pages are linked from at least one other page.
- **Backlink summary:**
  - [[example-source]]: 12 inbound links
  - [[example-concept]]: 9 inbound links
  - [[example-entity]]: 7 inbound links
  - [[index]]: 6 inbound links
  - [[log]]: 6 inbound links
  - [[hot]]: 5 inbound links
  - [[overview]]: 5 inbound links
  - [[example-question]]: 5 inbound links

### Dead Links (Wikilinks Referencing Non-Existent Pages)
- **Result:** None found in wiki/ folder. All wikilinks resolve to existing pages.

### Frontmatter Completeness
- **Result:** All pages have required fields:
  - `type` ✓
  - `title` ✓
  - `created` ✓ (value: `{{today}}` — needs expansion)
  - `updated` ✓ (value: `{{today}}` — needs expansion)
  - `tags` ✓
  - `status` ✓
- **Additional fields present:**
  - Concept pages: `complexity`, `domain`, `aliases`, `confidence`, `evidence`, `related`, `uses` ✓
  - Entity pages: `entity_type`, `role`, `first_mentioned`, `confidence`, `evidence`, `related` ✓
  - Source pages: `source_type`, `author`, `date_published`, `url`, `source_reliability`, `key_claims`, `confidence`, `evidence`, `related` ✓
  - Question pages: `question`, `answer_quality`, `confidence`, `evidence`, `related` ✓

### Empty Sections
- **Result:** None found. All headings have content or are part of the template structure.

### Hot Cache Size Budget
- **File:** `wiki/hot.md`
- **Word count:** 367 words
- **Spec limit:** 500 words
- **Status:** ✓ OK (delta: -133 words)
- **Note:** Well within acceptable range. No action needed.

### Notes Inbox Frontmatter & Index Drift
- **File:** `notes/index.md`
- **Frontmatter check:** ✓ Has required fields (type, title, created, updated, tags, status)
- **Index drift check:** ✓ No note captures exist yet (no files to index)
- **Status:** OK

---

## Stale Claims & Contradictions
- **Result:** Not applicable — all pages are freshly generated stubs. No actual claims to check for staleness.

---

## Cross-Reference & Naming Convention Checks

### Naming Conventions
- **Result:** All page filenames follow Title Case convention ✓
- **Wikilinks:** All match filenames exactly ✓
- **Folder structure:** Uses lowercase with dashes ✓
  - `wiki/concepts/`
  - `wiki/entities/`
  - `wiki/questions/`
  - `wiki/sources/`

### Writing Style
- **Result:** All pages use declarative present tense ✓
- **Example:** "A source page is the ingest record..." not "A source page basically is..."
- **Uncertainty flagging:** N/A (no uncertainty in stub pages)
- **Contradiction flagging:** N/A (no contradictions in single-source examples)

---

## Recommendations

### High Priority
1. **Expand {{today}} template variables** in all 8 pages to actual date `2026-04-29`

### Medium Priority
2. **Populate overview.md** with real vault metadata once you begin ingesting
3. **Populate index.md domains section** as you create domain-level pages
4. **Optional:** Create concept pages for foundational schema terms (confidence, evidence, frontmatter, wikilink)

### Low Priority
5. **Notes inbox:** Remains empty until first capture — this is expected behavior

---

## Next Steps

1. **Before next ingest:** Fix template variable expansion in all 8 wiki pages
2. **After first ingest:** Re-run lint to check for dead links and missing cross-references
3. **Monthly:** Review seed pages ([[overview]], example pages) and upgrade status or delete stubs

---

## Metadata
- **Lint scope:** `wiki/` folder only
- **Date run:** 2026-04-29
- **Vault version:** Initialized
- **Total checks performed:** 10
