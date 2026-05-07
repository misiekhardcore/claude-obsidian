# claude-obsidian

Agent + user instructions for the claude-obsidian plugin. `AGENTS.md` is a symlink to this file.

## Vault Assumptions

This vault is designed for **agent-only** use with **single-user, single-machine** access patterns. Any feature proposal violating one of these assumptions must be challenged before implementation:

- **Agent-only readers/writers.** No multi-user tiering, reviewer workflow, access control, or `reviewed_at` timestamps. Every write is an agent or the single human owner; human review happens via git, not via in-vault metadata.
- **Single-user, single-machine by default.** Cross-project access is opt-in per-project, not a multi-tenant design target.
- **Git-backed, file-per-page.** No database, no server, no live sync. All coordination is via commit history.

## Plugin Setup

1. Set `claude-obsidian.vault_path` (or Claude checks CWD for `wiki/` folder).
2. Run `/wiki init` to bootstrap vault structure.

## Vault Structure

```text
wiki/              Knowledge base (hot.md, index.md, concepts/, entities/, sources/)
notes/             Inbox: pending + deferred notes (notes/index.md)
daily/             Daily logs: YYYY-MM-DD.md with ## Captures bullets
.raw/              Immutable source documents + .manifest.json
_templates/        Obsidian Templater templates
_attachments/      Images and PDFs
```

## Wiki Conventions

- **Vault root:** `${vault_path}` (contains `wiki/` and `.raw/`)
- **Hot cache:** `wiki/hot.md` (~500 words, read at session start, written at session end)
- **Index:** `wiki/index.md` (master registry with categories)
- **Categories:** `wiki/concepts/`, `wiki/entities/`, `wiki/sources/`
- **Source documents:** `.raw/` (immutable; agents never modify)
- **Manifest:** `.raw/.manifest.json` (delta tracking for ingested sources)

## Vault I/O
All vault reads and writes go through **Obsidian CLI**, not `Read`/`Write`/`Edit`. A PreToolUse Bash hook routes raw `obsidian <verb> ...` calls through `scripts/obsidian-cli.sh` (resolve vault, preflight, normalize exit codes).
- **Technical Patterns**: See `_shared/vault-ops.md` for CLI patterns, slugging, and indexing.

```bash
obsidian read path=wiki/hot.md
obsidian create path=wiki/concepts/foo.md content="..."
obsidian append file=wiki/log.md content="..."
obsidian prepend file=wiki/index.md content="..."
```
`Read` allowed only outside vault (skill refs, external paths). `Write`/`Edit` not used for vault paths.

## Skills Discovery

All skills live in `skills/<name>/SKILL.md` and are auto-discovered by Claude Code via the plugin manifest.

## Available Skills

|Skill|Trigger phrases|
|-|-|
|`wiki`|`/wiki`, set up wiki, scaffold vault, check setup|
|`ingest`|ingest, ingest this url, ingest this image, batch ingest|
|`query`|query, what do you know about, query quick:, query deep:|
|`lint`|lint the wiki, health check, find orphans, dead links|
|`save`|`/save`, file this conversation, save insight|
|`notes`|`/note`, `/dump`, note this, todo:, show my inbox, `/note process`|
|`daily`|`/daily`, daily note this, log to today, log this, add to today's log|
|`daily-close`|`/daily-close`, close today, wrap up today, synthesize today|
|`braindump`|`/braindump`, brain dump this, dump the following thoughts, dump these thoughts, braindump:, split this into notes|
|`autoresearch`|autoresearch, autonomous research loop|
|`canvas`|`/canvas`, add to canvas, create canvas|
|`defuddle`|clean this url, defuddle, strip clutter|
|`obsidian-markdown`|obsidian syntax, wikilink, callout, embed|
|`obsidian-bases`|obsidian bases, .base file, dynamic table|

## Bootstrap

1. On first invocation: read CLAUDE.md + `skills/wiki/SKILL.md`.
2. Hot cache auto-read: `bootstrap_read_hot` (default: `on-demand`):
   - `always`: injected at SessionStart; absorb silently.
   - `on-demand`: skills read when active (saves ~2–3k tokens for non-wiki sessions).
   - `never`: user preference, avoid loading unless explicitly requested.
3. On `/wiki` or "set up wiki": follow wiki skill scaffold workflow.

## Orchestration via Sub-Agents

Skills dispatch sub-agents to parallelize heavy lifting and avoid context bloat:

- **`ingest`** → `agents/ingest.md` (one per source; writes wiki pages/index)
- **`braindump`** → `agents/capture.md` (parallel when independent; sequential when order matters)
- **`lint`** → `agents/lint.md` (runs all 16 checks; drafts report)
- **`autoresearch`** → `agents/research-round.md` + `agents/source-synth.md` (search/fetch/synthesis)
- **`query`** → `agents/gather.md` (parallel page reads when list > 5 pages)

Orchestrators verify CWD before spawning: `cd "${VAULT_ROOT}" && pwd`. Agents write wiki state; orchestrators coalesce results and update cross-cutting state (index, log). **Parallel agents never update `wiki/hot.md`** — only the orchestrator does (see `_shared/hot-cache-protocol.md`).

## Ingest Rules

Single-source ingests require interactive discussion (what to emphasize, granularity, existing context to link). Escape: "just ingest it" or "auto-ingest". Exempt: `/autoresearch` (intentionally autonomous).

## CLI Setup
Vault I/O via **Obsidian CLI** (shipped with 1.12.7+). See `_shared/setup.md` for installation and registration.

## Documentation Standards
All skill and reference docs must follow a **content-dense, declarative structure**:
- **No procedural lists**: Replace "Step 1... Step 2..." with a "Cycle" or "Pipeline" specification.
- **No redundant I/O**: Reference `_shared/vault-ops.md` instead of explaining CLI syntax.
- **Topical centralization**: Consolidate fragmented `references/` folders into `_shared/`.
- **Declarative logic**: Focus on *what* the outcome is and *which* shared pattern to use, not *how* the tool works.

## Cross-Project Access

Add to other projects' CLAUDE.md:
```markdown
## Wiki Knowledge Base
Path: /path/to/vault
When needed: (1) read wiki/hot.md first, (2) read wiki/index.md, (3) drill into domain pages.
Do NOT read for general coding questions.
```
