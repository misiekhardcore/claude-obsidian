#!/usr/bin/env bash
# Seed a vault with starter stub files and one example per page type.
# Skips any file that already exists (idempotent).
#
# Usage: bin/seed-demo.sh /absolute/path/to/vault
#
# Called by wiki-init.sh. Can also be run standalone.
#
# Note: this script does not derive CLAUDE_PLUGIN_ROOT (unlike peer scripts
# such as copy-templates.sh). It writes only to $VAULT and reads no plugin
# files, so the plugin root is not needed.

set -euo pipefail

VAULT="${1:-}"

if [ -z "$VAULT" ]; then
  echo "Configure vault path first: enable the plugin and enter your vault path when prompted"
  exit 0
fi

TODAY=$(date +%Y-%m-%d)

seed_file() {
  local path="$VAULT/$1"
  [ -e "$path" ] && return 0
  mkdir -p "$(dirname "$path")"
  cat > "$path"
}

# ── Structural stubs ──────────────────────────────────────────────────────────

seed_file "wiki/index.md" << EOF
---
type: meta
title: "Wiki Index"
created: $TODAY
updated: $TODAY
tags:
  - meta
  - index
status: evergreen
confidence: EXTRACTED
evidence: []
related:
  - "[[hot]]"
  - "[[log]]"
  - "[[overview]]"
---

# Wiki Index

Master catalog of all pages in this knowledge base.

## Domains

<!-- List domain pages here as they are created -->

## Core Types

| Type | Directory | Purpose |
|------|-----------|---------|
| concept | wiki/concepts/ | Patterns, techniques, ideas |
| entity | wiki/entities/ | Named real-world things |
| source | wiki/sources/ | Ingested source records |
| question | wiki/questions/ | Open and answered questions |

## Navigation

- [[hot]] — recent context cache (read first each session)
- [[log]] — chronological operations log
- [[overview]] — executive summary of this vault
EOF

seed_file "wiki/hot.md" << EOF
---
type: meta
title: "Hot Cache"
updated: $TODAY
---

# Recent Context

> **Demo content** — this file is overwritten at the end of every wiki operation.
> It shows what a populated hot cache looks like. Delete this notice once your
> first real ingest has run and replaced this content.

