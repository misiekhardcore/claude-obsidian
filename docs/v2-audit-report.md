# v2.0.0 Audit Report

Generated: 2026-06-15

## 1. `references/` → `_shared/` Consolidation

### Already consolidated (plugin root `_shared/`)
13 shared files exist at the plugin root:
`INIT.md`, `canvas-spec.md`, `capture-pipeline.md`, `cli-reference.md`, `cli.md`, `frontmatter.md`, `hot-cache-protocol.md`, `image-capture.md`, `research-program.md`, `setup.md`, `vault-ops.md`, `vault-structure.md`, `wiki-modes.md`

### Remaining `references/` directories (NOT yet consolidated)
5 skills still have local `references/` directories that should be moved to `_shared/`:

| Skill | File(s) | Lines referencing in SKILL.md |
|---|---|---|
| `autoresearch` | `references/page-schemas.md` | L99 |
| `canvas` | `references/node-templates.md` | L49 |
| `lint` | `references/scan-scope.md`, `checks.md`, `conventions.md`, `dashboard.md`, `canvas-map.md` | L16, L30, L42, L46 |
| `obsidian-bases` | `references/examples.md` | L90, L104 |
| `obsidian-markdown` | `references/syntax-tables.md` | L8 |

### Action required
Move each referenced file to `_shared/` and update the SKILL.md references from e.g. `references/page-schemas.md` to `${CLAUDE_PLUGIN_ROOT}/_shared/page-schemas.md` (or similar). Note: `lint` has 5 files — these may be good candidates for keeping as `lint/scan-scope.md`-style naming in `_shared/` to avoid namespace collisions.

## 2. `commands/` Parity

### Existing command definitions (9 files in `commands/`)
| Command file | Status |
|---|---|
| `autoresearch.md` | ✅ Matches `skills/autoresearch/` |
| `braindump.md` | ✅ Matches `skills/braindump/` |
| `canvas.md` | ✅ Matches `skills/canvas/` |
| `daily.md` | ✅ Matches `skills/daily/` |
| `daily-close.md` | ✅ Matches `skills/daily-close/` |
| `dump.md` | ❓ No matching skill — alias for `/note` → maps to `skills/notes/` |
| `note.md` | ❓ No matching skill dir — maps to `skills/notes/` |
| `save.md` | ✅ Matches `skills/save/` |
| `wiki.md` | ✅ Matches `skills/wiki/` |

### Skills WITHOUT command definitions (8 skills undocumented)
| Skill | Suggested command |
|---|---|
| `defuddle` | `/defuddle <url>` |
| `ingest` | `/ingest <source>` |
| `lint` | `/lint [path]` |
| `memory-search` | `/memory-search <query>` |
| `notes` | `/notes [list\|process\|<text>]` (replaces `/note` + `/dump`) |
| `obsidian-bases` | `/obsidian-bases <query>` |
| `obsidian-markdown` | `/obsidian-markdown <feature>` |
| `query` | `/query <question>` |

### Notes
- `/note` and `/dump` commands both target the `notes` skill; the command files use `notes` as the skill name but no `commands/notes.md` file exists.
- `defuddle` has commands detected in its SKILL.md frontmatter but no corresponding `commands/defuddle.md` file.

## 3. Summary

| Category | Count |
|---|---|
| Skills total | 15 |
| Skills with remaining `references/` | 5 |
| Skills with command definition files | 7 (9 files, minus 2 aliases) |
| Skills without command files | 8 |
| Shared files in `_shared/` | 13 |

## 4. Recommendations

1. **Consolidate remaining `references/`** — move the 5 directories into `_shared/` and update all SKILL.md paths.
2. **Create command files** for all 8 undocumented skills to ensure consistent slash-command discoverability.
3. **Merge `/note` + `/dump`** into a single `commands/notes.md` file to match the actual `skills/notes/` skill.
4. **Publish v2.0.0** only after items 1-3 are complete.
