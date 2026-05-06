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

## Vault I/O

This skill reads templates and existing pages, creates a new note, prepends entries to `wiki/log.md` and `wiki/index.md`, and overwrites `wiki/hot.md`. All operations go through the `obsidian` CLI.

See `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md` for verb syntax, the `overwrite` flag, and multiline `content=` escaping.

---

## Note Type Decision

Determine the best type from the conversation content:

| Type      | Folder          | Use when                                                          |
| --------- | --------------- | ----------------------------------------------------------------- |
| synthesis | wiki/questions/ | Multi-step analysis, comparison, or answer to a specific question |
| concept   | wiki/concepts/  | Explaining or defining an idea, pattern, or framework             |
| source    | wiki/sources/   | Summary of external material discussed in the session             |
| decision  | wiki/meta/      | Architectural, project, or strategic decision that was made       |
| session   | wiki/meta/      | Full session summary: captures everything discussed               |

If the user specifies a type, use that. If not, pick the best fit based on the content. When in doubt, use `synthesis`.

---

## Save Workflow

1. **Scan** the current conversation. Identify the most valuable content to preserve.
2. **Ask** (if not already named): "What should I call this note?" Keep the name short and descriptive.
3. **Determine** note type using the table above.
4. **Extract** all relevant content from the conversation. Rewrite it in declarative present tense (not "the user asked" but the actual content itself).
5. **Create** the note. Generate the filename slug via `bash ${CLAUDE_PLUGIN_ROOT}/scripts/slug.sh "<title>"` and use the result as `<slug>` in the path — do not hand-craft the slug, the script normalizes Unicode, trailing `.md`, and runs of separators:
   ```bash
   slug=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/slug.sh" "<title>")
   obsidian create \
     path=wiki/<folder>/$slug.md \
     content="<frontmatter + body, with \n for newlines>"
   ```
6. **Collect links**: identify any wiki pages mentioned in the conversation. Include them in `related` in the frontmatter you pass via `content=`.
7. **Update** `wiki/index.md`. Use a read-splice-overwrite pattern to insert the entry under the correct section heading.

   **Type → section** (deterministic; do not choose freehand):

   | Note type   | Target section                                                         |
   | ----------- | ---------------------------------------------------------------------- |
   | `concept`   | `## Concepts`                                                          |
   | `source`    | `## Sources`                                                           |
   | `decision`  | `## Plans & Decisions`                                                 |
   | `synthesis` | `## Questions`                                                         |
   | `session`   | _(skip — not indexed; chronology lives in `wiki/log.md` and `daily/`)_ |

   **Entry format:** `- [[<slug>|<Display Name>]] — <one-line description>`
   Omit `|<Display Name>` when the display name matches the slug exactly (after converting hyphens/underscores to spaces and title-casing).

   **Pattern:** delegate the read-splice-overwrite to `scripts/index-section-insert.sh`. It reads via `obsidian read`, splices the entry on the line immediately after the matching heading, and writes back via `obsidian create overwrite=true`. If the heading is absent, the script appends `<heading>\n<entry>` at the end of the file.

   ```bash
   # section is determined from the type table above
   new_entry="- [[$slug|$display_name]] — $description"
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/index-section-insert.sh" \
     wiki/index.md "$section" "$new_entry"
   ```

8. **Prepend** the latest entry to `wiki/log.md` (new entry goes at the TOP):
   ```bash
   obsidian prepend \
     file=wiki/log.md \
     content="## [YYYY-MM-DD] save | Note Title\n- Type: [note type]\n- Location: wiki/[folder]/Note Title.md\n- From: conversation on [brief topic description]\n\n"
   ```
9. **Rewrite** `wiki/hot.md` (use the `overwrite` flag). Follow the format in `${CLAUDE_PLUGIN_ROOT}/_shared/hot-cache-protocol.md`.
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

### Forward-only hub membership

Do **not** write a `domain:` field on any leaf you save. Hub membership is forward-only — the `wiki/domains/<slug>/_index.md` hub is responsible for linking out to its leaves; the leaf does not declare which hub it belongs to. The leaf's tags are enough for `/lint` and `/wiki promote` to discover it later. If a relevant hub already exists, append the new leaf to that hub's `related:` list as a separate operation; do not encode the relationship on the leaf.

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
