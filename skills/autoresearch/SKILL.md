---
name: autoresearch
description: >
  Autonomous iterative research loop. Takes a topic, runs web searches, fetches sources,
  synthesizes findings, and files everything into the wiki as structured pages.
  Based on Karpathy's autoresearch pattern: program.md configures objectives and constraints,
  the loop runs until depth is reached, output goes directly into the knowledge base.
  Triggers on: "/autoresearch", "autoresearch", "research [topic]", "deep dive into [topic]",
  "investigate [topic]", "find everything about [topic]", "research and file",
  "go research", "build a wiki on".
allowed-tools: Bash Read Glob Grep WebFetch WebSearch
---

# autoresearch: Autonomous Research Loop

You are a research agent. You take a topic, run iterative web searches, synthesize findings, and file everything into the wiki. The user gets wiki pages, not a chat response.

This is based on Karpathy's autoresearch pattern: a configurable program defines your objectives. You run the loop until depth is reached. Output goes into the knowledge base.

---

## Before Starting

Read `references/program.md` to load the research objectives and constraints. This file is user-configurable. It defines what sources to prefer, how to score confidence, and any domain-specific constraints.

---

## Vault I/O

All vault writes (sources, concepts, entities, synthesis page, index, log, hot cache) go through the `obsidian` CLI. See `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md` for verbs, output formats, multiline `content=` escaping, and exception paths.

---

## Research Loop

```
Input: topic (from user command)

Round 1. Broad search
1. Decompose topic into 3-5 distinct search angles
2. For each angle: run 2-3 WebSearch queries
3. For top 2-3 results per angle: WebFetch the page
4. Extract from each: key claims, entities, concepts, open questions

Round 2. Gap fill
5. Identify what's missing or contradicted from Round 1
6. Run targeted searches for each gap (max 5 queries)
7. Fetch top results for each gap

Round 3. Synthesis check (optional, if gaps remain)
8. If major contradictions or missing pieces still exist: one more targeted pass
9. Otherwise: proceed to filing

Max rounds: 3 (as set in program.md). Stop when depth is reached or max rounds hit.
```

---

## Filing Results

After research is complete, create these pages:

**wiki/sources/**. One page per major reference found
- Use source frontmatter (type, source_type, author, date_published, url, confidence, key_claims)
- Body: summary of the source, what it contributes to the topic

**wiki/concepts/**. One page per significant concept extracted
- Only create a page if the concept is substantive enough to stand alone
- Check the index first: update existing concept pages rather than creating duplicates

**wiki/entities/**. One page per significant person, org, or product identified
- Check the index first: update existing entity pages

**wiki/questions/**. One synthesis page titled "Research: [Topic]"
- This is the master synthesis. Everything comes together here.
- Sections: Overview, Key Findings, Entities, Concepts, Contradictions, Open Questions, Sources
- Full frontmatter with related links to all pages created in this session

**wiki/trails/**. Exactly one `type: trail` page per run, regardless of atomic-note count
- Filename: `wiki/trails/Trail: [Topic] (YYYY-MM-DD).md` (the date suffix uses the run date, so multiple runs on the same topic produce distinct files — never merge or overwrite).
- Emit immediately **after** the synthesis page is written and **before** any `## After Filing` step (index, log, hot.md). The index and log entries naturally pick the trail up from this position.
- Body is an ordered Markdown list. One step per atomic note created in this run, in argument order. Each step has exactly one `[[wikilink]]` to that atomic note plus a single LLM-synthesized one-line annotation describing the note's role in the argument (why this note next, what it contributes).
- No minimum atomic-note count. A run that produced one note still emits a one-step trail — the run-record value beats the empty-trail cost.
- Create `wiki/trails/` lazily on first emission if it does not exist.

---

## Synthesis Page Structure

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

---

## Trail Page Structure

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

The body must be a single ordered list. Each list item must contain exactly one `[[wikilink]]` to an atomic note created in this run plus exactly one annotation describing the note's argument role. No URLs, no bare-text steps, no nested lists, no prose paragraphs between items — keep the trail's argument-path semantics tight.

`status: mature` reflects that trails are frozen at write time and never edited; the run produced what the run produced. `confidence: EXTRACTED` because the trail records run output, not inference. Use `evidence:` to list the atomic notes (the same wikilinks that appear in the body, in order).

---

## After Filing

1. Update `wiki/index.md`. Add all new pages to the right sections
2. Append to `wiki/log.md` (at the TOP):
   ```
   ## [YYYY-MM-DD] autoresearch | [Topic]
   - Rounds: N
   - Sources found: N
   - Pages created: [[Page 1]], [[Page 2]], ...
   - Synthesis: [[Research: Topic]]
   - Trail: [[Trail: Topic (YYYY-MM-DD)]]
   - Key finding: [one sentence]
   ```
3. Update `wiki/hot.md` with the research summary. For the full hot-cache protocol (when to read, when to update, sub-agent discipline), see `${CLAUDE_PLUGIN_ROOT}/_shared/hot-cache-protocol.md`.

---

## Report to User

After filing everything:

```
Research complete: [Topic]

Rounds: N | Searches: N | Pages created: N

Created:
  wiki/questions/Research: [Topic].md (synthesis)
  wiki/trails/Trail: [Topic] (YYYY-MM-DD).md (reading order)
  wiki/sources/[Source 1].md
  wiki/concepts/[Concept 1].md
  wiki/entities/[Entity 1].md

Key findings:
- [Finding 1]
- [Finding 2]
- [Finding 3]

Open questions filed: N
```

---

## Constraints

Follow the limits in `references/program.md`:
- Max rounds (default: 3)
- Max pages per session (default: 15)
- Confidence scoring rules
- Source preference rules

If a constraint conflicts with completeness, respect the constraint and note what was left out in the Open Questions section.
