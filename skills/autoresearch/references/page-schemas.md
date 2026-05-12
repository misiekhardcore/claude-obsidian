# Autoresearch Page Schemas

## Synthesis Page Template

```markdown
---
type: synthesis
title: "Research: [Topic]"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - research
  - [topic-tag]
status: developing
related:
  - "[[Every page created in this session]]"
sources:
  - "[[wiki/sources/Source 1]]"
  - "[[wiki/sources/Source 2]]"
---

# Research: [Topic]

## Overview

[2-3 sentence summary of what was found]

## Key Findings

- Finding 1 (Source: [[Source Page]])
- Finding 2 (Source: [[Source Page]])
- ...

## Key Entities

- [[Entity Name]]: role/significance

## Key Concepts

- [[Concept Name]]: one-line definition

## Contradictions

- [[Source A]] says X. [[Source B]] says Y. [Brief note on which is more credible and why]

## Open Questions

- [Question that research didn't fully answer]
- [Gap that needs more sources]

## Sources

- [[Source 1]]: author, date
- [[Source 2]]: author, date
```

## Trail Page Template

```markdown
---
type: trail
title: "Trail: [Topic] (YYYY-MM-DD)"
topic: "<topic-slug>"
research_run: YYYY-MM-DD
synthesis: "[[Research: Topic]]"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - trail
  - [topic-tag]
status: mature
confidence: EXTRACTED
evidence:
  - "[[Atomic Note 1]]"
  - "[[Atomic Note 2]]"
---

# Trail: [Topic] (YYYY-MM-DD)

Reading order for the [[Research: Topic]] run on YYYY-MM-DD. One step per atomic note; the annotation explains the note's argument role.

1. [[Atomic Note 1]] — opens the question by establishing X.
2. [[Atomic Note 2]] — sharpens X into the testable claim Y.
3. [[Atomic Note 3]] — surfaces the counter-evidence that constrains Y to its scope.
4. [[Atomic Note 4]] — resolves the constraint by introducing mechanism Z.
```

### Trail Body Format Rules

- Exactly one ordered list (`1.`, `2.`, …). No prose paragraphs between items, no nested lists, no multiple top-level lists.
- Each item: exactly one `[[wikilink]]` to an atomic note + plain-text annotation (no URLs, no extra wikilinks, inline formatting OK).
- `status: mature` (frozen at write time, never edited). `confidence: EXTRACTED` (records run output, not inference).
- `evidence:` lists atomic notes in order (matches body wikilinks).
