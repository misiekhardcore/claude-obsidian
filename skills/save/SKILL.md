---
name: save
description: >
  Save the current conversation, answer, or insight into the Obsidian wiki vault as a
  structured note. Analyzes the chat, determines the right note type, creates frontmatter,
  files it in the correct wiki folder, and updates index, log, and hot cache.
  Triggers on: "save this", "save that answer", "/save", "file this",
  "save to wiki", "save this session", "file this conversation", "keep this",
  "save this analysis", "add this to the wiki".
allowed-tools: Bash Read Glob Grep
---

# save: File Conversations Into the Wiki

Good answers and insights shouldn't disappear into chat history. This skill takes what was just discussed and files it as a permanent wiki page.

The wiki compounds. Save often.

## Vault Writes Use the CLI Wrapper

All vault reads and writes go through `${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh`, not Read/Write/Edit. The wrapper resolves the vault, normalizes exit codes, and ensures Obsidian's index is consistent with disk. Contract: `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md`.

| Op | Wrapper invocation |
|---|---|
| Read template / existing page | `${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh read path=<path>` |
| Create new wiki page | `${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh create path=wiki/<category>/<slug>.md content="<body>"` |
| Append to operations log | `${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh append path=wiki/log.md content="<entry>"` |
| Prepend to master index | `${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh prepend file=wiki/index.md content="<entry>"` |
| Rewrite hot cache | `${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh create path=wiki/hot.md content="<body>" overwrite` |

Multiline content uses the CLI's `\n` escape (round-trip verified empirically — see `tests/spike-results/rmw-mutate-diff.out`). If a future spike reveals the round-trip is broken, fall back to `obsidian create source=/tmp/staging.md path=wiki/...` per `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md`.

`Read` is retained only for resources outside the vault. The skill no longer needs `Write` or `Edit`.

---

## Note Type Decision

Determine the best type from the conversation content:

| Type | Folder | Use when |
|------|--------|---------|
| synthesis | wiki/questions/ | Multi-step analysis, comparison, or answer to a specific question |
| concept | wiki/concepts/ | Explaining or defining an idea, pattern, or framework |
| source | wiki/sources/ | Summary of external material discussed in the session |
| decision | wiki/meta/ | Architectural, project, or strategic decision that was made |
| session | wiki/meta/ | Full session summary: captures everything discussed |

If the user specifies a type, use that. If not, pick the best fit based on the content. When in doubt, use `synthesis`.

---

## Save Workflow

1. **Scan** the current conversation. Identify the most valuable content to preserve.
2. **Ask** (if not already named): "What should I call this note?" Keep the name short and descriptive.
3. **Determine** note type using the table above.
4. **Extract** all relevant content from the conversation. Rewrite it in declarative present tense (not "the user asked" but the actual content itself).
5. **Create** the note via the wrapper:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh create \
     path=wiki/<folder>/<slug>.md \
     content="<frontmatter + body, with \n for newlines>"
   ```
6. **Collect links**: identify any wiki pages mentioned in the conversation. Include them in `related` in the frontmatter you pass via `content=`.
7. **Update** `wiki/index.md`. Prepend the new entry under the relevant section:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh prepend \
     file=wiki/index.md \
     content="- [[<slug>]]: <one-line description>\n"
   ```
8. **Append** to `wiki/log.md`. New entry at the TOP via the wrapper:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh prepend \
     file=wiki/log.md \
     content="## [YYYY-MM-DD] save | Note Title\n- Type: [note type]\n- Location: wiki/[folder]/Note Title.md\n- From: conversation on [brief topic description]\n\n"
   ```
9. **Rewrite** `wiki/hot.md` via `obsidian-cli.sh create path=wiki/hot.md content="..." overwrite`. Follow the format in `${CLAUDE_PLUGIN_ROOT}/_shared/hot-cache-protocol.md`. Multiline content uses `\n` escapes.
10. **Confirm**: "Saved as [[Note Title]] in wiki/[folder]/."

---

## Frontmatter Template

```yaml
---
type: <synthesis|concept|source|decision|session>
title: "Note Title"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - <relevant-tag>
status: developing
related:
  - "[[Any Wiki Page Mentioned]]"
sources:
  - "[[.raw/source-if-applicable.md]]"
---
```

For `question` type, add:
```yaml
question: "The original query as asked."
answer_quality: solid
```

For `decision` type, add:
```yaml
decision_date: YYYY-MM-DD
status: active
```

---

## Writing Style

- Declarative, present tense. Write the knowledge, not the conversation.
- Not: "The user asked about X and Claude explained..."
- Yes: "X works by doing Y. The key insight is Z."
- Include all relevant context. Future sessions should be able to read this page cold.
- Link every mentioned concept, entity, or wiki page with wikilinks.
- Cite sources where applicable: `(Source: [[Page]])`.

---

## What to Save vs. Skip

Save:
- Non-obvious insights or synthesis
- Decisions with rationale
- Analyses that took significant effort
- Comparisons that are likely to be referenced again
- Research findings

Skip:
- Mechanical Q&A (lookup questions with obvious answers)
- Setup steps already documented elsewhere
- Temporary debugging sessions with no lasting insight
- Anything already in the wiki

If it's already in the wiki, update the existing page instead of creating a duplicate.
