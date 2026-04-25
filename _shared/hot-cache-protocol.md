# Hot Cache Protocol

`wiki/hot.md` is a ~500-word recency cache. It lets any session restore recent context without crawling the full wiki. This document is the single source of truth for when to read it, when to update it, and what to put in it.

Read this file when a skill needs to understand hot-cache behavior. Do not preload — read on demand.

---

## When to Read

| Trigger | Action |
|---------|--------|
| Session start (when `bootstrap_read_hot=always`) | `wiki/hot.md` was injected by the hook — silently absorb the context. Do not announce. |
| Session start (when `bootstrap_read_hot=on-demand` or `never`) | No injection occurred. Wiki skills read `wiki/hot.md` when they activate. |
| Post-compaction (when `bootstrap_read_hot=always`) | Re-read `wiki/hot.md`. Hook-injected context does not survive compaction — this restores it. |
| Pre-query (any mode, unless `never`) | Read `wiki/hot.md` first. If it answers the question, respond without opening other pages. |

The hot cache costs ~500 tokens. Reading it first is always cheaper than reading index or individual pages.

---

## Auto-Read Gating

The `claude-obsidian.bootstrap_read_hot` plugin config key controls whether `wiki/hot.md` is injected at session start and post-compaction. Set it via `/plugin manage` or by editing `~/.claude/settings.local.json`.

| Value | Hook behavior | Skill behavior |
|-------|---------------|----------------|
| `always` | Inject `wiki/hot.md` on SessionStart and PostCompact | Skills read hot.md as usual |
| `on-demand` *(default)* | Skip injection | Skills read hot.md when they activate |
| `never` | Skip injection | Skills should also avoid auto-reading hot.md |

**Why the default is `on-demand`:** At ~2–3k tokens/turn, always injecting `wiki/hot.md` is a hidden per-session cost that accumulates across all sessions — including unrelated coding work. Wiki skills already read hot.md on activation, so `on-demand` preserves the benefit for wiki sessions while eliminating the cost for everything else. Restore the previous behavior with `bootstrap_read_hot: "always"`.

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
| Lint (if fixes were applied) | Lint skill | After the lint report is written and any auto-fixes are applied |
| Session end (wiki changed) | Agent | Before the session closes |

Do not skip the hot cache update at the end of an ingest or autoresearch session. It is what keeps future sessions fast.

---

## Format

Overwrite `wiki/hot.md` completely each time — it is a cache, not a journal.

```markdown
---
type: meta
title: "Hot Cache"
updated: YYYY-MM-DD
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
