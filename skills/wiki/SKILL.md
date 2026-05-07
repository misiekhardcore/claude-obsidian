---
name: wiki
description: Knowledge companion. Bootstraps vault, scaffolds structure, routes to sub-skills.
allowed-tools: Bash Read Glob Grep
---
# wiki

Build and maintain persistent, compounding wiki in Obsidian vault. Write, cross-reference, file, maintain structured knowledge that gets richer with every source and question. Wiki is product; chat is interface. Key difference from RAG: wiki is persistent artifact with pre-flagged contradictions and accumulated synthesis.

## Architecture

Directory map, page-type table, semantics in `_shared/vault-structure.md` (single source of truth).

Peers of `wiki/`: `notes/` (inbox, notes skill), `daily/` (log, daily skill).

Canvas files (`.canvas`) are first-class wiki documents. Indexed, counted in lint, scanned for dead links. `canvas` skill owns creation/editing.

Dot-prefixed folders (`.raw/`) hidden; used for immutable sources.

## Hot Cache

`wiki/hot.md`: ~500-word summary of recent context. Allows any session to get context without crawling full wiki. Full protocol in `_shared/hot-cache-protocol.md` (single source of truth).

## Operations

Route to the correct operation based on what the user says:

|User says|Operation|Sub-skill|
|-|-|-|
|"/wiki init", "init vault", "bootstrap vault"|INIT|this skill|
|"scaffold", "set up vault", "create wiki"|SCAFFOLD|this skill|
|"/wiki promote &lt;tag&gt;", "promote tag", "scaffold a hub"|PROMOTE|this skill|
|"ingest [source]", "process this", "add this"|INGEST|`ingest`|
|"what do you know about X", "query:"|QUERY|`query`|
|"lint", "health check", "clean up"|LINT|`lint`|
|"save this", "file this", "/save"|SAVE|`save`|
|"/note", "/dump", "note this", "todo:", "show my inbox", "/note process"|NOTE|`notes`|
|"/autoresearch [topic]", "research [topic]"|AUTORESEARCH|`autoresearch`|
|"/canvas", "add to canvas", "open canvas"|CANVAS|`canvas`|

## INIT Operation

Trigger: `/wiki init`, "init vault", "bootstrap vault".

Goal: seed an empty vault from `${user_config.vault_path}` so the user can open it in Obsidian. One-shot, idempotent; does not scaffold the knowledge base (that is SCAFFOLD).

Delegate to the umbrella script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/wiki-init.sh" "${user_config.vault_path}"
```

`bin/wiki-init.sh` handles the full flow:

1. If the vault path argument is empty, prints `Configure vault path first: enable the plugin and enter your vault path when prompted` and exits 0 — no error, no further action.
2. Calls `bin/setup-vault.sh` to create `.obsidian/`, `.raw/`, `wiki/`, `_templates/` and the Obsidian config files.
3. Calls `bin/copy-templates.sh` to copy `_templates/*.md` into the vault, skipping files that already exist.
4. Prints next steps: open Obsidian at the vault path, enable the Bases core plugin, install the Templater community plugin, then run `/wiki` to scaffold the knowledge base.

Re-running is safe: every step guards existing files.

## SCAFFOLD Operation

Trigger: user describes what the vault is for.

Read `references/operation-scaffold.md` for the 12-step procedure and the vault `CLAUDE.md` template. The reference is the single source of truth for SCAFFOLD; this skill body only routes to it.

## PROMOTE Operation

Trigger: `/wiki promote <tag>`, "promote tag", "scaffold a hub for X".

Read `references/operation-promote.md` for the 10-step procedure, frontmatter shape, body template, idempotency guard, and forward-only contract. The reference is the single source of truth for PROMOTE; this skill body only routes to it.

## Cross-Project Referencing

This is the force multiplier. Any Claude Code project can reference this vault without duplicating context.

In another project's CLAUDE.md, add:

```markdown
## Wiki Knowledge Base

Path: ~/path/to/vault

When you need context not already in this project:

1. Read wiki/hot.md first (recent context, ~500 words)
2. Tag-match the question against leaves; check wiki/domains/<tag>/\_index.md for a curated hub
3. If no hub matches, read wiki/index.md (master flat registry)
4. Only then read individual wiki pages

Do NOT read the wiki for:

- General coding questions or language syntax
- Things already in this project's files or conversation
- Tasks unrelated to [your domain]
```

This keeps token usage low. Hot cache costs ~500 tokens. Index costs ~1000 tokens. Individual pages cost 100-300 tokens each.

## Your Job (LLM)

1. Set up vault
2. Scaffold structure from domain description
3. Route ingest/query/lint to correct sub-skill
4. Maintain hot cache after every operation
5. Update index.md, domain hubs, log, hot.md on changes
6. Use frontmatter and wikilinks
7. Never modify .raw/

Human's job: curate sources, ask questions, think about what it means.
