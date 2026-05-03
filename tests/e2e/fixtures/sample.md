---
name: E2E Sample Fixture
description: Minimal markdown source used as the ingest fixture for the claude-obsidian E2E harness.
type: source
---

# E2E Sample Fixture

A short document used as the ingest fixture for the claude-obsidian end-to-end harness.
The ingest skill reads this from `.raw/sample.md`, extracts metadata, and creates
a corresponding page in `wiki/sources/` with valid frontmatter. `wiki/index.md` is
updated to reference the new page.

## Notes

- Intentionally minimal (~200 bytes of body text).
- Content is synthetic; no real-world information is included.
- Shape-only assertions apply — the harness never checks generated page content.
