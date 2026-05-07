---
name: wiki
description: Knowledge companion. Bootstraps vault, scaffolds structure, routes to sub-skills.
when_to_use: Use to bootstrap the vault (`/wiki init`) or scaffold its structure. Routes to sub-skills for domain operations.
allowed-tools: Bash Read
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
|-|-|-|
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
User describes vault purpose → Execute:
1. Ask: "What is this vault for?" (one question, then proceed).
2. Scaffold flat folders under `wiki/`: `concepts/`, `entities/`, `sources/`, `solutions/`, `comparisons/`, `questions/`. No per-folder `_index.md`.
3. Create `wiki/index.md`, `wiki/log.md`, `wiki/hot.md`.
4. Create `notes/` and copy `_seed/notes/index.md` if missing.
5. Create `daily/` and copy `_seed/daily/example-daily.md` if directory is missing.
6. Create `_templates/` files for each note type.
7. Create `.obsidian/snippets/vault-colors.css` with standard callout styles.
8. Create vault `CLAUDE.md` pointing agents at the vault.
9. Initialize git (`git init && git add -A && git commit -m "Initial vault scaffold"`).
10. Present structure and ask: "Want to adjust anything before we start?"

### PROMOTE
`/wiki promote <tag>` → Execute:
1. Resolve tag slug (kebab-case, strip leading `#`).
2. Collect all leaves with `tags:` containing the resolved tag across `wiki/concepts/`, `wiki/entities/`, `wiki/sources/`.
3. Bail if fewer than 5 leaves: report count, suggest growing the cluster.
4. Bail if `wiki/domains/<tag>/_index.md` already exists.
5. Create hub at `wiki/domains/<tag>/_index.md` with `type: domain` frontmatter and `related:` list of all cluster leaves.
6. Register hub in `wiki/index.md` under `## Domains`.
7. Log in `wiki/log.md`.

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