## Last Updated
$TODAY. Vault initialized with starter pages via \`/wiki init\`.

## Key Recent Facts

This vault uses a four-layer wiki schema: **sources** capture what documents say,
**entities** record named real-world things, **concepts** synthesize patterns across
sources, and **questions** track open and answered queries. All pages carry
\`confidence:\` (EXTRACTED | INFERRED | AMBIGUOUS) and an \`evidence:\` list so
claims can be traced to their origin.

The **hot cache** (this file) is the cheapest entry point for any session — it
answers "what happened recently?" without opening the full index. Claude reads it
silently at session start. Keep it under 500 words and overwrite it completely
after every operation.

The **index** ([[index]]) is the master catalog; the **log** ([[log]]) is the
chronological record of operations; **overview** ([[overview]]) is the
executive summary of what this vault covers.

## Recent Changes

- Created: [[example-concept]] — concept stub demonstrating the schema
- Created: [[example-entity]] — entity stub demonstrating typed relationships
- Created: [[example-source]] — source stub with key_claims and reliability rating
- Created: [[example-question]] — question stub with answer_quality field
- Created: [[index]], [[log]], [[overview]] — structural meta pages
- Created: FIRST_RUN.md — onboarding guide at vault root

## Active Threads

- Vault is freshly initialized; no research threads yet
- Next step: run \`/wiki ingest <path-or-url>\` to add your first real source
- Example pages are placeholders — delete them once you've ingested real content

## Schema Quick Reference

| Page type | Directory | confidence default | evidence required? |
|-----------|-----------|--------------------|--------------------|
| source | wiki/sources/ | EXTRACTED | No |
| concept | wiki/concepts/ | INFERRED | Yes |
| entity | wiki/entities/ | INFERRED | Yes |
| question | wiki/questions/ | INFERRED | Yes |
| meta | wiki/ | EXTRACTED | No |
EOF

seed_file "wiki/log.md" << EOF
---
type: meta
title: "Operations Log"
created: $TODAY
updated: $TODAY
tags:
  - meta
  - log
status: evergreen
confidence: EXTRACTED
evidence: []
related:
  - "[[hot]]"
  - "[[index]]"
---

# Operations Log

Chronological record of all wiki operations in this vault.

## $TODAY

- Vault initialized via \`/wiki init\`
- Seeded starter pages: [[example-concept]], [[example-entity]], [[example-source]], [[example-question]]

---

<!-- New entries prepend to this file. Format: ## YYYY-MM-DD then bullet list of actions. -->
EOF

seed_file "wiki/overview.md" << EOF
---
type: meta
title: "Wiki Overview"
created: $TODAY
updated: $TODAY
tags:
  - meta
  - overview
status: seed
confidence: EXTRACTED
evidence: []
related:
  - "[[index]]"
  - "[[hot]]"
---

# Wiki Overview

Executive summary of this knowledge base: what it covers, how it is organized, and what is most useful.

## Purpose

<!-- What domains and topics does this vault cover? What is it for? -->

## Key Themes

<!-- The 3-5 most important ideas or insights across the vault -->

## Status

| Metric | Value |
|--------|-------|
| Created | $TODAY |
| Total pages | — |
| Domains | — |
| Open questions | — |

## Start Here

- [[hot]] — most recent context
- [[index]] — full page catalog
- [[log]] — history of changes
EOF

# ── Example pages ─────────────────────────────────────────────────────────────

seed_file "wiki/concepts/example-concept.md" << EOF
---
type: concept
title: "Example Concept"
complexity: intermediate
domain: "knowledge-management"
aliases:
  - "concept stub"
created: $TODAY
updated: $TODAY
tags:
  - concept
  - example
status: seed
confidence: INFERRED
evidence:
  - "[[example-source]]"
related:
  - "[[example-entity]]"
  - "[[example-question]]"
uses:
  - "[[example-source]]"
---

# Example Concept

## Definition

A concept page captures a pattern, technique, or idea — not a specific person, tool, or document. It synthesizes understanding from one or more sources into a reusable explanation.

## How It Works

Concept pages are populated by the \`/wiki ingest\` and \`/wiki autoresearch\` skills. When a source is ingested, the LLM extracts patterns and creates or updates concept pages.

## Why It Matters

Separating concepts from entities and sources lets you build a knowledge graph where ideas are first-class citizens, not just footnotes to documents.

## Examples

- This page itself is an example of a concept page
- See [[example-entity]] for how a named thing is recorded
- See [[example-source]] for how a document is captured

## Sources

- [[example-source]]
EOF

seed_file "wiki/entities/example-entity.md" << EOF
---
type: entity
title: "Example Entity"
entity_type: person
role: "Illustrative example"
first_mentioned: "[[example-source]]"
created: $TODAY
updated: $TODAY
tags:
  - entity
  - example
status: seed
confidence: INFERRED
evidence:
  - "[[example-source]]"
related:
  - "[[example-concept]]"
  - "[[example-question]]"
---

# Example Entity

## Overview

An entity page records a named real-world thing: a person, tool, organization, product, or repository. Unlike concept pages, entities are proper nouns — they refer to something specific that exists or existed.

## Key Facts

- Entity type is set in frontmatter (\`entity_type\`)
- The \`first_mentioned\` field links to the source where this entity first appeared
- Use [[example-concept]] as context for how this entity relates to broader patterns

## Connections

- Mentioned in: [[example-source]]
- Related concept: [[example-concept]]

## Sources

- [[example-source]]
EOF

seed_file "wiki/sources/example-source.md" << EOF
---
type: source
title: "Example Source"
source_type: article
author: ""
date_published: $TODAY
url: ""
source_reliability: high
key_claims:
  - "Source pages capture what was found in a document, not inferences from it"
  - "Each source gets its own page, linked from any concept or entity it informs"
created: $TODAY
updated: $TODAY
tags:
  - source
  - example
status: seed
confidence: EXTRACTED
evidence: []
related:
  - "[[example-concept]]"
  - "[[example-entity]]"
  - "[[example-question]]"
---

# Example Source

## Summary

A source page is the ingest record for a single document. It holds the document's metadata, a summary, and the key claims extracted from it. Downstream concept and entity pages link back here as their evidence.

## Key Claims

- Source pages use \`confidence: EXTRACTED\` because they summarize what is directly in the document
- The \`key_claims\` frontmatter field holds the most important findings as a flat list
- \`source_reliability\` captures how trustworthy the source itself is (high / medium / low)

## Entities Mentioned

- [[example-entity]] — illustrates how entities are linked from source pages

## Concepts Introduced

- [[example-concept]] — illustrates how concepts are linked from source pages

## Notes

Replace this page with a real source by running \`/wiki ingest\` on a document.
EOF

seed_file "wiki/questions/example-question.md" << EOF
---
type: question
title: "What is a wiki question page for?"
question: "What is a wiki question page for?"
answer_quality: solid
created: $TODAY
updated: $TODAY
tags:
  - question
  - example
status: developing
confidence: INFERRED
evidence:
  - "[[example-source]]"
related:
  - "[[example-concept]]"
  - "[[example-entity]]"
---

# What is a wiki question page for?

**Question:** What is a wiki question page for?

## Answer

Question pages capture open or answered queries about the domain. They serve as explicit tracking for things you were uncertain about, allowing you to record the answer once and link to it from anywhere.

Use question pages when:
- You want to record an answer that required research
- You want to track an open question for future investigation
- You want to make implicit knowledge explicit

When a question is answered, set \`answer_quality\` to \`solid\` or \`definitive\` and link to the supporting evidence.

(Source: [[example-concept]], [[example-source]])

## Confidence

solid — this reflects the vault schema design, directly observable from the plugin structure.

## Related Questions

- How do concept pages differ from source pages? (open)
EOF

# ── FIRST_RUN.md ──────────────────────────────────────────────────────────────

seed_file "FIRST_RUN.md" << 'FIRSTRUN'
# First Run Guide

Welcome to your claude-obsidian vault. Follow these steps to get fully set up.

---

## 1. Open in Obsidian

1. Open Obsidian
2. **Manage Vaults → Open folder as vault**
3. Select this directory

---

## 2. Enable Community Plugins

When Obsidian opens, it will warn that community plugins are disabled.

1. Go to **Settings → Community Plugins**
2. Turn off Safe Mode (required for community plugins)

---

## 3. Install Required Plugins

In **Settings → Community Plugins → Browse**, install:

| Plugin | Purpose |
|--------|---------|
| **Dataview** | Query your wiki pages as a database |
| **Templater** | Use the templates in `_templates/` to create new pages |
| **Obsidian Git** | Sync vault changes to git automatically |

---

## 4. Explore the Starter Content

Your vault includes one example page per core type — open them to see the schema in action:

- `wiki/concepts/example-concept.md` — patterns and ideas
- `wiki/entities/example-entity.md` — named real-world things
- `wiki/sources/example-source.md` — ingested document records
- `wiki/questions/example-question.md` — open and answered questions

Structural pages:

- `wiki/hot.md` — recent-context cache (Claude reads this first each session)
- `wiki/index.md` — master page catalog
- `wiki/log.md` — chronological operations log
- `wiki/overview.md` — executive summary of the vault

---

## 5. Start Using the Wiki

In Claude Code, type `/wiki` to see all available wiki operations.

**Common first steps:**

```
/wiki ingest <path-or-url>   — ingest a document and extract wiki pages
/wiki query <question>       — ask a question answered from vault content
/wiki scaffold               — customize the vault structure for your domain
```

---

## 6. Delete the Example Pages (when ready)

Once you understand the schema, delete the example pages:

```
wiki/concepts/example-concept.md
wiki/entities/example-entity.md
wiki/sources/example-source.md
wiki/questions/example-question.md
```

Keep the structural pages (`hot.md`, `index.md`, `log.md`, `overview.md`).

---

*Generated by claude-obsidian on first `/wiki init`.*
FIRSTRUN

echo "✓ Demo vault seeded at: $VAULT"
