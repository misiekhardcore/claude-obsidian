# Wiki Operational Modes

Pre-defined structures for specific vault use cases.

## Mode A: Website / Sitemap
- **Focus**: Content gaps, SEO, site architecture.
- **Structure**: `wiki/pages/` (URL-based), `wiki/structure/` (hierarchy), `wiki/audits/` (gaps).
- **Frontmatter**: `url`, `status` (live|redirect|404), `meta_description`, `last_crawled`.

## Mode B: GitHub / Repository
- **Focus**: Codebase mapping, ADRs, dependency risks.
- **Structure**: `wiki/modules/` (packages), `wiki/components/` (UI), `wiki/decisions/` (ADRs), `wiki/flows/` (request paths).
- **Frontmatter**: `path` (src path), `status` (active|deprecated), `language`, `depends_on`.

## Mode C: Business / Project
- **Focus**: Stakeholders, deliverables, competitive intel.
- **Structure**: `wiki/stakeholders/`, `wiki/decisions/`, `wiki/deliverables/`, `wiki/intel/`.
- **Frontmatter**: `status` (active|pending|done), `priority` (1-5), `owner`, `due_date`.

## Mode D: Personal / Second Brain
- **Focus**: Goals, learning, life areas.
- **Structure**: `wiki/goals/`, `wiki/learning/`, `wiki/people/`, `wiki/areas/`.
- **Frontmatter**: `status` (active|paused|completed), `area` (health|career|etc), `progress` (0-100).

## Mode E: Research
- **Focus**: Paper tracking, thesis development.
- **Structure**: `wiki/papers/` (summaries), `wiki/concepts/`, `wiki/thesis/` (state of field), `wiki/gaps/`.
- **Frontmatter**: `status` (summarized|synthesized), `year`, `venue`, `key_claim`.

## Mode F: Book / Course
- **Focus**: Theme analysis, curriculum sequence.
- **Structure**: `wiki/characters/`, `wiki/themes/`, `wiki/timeline/`, `wiki/synthesis/`.
- **Frontmatter**: `status` (developing|mature), `source_chapters`, `first_appearance`.
