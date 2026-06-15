---
name: save
description: Save conversation/insight/note as structured wiki page. Updates index, log, hot cache.
when_to_use: Non-obvious synthesis, rationale, research findings. Creates permanent wiki pages. All five steps are mandatory.
model: sonnet
effort: medium
user-invocable: true
allowed-tools: Bash Read
---
File conversations into wiki as permanent pages. Determines note type, files it, updates index/log/hot-cache.

## I/O
- Input: Conversation context, insight, or user-specified content.
- Output: Wiki page at `wiki/<folder>/<slug>.md`, index entry, log entry, hot cache update.

## Process
1. **Classify**: Determine note type — `synthesis` (default), `concept`, `source`, `decision`, or `session`. See `_shared/frontmatter.md` for field schemas.
2. **Slug**: Derive via `bash ${CLAUDE_PLUGIN_ROOT}/scripts/slug.sh "<title>"`.
3. **Create**: `obsidian create path=wiki/<folder>/<slug>.md content="<frontmatter + body>"`.
4. **Index**: Insert entry into `wiki/index.md` using `scripts/index-section-insert.sh` per type→section mapping.
5. **Log & Cache**: Prepend to `wiki/log.md`, overwrite `wiki/hot.md` per `_shared/hot-cache-protocol.md`.

## Rules
- All five steps mandatory. Never stop after step 3.
- Declarative present tense. Self-contained. Hyperlinked.
- Skip mechanical Q&A, documented setup, temporary debugging — update existing pages instead.
- Do not write `domain:` on leaves. Hub membership is managed by the hub.
