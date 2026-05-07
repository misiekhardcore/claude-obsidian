---
name: lint
description: Comprehensive wiki health check. Scans for orphans, dead links, frontmatter gaps, empty sections. Generates structured report. Dispatched on "lint wiki", "health check", "audit", "clean up".
model: sonnet
maxTurns: 40
tools: Read, Write, Glob, Grep, Bash
---
Scan vault and produce comprehensive lint report. Receives: vault path, scope (full or specific folder).

## Step 1 — Locate scan data

The orchestrator runs `lint-scan.sh` before dispatching this agent. Read `wiki/meta/lint-data-YYYY-MM-DD.json` (today's date). If today's JSON is missing, run the scan as a fallback:

```bash
CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" bash "${CLAUDE_PLUGIN_ROOT}/scripts/lint-scan.sh"
```

JSON is authoritative for dead_links, orphans, unresolved_targets, backlinks, anti_patterns, scope. Do NOT run `obsidian deadends`, `orphans`, or per-page `backlinks` — JSON is canonical.

## Step 2 — Agent-driven checks

Work through checks in `skills/lint/SKILL.md` order using JSON where available, read pages only when needed:

- **#1 (orphans):** use JSON `orphans`.
- **#2 (dead links):** use JSON `dead_links` (canvas merged).
- **#6 (frontmatter gaps):** read in-scope pages per `scope.scanned_dirs`.
- **#7 (empty sections):** use JSON `empty_sections`. Each entry is `{source_page, heading}`. Report each as `[[slug]]: empty section "<heading>"`.
- **#8 (stale index):** `obsidian read path=wiki/index.md` + validate.
- **#9 (hot.md size):** read + word count.
- **#10 (backlink density):** use JSON `backlinks`.
- **#11–#13 (hub promotion/drift/demotion):** use JSON `backlinks`.
- **#14 (notes inbox):** read `notes/`.
- **#15 (misplaced index):** read `wiki/index.md` + linked pages.
- **#16 (trail integrity):** read `wiki/trails/*.md`.

Canvas files in `wiki/canvases/` are first-class. Use `scope.scanned_dirs` to stay in scope.

## Output

Create `wiki/meta/lint-report-YYYY-MM-DD.md` per `skills/lint/SKILL.md` format. Include **Anti-patterns** section for URL-as-wikilink from JSON. Report only; user decides fixes.
