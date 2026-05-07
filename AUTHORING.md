# Authoring Guide

## Directory Layout

```text
_shared/          Cross-skill reference docs
scripts/          Utility scripts (obsidian-cli.sh, resolve-vault.sh)
skills/<name>/    One skill per dir (SKILL.md entrypoint + references/)
agents/           Sub-agent definitions
commands/         Slash-command shims
hooks/            Claude Code hooks (hooks.json + .sh)
_templates/       Templater templates + authoring guidance
```

## `_shared/` Promotion Rubric

Promote a doc to `_shared/` when **≥3 skills** reference it. Otherwise keep under `skills/<name>/references/`.

**Current shared docs:**
- `vault-structure.md` — conventions, tagging, relationships
- `frontmatter.md` — YAML schema, status/confidence values
- `hot-cache-protocol.md` — hot-cache read/write, parallel worker discipline
- `cli.md` — Obsidian CLI contract (exit codes, patterns, escape hatches)
- `capture-pipeline.md` — vault I/O contract, MATCH/NEW heuristic, image handling
- `image-capture.md` — image validation, move, embed, frontmatter (shared across note/daily/braindump)

## Vault Operations: CLI Wrapper

All vault I/O via `scripts/obsidian-cli.sh`:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh" read path=wiki/hot.md
"${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh" create path=wiki/concepts/foo.md content="..."
"${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh" append path=wiki/index.md content="- New entry"
```

PreToolUse hook transparently rewrites raw `obsidian <verb> ...` calls. For error handling, exit codes, and escape hatches, see `_shared/cli.md`.

## Referencing `_shared/`

Use `${CLAUDE_PLUGIN_ROOT}/_shared/<file>` (runtime resolved). Read on-demand, not preloaded.

Do not promote docs specific to one skill's operation, even if long.

## Skill & Command Frontmatter

| Field | Notes |
|-------|-------|
| `name` | Required. Must match the directory name for skills. |
| `description` | **≤150 chars.** Shown in `/` menu and used for harness routing. |
| `when_to_use` | Optional routing hint shown alongside `description`. Combined `description` + `when_to_use` must be **≤1,536 chars**. Use when routing context would push description over 150 chars. |
| `allowed-tools` | Space-separated allowlist active while skill is running. Skills that dispatch sub-agents **must include `Agent`**. Vault ops go through `obsidian` CLI (Bash) — do not list `Read`, `Write`, `Glob`, or `Grep` unless the skill calls those tools directly outside the vault. |
| `effort` | `low`\|`medium`\|`high`\|`xhigh`\|`max` — effort level override. |
| `argument-hint` | Shown in autocomplete (e.g. `[topic]`). Add to any command that takes an argument. |
| `context` | Accepted value: `fork`. Runs the skill in an isolated subagent instead of inline. |
| `agent` | Used with `context: fork`. Names the agent type to dispatch (e.g., `claude-obsidian:ingest`). |
| `model` | `sonnet`, `opus`, `haiku`, or full model ID. |
| `user-invocable` | `false` hides skill from `/` menu (orchestrator-only skills). |

## Agent Frontmatter

Agents use **`tools`** (allowlist), not `allowed-tools` — using the wrong key is a **silent no-op**.

| Field | Notes |
|-------|-------|
| `tools` | Space-separated allowlist. |
| `disallowedTools` | Space-separated denylist. Defense-in-depth beyond the `tools` allowlist. |
| `maxTurns` | Max agentic turns. |
| `model` | Same aliases as skills. |

**Plugin security restrictions:** `permissionMode`, `hooks`, and `mcpServers` are **silently ignored** for plugin agents — do not set them.

## Sub-Agents vs. Inline

**Inline:** single item, order matters, fits in orchestrator.
**Sub-agents:** multiple independent items, parallelizable, avoids context bloat.

**Orchestrator:** verify CWD (`cd "${VAULT_ROOT}" && pwd`), collect reports, update index/log/hot.md once (never per-agent), never write vault state in parallel.

See agents/ for patterns: `capture` (single note), `ingest` (single source), `lint` (vault scan), `gather` (page cluster).
