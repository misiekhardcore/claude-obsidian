# CLAUDE.md

Guidance for using claude-obsidian as a Claude Code plugin.

## Vault Assumptions

This vault is designed for **agent-only** use with **single-user, single-machine** access patterns. Any feature proposal violating one of these assumptions must be challenged before implementation:

- **Agent-only readers/writers.** No multi-user tiering, reviewer workflow, access control, or `reviewed_at` timestamps. Every write is an agent or the single human owner; human review happens via git, not via in-vault metadata.
- **Single-user, single-machine by default.** Cross-project access is opt-in per-project, not a multi-tenant design target.
- **Git-backed, file-per-page.** No database, no server, no live sync. All coordination is via commit history.

## Plugin Setup

This is both a Claude Code plugin and an Obsidian vault. To use it:

1. Set your vault path in Claude Code's project settings (or global settings):
   - **Setting key:** `claude-obsidian.vault_path`
   - **Value:** Absolute path to your Obsidian vault (e.g., `/Users/you/Obsidian/MyVault`)
   - **What it controls:** Where skills read and write wiki files

2. If `vault_path` is not set, Claude will check the current working directory:
   - If CWD contains a `wiki/` folder, that becomes the vault root
   - Otherwise, initialization fails with an error

3. Run `/wiki init` to bootstrap a new vault with the correct folder structure

## Vault Structure

Your vault must contain:

```
wiki/              Claude-generated knowledge base
  hot.md           Recent context cache (read first at session start)
  index.md         Master index of all pages
  concepts/        Conceptual deep-dives
  entities/        Reference material (people, organizations, tools)
  sources/         Summaries linked to original materials
.raw/              Source documents — immutable, never modified by agents
_templates/        Obsidian Templater templates
_attachments/      Images and PDFs referenced by wiki pages
```

## Wiki Conventions

- **Hot cache:** `wiki/hot.md` — read at session start, updated at session end (~500 words of recent context)
- **Index:** `wiki/index.md` — master registry of all pages with categories
- **Categories:** `wiki/concepts/`, `wiki/entities/`, `wiki/sources/` (expand as needed)
- **Source tracking:** `.raw/.manifest.json` — delta tracking for ingested sources

## Skills Overview

| Skill | Trigger |
|-------|---------|
| `/wiki` | Setup, scaffold, route to sub-skills |
| `/wiki-ingest` | Single or batch source ingestion (interactive by default) |
| `/wiki-query` | Answer questions using vault content |
| `/wiki-lint` | Health check: find orphans, dead links, gaps |
| `/save` | File current conversation or insight into wiki |
| `/autoresearch` | Autonomous research loop: search, fetch, synthesize, file |
| `/canvas` | Visual layer: add images, PDFs, notes to Obsidian canvas |

## Ingest Rules

Single-source ingests via `/wiki-ingest` require an interactive discussion before writing pages. After reading the source, Claude must ask:
- What to emphasize
- How granular to go
- What existing wiki context to link against

**Escape hatch:** Say "just ingest it" or "auto-ingest" to skip discussion and proceed automatically.

The `/autoresearch` pipeline is exempt — it is intentionally autonomous.

## MCP (Optional)

If you configured the MCP server, Claude can read and write vault notes directly via the `obsidian-vault` server.
See `skills/wiki/references/mcp-setup.md` for setup instructions.

## Maintenance

The schema (directory map, page types), ingest procedure, contradiction handling, and quality standards are defined in `skills/wiki/references/maintenance-rules.md`.

The frontmatter field schema (universal fields, typed relationships) is defined in `skills/wiki/references/frontmatter.md`.

Read both files before any ingest, autoresearch, or significant wiki operation.

## Cross-Project Access

To reference this vault from another Claude Code project, add to that project's CLAUDE.md:

```markdown
## Wiki Knowledge Base

Path: /path/to/vault

When you need context:
1. Read wiki/hot.md first (recent context)
2. If not enough, read wiki/index.md
3. Drill into domain-specific pages as needed

Do NOT read for general coding questions.
```
