# claude-obsidian

Agent + user instructions for the claude-obsidian plugin. `AGENTS.md` is a symlink to this file.

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
notes/             Inbox: verbatim quick-capture notes (owned by `notes` skill)
  index.md         Pending + Deferred bullet list
daily/             Chronological daily log (owned by `daily` skill)
  YYYY-MM-DD.md    One file per day, append-only bullets under ## Captures
.raw/              Source documents — immutable, never modified by agents
_templates/        Obsidian Templater templates
_attachments/      Images and PDFs referenced by wiki pages
```

## Wiki Conventions

- **Vault root:** The directory containing `wiki/` and `.raw/` (specified by `vault_path`)
- **Hot cache:** `wiki/hot.md` — read at session start, updated at session end (~500 words of recent context)
- **Index:** `wiki/index.md` — master registry of all pages with categories
- **Categories:** `wiki/concepts/`, `wiki/entities/`, `wiki/sources/` (expand as needed)
- **Source documents:** `.raw/` — immutable, agents never modify
- **Generated knowledge:** `wiki/` — agent-owned, links to sources via wikilinks
- **Manifest:** `.raw/.manifest.json` — delta tracking for ingested sources

## Vault I/O

All vault reads and writes go through the **Obsidian CLI**, not `Read`/`Write`/`Edit`/`cat`. The CLI keeps Obsidian's index consistent with disk and gives every skill a single, vault-aware code path.

```bash
obsidian read path=wiki/hot.md
obsidian create path=wiki/concepts/foo.md content="..."
obsidian append file=wiki/log.md content="..."
obsidian prepend file=wiki/index.md content="..."
```

A PreToolUse Bash hook (`hooks/obsidian-cli-rewrite.sh`) transparently routes raw `obsidian <verb> ...` calls through `${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh`, which resolves the vault, pre-flights the connection, and normalizes exit codes (the upstream CLI always returns 0). See the wrapper's header comment for exit-code semantics, error patterns, escape hatches, and documented bypasses.

`Read` is allowed only for resources outside the vault (skill references, plugin templates, external paths). `Write` / `Edit` are not used for vault paths.

## Skills Discovery

All skills live in `skills/<name>/SKILL.md` and are auto-discovered by Claude Code via the plugin manifest.

## Available Skills

| Skill | Trigger phrases |
|---|---|
| `wiki` | `/wiki`, set up wiki, scaffold vault, check setup |
| `ingest` | ingest, ingest this url, ingest this image, batch ingest |
| `query` | query, what do you know about, query quick:, query deep: |
| `lint` | lint the wiki, health check, find orphans, dead links |
| `save` | `/save`, file this conversation, save insight |
| `notes` | `/note`, `/dump`, note this, todo:, show my inbox, `/note process` |
| `daily` | `/daily`, daily note this, log to today, log this, add to today's log |
| `braindump` | `/braindump`, brain dump this, dump the following thoughts, dump these thoughts, braindump:, split this into notes |
| `autoresearch` | autoresearch, autonomous research loop |
| `canvas` | `/canvas`, add to canvas, create canvas |
| `defuddle` | clean this url, defuddle, strip clutter |
| `obsidian-markdown` | obsidian syntax, wikilink, callout, embed |
| `obsidian-bases` | obsidian bases, .base file, dynamic table |

## Bootstrap

When the user opens this plugin for the first time:

1. Read this file for context
2. Read `skills/wiki/SKILL.md` for the orchestration pattern
3. Hot cache auto-read depends on `claude-obsidian.bootstrap_read_hot` (default: `on-demand`):
   - `always` — `wiki/hot.md` was injected at session start by the hook; absorb it silently.
   - `on-demand` (default) — no injection occurred; wiki skills read `wiki/hot.md` when they activate. Saves ~2–3k tokens/turn for non-wiki sessions.
   - `never` — same hook behavior as `on-demand`; treat this as a user preference to avoid loading `wiki/hot.md` unless the user explicitly asks for it or the current task clearly requires wiki context.
4. If the user types `/wiki` (or "set up wiki"), follow the wiki skill's scaffold workflow

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

Cross-skill structural conventions (vault directory map, page types, confidence tagging semantics, typed-relationship semantics) are defined in `${CLAUDE_PLUGIN_ROOT}/_shared/vault-structure.md`.

The frontmatter field schema (universal fields, typed relationships, status and confidence values) is defined in `${CLAUDE_PLUGIN_ROOT}/_shared/frontmatter.md`.

Skill-operational rules (ingest procedure, contradiction handling, quality standards, log format) are defined in `skills/wiki/references/maintenance-rules.md`.

The hot-cache read/write protocol is defined in `${CLAUDE_PLUGIN_ROOT}/_shared/hot-cache-protocol.md`.

Read the relevant files before any ingest, autoresearch, or significant wiki operation.

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

## Reference

- Plugin homepage: https://github.com/misiekhardcore/claude-obsidian
- Pattern source: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- Obsidian skills: https://github.com/kepano/obsidian-skills (Obsidian-specific reference)
