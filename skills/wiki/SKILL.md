---
name: wiki
description: Knowledge companion. Bootstraps vault, scaffolds structure, routes to sub-skills.
when_to_use: Use to bootstrap the vault (`/wiki init`) or scaffold its structure. Routes to sub-skills for domain operations.
model: opus
effort: medium
user-invocable: true
allowed-tools: Bash Read
---
Build and maintain persistent, compounding wiki in Obsidian vault. Wiki is product; chat is interface.

## I/O
- Input: User request (init, scaffold, promote tag, or route to sub-skill).
- Output: Vault structure, wiki pages, or sub-skill dispatch.

## Process
1. **Route**: Map user request to sub-skill — `/wiki init` → wiki, "ingest" → `Skill("ingest")`, "query this" → `Skill("query")`, "lint" → `Skill("lint")`, "/save" → `Skill("save")`, "/note" → `Skill("notes")`, "/autoresearch" → `Skill("autoresearch")`, "/canvas" → `Skill("canvas")`, "/daily" → `Skill("daily")`, "/daily-close" → `Skill("daily-close")`.
2. **INIT**: `bash "${CLAUDE_PLUGIN_ROOT}/bin/wiki-init.sh" "${user_config.vault_path}"` — idempotent vault bootstrap.
3. **SCAFFOLD**: Ask "What is this vault for?" → create folders (`concepts/`, `entities/`, `sources/`, `solutions/`, `comparisons/`, `questions/`), `index.md`, `log.md`, `hot.md`, `notes/`, `daily/`, `_templates/`, `.obsidian/snippets/`, vault `CLAUDE.md`.
4. **PROMOTE**: `/wiki promote <tag>` → collect leaves with matching tag → bail if <5 leaves or hub exists → create hub at `wiki/domains/<tag>/_index.md` → register in index.
5. **Maintain**: Update hot cache and index/log after every operation.

## Rules
- Never modify `.raw/`.
- Forward-only hubs: promote roads, not gardens.
- Cross-project: add vault reference pointer to other projects' CLAUDE.md.
