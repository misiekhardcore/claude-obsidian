# AGENTS.md

Agent instructions for claude-obsidian plugin.

## Plugin Architecture

claude-obsidian is a Claude Code plugin that manages an Obsidian vault using the LLM Wiki pattern.

**Key paths:**
- **Vault:** Located at `${user_config.vault_path}` (set in project/global settings, or CWD if it contains `wiki/`)
- **Skills:** Located at `skills/` in the plugin repo
- **Sources:** Stored at `${vault_path}/.raw/` (immutable)
- **Knowledge:** Generated at `${vault_path}/wiki/` (agent-owned)

## Skills Discovery

All skills live in `skills/<name>/SKILL.md` and are auto-discovered by Claude Code via the plugin manifest.

## Available Skills

| Skill | Trigger phrases |
|---|---|
| `wiki` | `/wiki`, set up wiki, scaffold vault, check setup |
| `wiki-ingest` | ingest, ingest this url, ingest this image, batch ingest |
| `wiki-query` | query, what do you know about, query quick:, query deep: |
| `wiki-lint` | lint the wiki, health check, find orphans, dead links |
| `save` | `/save`, file this conversation, save insight |
| `autoresearch` | autoresearch, autonomous research loop |
| `canvas` | `/canvas`, add to canvas, create canvas |
| `defuddle` | clean this url, defuddle, strip clutter |
| `obsidian-markdown` | obsidian syntax, wikilink, callout, embed |
| `obsidian-bases` | obsidian bases, .base file, dynamic table |

## Key Conventions

- **Vault root:** The directory containing `wiki/` and `.raw/` (specified by `vault_path`)
- **Hot cache:** `wiki/hot.md` (read at session start, updated at session end)
- **Source documents:** `.raw/` (immutable: agents never modify)
- **Generated knowledge:** `wiki/` (agent-owned, links to sources via wikilinks)
- **Manifest:** `.raw/.manifest.json` tracks ingested sources (delta tracking)

## Bootstrap

When the user opens this plugin for the first time:

1. Read this file (`AGENTS.md`) and the project `CLAUDE.md` for context
2. Read `skills/wiki/SKILL.md` for the orchestration pattern
3. If `wiki/hot.md` exists, read it silently to restore recent context
4. If the user types `/wiki` (or "set up wiki"), follow the wiki skill's scaffold workflow

## Reference

- Plugin homepage: https://github.com/misiekhardcore/claude-obsidian
- Pattern source: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- Obsidian skills: https://github.com/kepano/obsidian-skills (Obsidian-specific reference)
