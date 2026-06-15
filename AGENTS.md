# Agent Architecture

This directory (`agents/`) contains sub-agent definition files dispatched by orchestrator skills for parallelized or specialized work. Agents are loaded via Claude Code's `Agent()` or `Task()` tool.

## Agent Inventory

|File|Dispatched by|Purpose|
|-|-|-|
|`capture.md`|`braindump` skill|Files one atomic chunk as an inbox note|
|`gather.md`|`query` / `daily-close`|Reads files and returns structured summaries|
|`ingest.md`|`ingest` skill|Processes one source into wiki pages|
|`lint.md`|`lint` skill|Runs full wiki health check; produces report|
|`memory-search.md`|orchestrators / `Task`|Answers questions from vault content (read-only)|
|`research-round.md`|`autoresearch`|Searches, fetches, dispatches source-synth agents|
|`source-synth.md`|`research-round`|Synthesizes one source into wiki pages|

## Conventions

- **Frontmatter always includes**: `name`, `description`, `model`, `maxTurns`, `tools`, `disallowedTools`, `background`.
- **`disallowedTools`** must include `Agent` (agents never spawn sub-agents).
- **`background: true`** — agents run silently; orchestrator collects output.
- **`model`** — `haiku` for read-only/search tasks, `sonnet` for synthesis/writing.
- **CWD verification required** — every agent begins with `cd "${VAULT_ROOT}" && pwd`.
- **No cross-cutting state** — agents never update `wiki/hot.md`, `wiki/index.md`, or `wiki/log.md`. That is always the orchestrator's job.
- **Vault I/O** — all vault reads/writes via `obsidian <verb>` through `scripts/obsidian-cli.sh`.

## Reading Agent Files

Agent files are declarative single-responsibility specs. They follow this structure:

1. Frontmatter (configuration)
2. Role/constraint summary
3. CWD verification block
4. Inputs section
5. Process/pipeline description
6. Output format

Do not add procedural boilerplate. Reference `_shared/` files for shared protocols.
