# Lint Scan Scope

## Folders Scanned

- `wiki/concepts/`, `wiki/entities/`, `wiki/sources/`, `wiki/domains/`, `wiki/comparisons/`, `wiki/questions/`, `wiki/solutions/`
- `wiki/index.md`, `wiki/log.md`, `wiki/hot.md`
- `wiki/canvases/*.canvas` — first-class; treated identically to `.md` in all 16 checks

## Folders Excluded

| Folder | Rationale |
|-|-|
| `wiki/meta/` | Administrative bookkeeping (lint reports, dashboards). Findings pointing into `wiki/meta/` from `wiki/index.md` are still validated by check #15. |
| `wiki/trails/` | Frozen run-snapshots; surfaced for visibility, never counted toward totals, never auto-fixed. |
| `notes/` | Transient inbox; only checks #14 (frontmatter gaps) and index drift apply. |
| `_archive/`, `_templates/`, `.raw/` | Non-wiki storage; never scanned. |

## File Extensions

- **Scanned for wikilinks (sources):** `.md`, `.canvas`
- **Valid as wikilink targets (resolver pool):** `.md`, `.canvas`, `.base`, `.png`, `.jpg`, `.jpeg`, `.svg`, `.pdf`
