# Hot Cache Protocol

`wiki/hot.md` is a ~500-word recency cache. It lets any session restore recent context without crawling the full wiki. This document is the single source of truth for when to read it, when to update it, and what to put in it.

Read this file when a skill needs to understand hot-cache behavior. Do not preload — read on demand.

---

## When to Read

| Trigger | Action |
|---------|--------|
| Session start | Read `wiki/hot.md` silently. Do not announce. Do not report what was read. Just have the context. |
| Post-compaction | Re-read `wiki/hot.md`. Hook-injected context does not survive compaction — this restores it. |
| Pre-query (any mode) | Read `wiki/hot.md` first. If it answers the question, respond without opening other pages. |

The hot cache costs ~500 tokens. Reading it first is always cheaper than reading index or individual pages.

---

## When to Update

Update `wiki/hot.md` at the end of every operation that changes wiki content. **The orchestrator writes, once, after all parallel workers have reported.** Never update mid-operation or from within a worker.

| Operation | Who updates | When |
|-----------|-------------|------|
| Single source ingest | Orchestrator (not individual ingest agents) | After all pages are written |
| Batch ingest | Orchestrator | Once at the end, not per-source |
| Autoresearch | Autoresearch skill | After all pages are filed |
| Save | Save skill | After the note is created |
| Query (if answer was filed) | Query skill | After filing the answer as a wiki page |
| Lint (if fixes were applied) | Lint skill | After the lint report is written and any auto-fixes are committed |
| Session end (wiki changed) | Agent | Before the session closes |

Do not skip the hot cache update at the end of an ingest or autoresearch session. It is what keeps future sessions fast.

---

## Format

Overwrite `wiki/hot.md` completely each time — it is a cache, not a journal.

```markdown
---
type: meta
title: "Hot Cache"
updated: YYYY-MM-DDTHH:MM:SS
---

# Recent Context

## Last Updated
YYYY-MM-DD. [what happened in one phrase]

## Key Recent Facts
- [Most important recent takeaway]
- [Second most important]
- [Third if needed]

## Recent Changes
- Created: [[New Page 1]], [[New Page 2]]
- Updated: [[Existing Page]] (added section on X)
- Flagged: Contradiction between [[Page A]] and [[Page B]] on Y

## Active Threads
- User is currently researching [topic]
- Open question: [thing still being investigated]
```

**Rules:**
- Under 500 words. Trim aggressively.
- Factual, not narrative. No "the user asked..." phrasing.
- Overwrite completely. Never append.
- Wikilinks in `## Recent Changes` must match real page filenames.

---

## Parallel Worker Discipline

Parallel workers, whether Task-tool subagents (see `${CLAUDE_PLUGIN_ROOT}/agents/ingest.md`) or TeamCreate teammates, must NOT update `wiki/hot.md`. Only the orchestrating session updates it, once, after all workers have reported back. This prevents race conditions and conflicting writes.
