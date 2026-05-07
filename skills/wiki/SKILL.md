---
name: wiki
description: Knowledge companion. Bootstraps vault, scaffolds structure, routes to sub-skills.
allowed-tools: Bash Read Glob Grep
---
# wiki

Build and maintain persistent, compounding wiki in Obsidian vault. Wiki is product; chat is interface.

## Architecture
- **Truth**: Directory map, page-type table, and semantics in `_shared/vault-structure.md`.
- **Peers**: `notes/` (inbox), `daily/` (log).
- **Canvas**: `.canvas` files are first-class documents. `canvas` skill owns them.
- **Sources**: `.raw/` folders are hidden and immutable.

## Hot Cache
`wiki/hot.md`: ~500-word summary of recent context. Protocol in `_shared/hot-cache-protocol.md`.

## Operations Routing
Route user requests to the correct sub-skill:

|Trigger|Operation|Skill|
|:-|:-|:-|
|`/wiki init`, "init vault"|INIT|`wiki`|
|"scaffold", "create wiki"|SCAFFOLD|`wiki`|
|`/wiki promote <tag>`, "promote tag"|PROMOTE|`wiki`|
|"ingest [source]", "process this"|INGEST|`ingest`|
|"what do you know about X", "query:"|QUERY|`query`|
|"lint", "health check"|LINT|`lint`|
|"save this", "/save"|SAVE|`save`|
|"/note", "todo:", "show inbox"|NOTE|`notes`|
|"/autoresearch [topic]"|AUTORESEARCH|`autoresearch`|
|"/canvas", "open canvas"|CANVAS|`canvas`|

## Local Operations

### INIT
Seed empty vault from `${user_config.vault_path}`. Idempotent.
```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/wiki-init.sh" "${user_config.vault_path}"
```
`bin/wiki-init.sh` handles vault creation, templates, and Obsidian config.

### SCAFFOLD
User describes vault purpose → Follow 12-step procedure in `references/operation-scaffold.md`.

### PROMOTE
`/wiki promote <tag>` → Follow 10-step procedure in `references/operation-promote.md`.

## Cross-Project Referencing
Any project can reference this vault. Add this to other projects' `CLAUDE.md`:
```markdown
## Wiki Knowledge Base
Path: /path/to/vault
When needed: (1) read wiki/hot.md, (2) read wiki/index.md, (3) drill into domain pages.
Do NOT read for general coding questions.
```

## LLM Responsibilities
1. Set up vault and scaffold structure.
2. Route operations to sub-skills.
3. Maintain hot cache and index/log updates after every operation.
4. Use frontmatter, wikilinks, and the forward-only hub model.
5. Never modify `.raw/`.
