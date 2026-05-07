# Hot Cache Protocol

`wiki/hot.md` is a ~500-word recency cache for session context restoration.

Read on demand.

## When to Read

|Trigger|Action|
|-|-|
|Session start (when `bootstrap_read_hot=always`)|`wiki/hot.md` was injected by the hook — silently absorb the context. Do not announce.|
|Session start (when `bootstrap_read_hot=on-demand` or `never`)|No injection occurred. Wiki skills read `wiki/hot.md` when they activate.|
|Post-compaction (when `bootstrap_read_hot=always`)|Re-read `wiki/hot.md`. Hook-injected context does not survive compaction — this restores it.|
|Pre-query (any mode)|Read `wiki/hot.md` first. If it answers the question, respond without opening other pages. When `bootstrap_read_hot=never`, treat this as a user preference to skip the auto-read unless the task clearly requires wiki context.|

When kept under the 500-word budget, `wiki/hot.md` costs ~500 tokens to read — always cheaper than reading the index or individual pages. The "~2–3k tokens/turn" figure cited elsewhere refers to the per-turn cost of injecting hot.md at every SessionStart and PostCompact when `bootstrap_read_hot=always`; that cost grows further if hot.md drifts past its word budget.

## Auto-Read Gating

`claude-obsidian.bootstrap_read_hot` setting (set via `/plugin manage` or `~/.claude/settings.local.json`):

|Value|Hook behavior|Skill behavior|
|-|-|-|
|`always`|Inject at SessionStart and PostCompact|Read as usual|
|`on-demand` _(default)_|Skip injection|Skills read on activation|
|`never`|Skip injection|User preference: avoid auto-read unless explicit request|

**Why default is `on-demand`:** Injecting every time costs ~2–3k tokens/turn across all sessions. Skills read it on activation anyway.

## When to Update

At end of every content-changing operation. **Orchestrator writes once after all parallel workers report.** Never mid-operation or from worker.

|Operation|Who|When|
|-|-|-|
|Single ingest|Orchestrator|After all pages written|
|Batch ingest|Orchestrator|Once at end|
|Autoresearch|Skill|After all pages filed|
|Save|Skill|After note created|
|Query (filed)|Skill|After answer filed|
|Lint (fixed)|Skill|After report + fixes|
|Session end|Agent|Before close|

Required: update at end of ingest/autoresearch for next-session performance.

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

**Rules:** <500 words. Factual only. Overwrite completely (never append). Wikilinks must match real filenames.

## Parallel Worker Discipline

Parallel workers (Task-tool or TeamCreate) must NOT update `wiki/hot.md`. Orchestrator only, once after all report. Prevents races and conflicts.
