# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

The version bump and release entry will be added in a separate change. Until then, the work below ships under the existing `0.4.0` version. When the release lands, this section gets renamed to its semver heading.

### Breaking Changes (planned)

The plugin will talk to Obsidian through the official Obsidian CLI (1.12.7+) instead of the Local REST API + MCP server combination. Vaults must be open in a running Obsidian desktop instance for converted skills to read or write.

This affects every vault-touching skill once its conversion sub-issue lands. Foundation in this PR covers `query` and `save` only; the remaining skills (`ingest`, `lint`, `notes`, `canvas`, `obsidian-bases`, `wiki`, `autoresearch`, `defuddle`) keep their existing direct-file / MCP behaviour and will be migrated in follow-up sub-issues. Mixed-mode coexistence is intentional — you do not need to wait for the full migration.

### Added

- `scripts/obsidian-cli.sh` — wrapper that resolves the vault, derives the vault name (`basename`), pre-flights `obsidian version`, and normalizes exit codes. Contract is documented inline in the script's header comment: exit-code table, error patterns, escape-hatch policy, and the documented exception list.
- `scripts/cli-spike.sh` — empirical CLI probe; results pinned in `tests/spike-results/`. Re-run after every Obsidian CLI minor-version bump.
- `tests/cli-smoke.sh` — 15 assertions on wrapper output shape and exit codes against the active vault.
- `tests/fixtures/vault/` — minimal Obsidian vault used by the spike and future skill smoke tests.
- SessionStart hook entry that pre-flights `obsidian version` and emits an actionable warning when Obsidian is missing or stopped (fail-soft — never blocks the session).
- `hooks/obsidian-cli-rewrite.sh` — PreToolUse hook (matcher: `Bash`) that transparently rewrites raw `obsidian <verb>` invocations to call `scripts/obsidian-cli.sh` instead. RTK-style transparent rewrite via `hookSpecificOutput.updatedInput.command`. Conservative match: first token must be exactly `obsidian`; commands already mentioning `obsidian-cli` are untouched.

### Changed

- `skills/query/SKILL.md` — vault reads now go through `obsidian-cli.sh read path=...`. `Read` is retained for non-vault resources only. `allowed-tools` adds `Bash`.
- `skills/save/SKILL.md` — vault reads, creates, appends, prepends, and overwrites go through the wrapper. `Write` and `Edit` are no longer in `allowed-tools` (the wrapper covers all vault writes).
- No new `userConfig` keys; the SessionStart version probe is unconditional and fail-soft.

### Migration (when this lands as 1.0.0)

1. Install Obsidian 1.12.7 or newer.
2. Enable the Obsidian CLI (Settings → Community plugins → Obsidian CLI; or follow the upstream install instructions).
3. Make sure Obsidian is running with your vault open before starting a Claude Code session that uses `query` or `save`. The SessionStart hook prints a warning to stderr if it is not — sessions still continue.
4. No vault-side migrations are required; existing wiki content is read/written unchanged.

### Empirical findings worth knowing

These came out of `scripts/cli-spike.sh` and are pinned in the wrapper / smoke header comments:

- The Obsidian CLI **always returns exit 0**, regardless of success or failure. The wrapper detects errors by inspecting the first line of stdout (`Error: ...` or `Vault not found.`).
- `vault=<name>` accepts a vault **name** (basename), not a path. `vault=/some/path` returns `Vault not found.`
- `orphans`, `deadends`, `tasks`, and `properties` do not accept `format=json`; only `backlinks`, `tags`, `unresolved`, `outline`, `search`, `bookmarks`, and `aliases` do. The format-defaults table in `tests/cli-smoke.sh` reflects this.
- Multiline `content="line one\nline two"` round-trips cleanly through `create` + `read`. No `source=/tmp/...` fallback is needed for hot-cache rewrites.

### Rollback (post-release)

If a regression blocks your work, pin the previous release:

```bash
/plugin install claude-obsidian@0.4.0
```

The 0.4.0 plugin re-enables the Local REST API + MCP code path. After pinning, you can optionally `pkill -f mcp-obsidian` if a stale MCP server is still running from before the upgrade.

## [0.4.0] — 2026-04-26

### Added
- `bootstrap_read_hot` config key (`always` | `on-demand` | `never`, default `on-demand`) gates `wiki/hot.md` injection at SessionStart and PostCompact, saving ~2–3k tokens/turn for non-wiki sessions ([#43], closes [#25]).

### Fixed
- SessionEnd reflection hook no longer prints `Hook cancelled`. The synchronous `claude -p` subprocess exceeded Claude Code's exit deadline; the hook now detaches via `nohup … & disown` so it returns instantly while the reflection still writes to the daily note ([#56], closes [#55]).

## [0.3.0] — 2026-04-25

### Added
- `/note` skill for inbox capture and triage: verbatim quick-capture, silent auto-match append on overlap, list and process flows for triaging ([#42]).
- Demo vault seeded on `/wiki init` so new users see a populated structure on first run ([#40], closes [#34]).
- `wiki-lint` now checks `wiki/hot.md` against the 500-word size budget ([#38], closes [#24]).

### Fixed
- Hooks no longer pass `${user_config.vault_path}` directly; the resolver owns vault path resolution ([#37]).

## [0.2.0] — 2026-04-24

### Added
- Release workflow in CI ([#35]).
- Cross-skill documentation extracted into `_shared/` for reuse across skills ([#30]).
- Scheduled lint nudge and passive vault reflection hooks ([#19]).
- `/wiki init` wired to `setup-vault.sh` with absolute vault path support and `_templates/` ([#18], [#15]).
- `resolve-vault.sh` helper plus hook rewrite to use `${user_config.vault_path}` for vault path resolution ([#14]).
- 10 skills, 4 commands, and 2 agents migrated from `claude-config/memory` into the plugin ([#12]).
- `.claude-plugin` manifests with `userConfig` for vault path ([#11]).
- README install, skills, and vault structure sections ([#28], [#23]).

### Changed
- `/wiki init` logic refactored into `bin/wiki-init.sh` and `bin/copy-templates.sh` ([#20]).
- `CLAUDE.md` and `AGENTS.md` rewritten for plugin context ([#13]).

### Fixed
- `resolve-vault.sh` falls back to `settings.local.json` for out-of-session invocations where `${user_config.*}` is unavailable ([#33], [#32]).
- Hooks pass `vault_path` as an argument to `resolve-vault.sh` ([#29]).

[0.4.0]: https://github.com/misiekhardcore/claude-obsidian/releases/tag/v0.4.0
[0.3.0]: https://github.com/misiekhardcore/claude-obsidian/releases/tag/v0.3.0
[0.2.0]: https://github.com/misiekhardcore/claude-obsidian/releases/tag/v0.2.0

[#11]: https://github.com/misiekhardcore/claude-obsidian/pull/11
[#12]: https://github.com/misiekhardcore/claude-obsidian/pull/12
[#13]: https://github.com/misiekhardcore/claude-obsidian/pull/13
[#14]: https://github.com/misiekhardcore/claude-obsidian/pull/14
[#15]: https://github.com/misiekhardcore/claude-obsidian/pull/15
[#18]: https://github.com/misiekhardcore/claude-obsidian/pull/18
[#19]: https://github.com/misiekhardcore/claude-obsidian/pull/19
[#20]: https://github.com/misiekhardcore/claude-obsidian/pull/20
[#23]: https://github.com/misiekhardcore/claude-obsidian/pull/23
[#24]: https://github.com/misiekhardcore/claude-obsidian/issues/24
[#25]: https://github.com/misiekhardcore/claude-obsidian/issues/25
[#28]: https://github.com/misiekhardcore/claude-obsidian/pull/28
[#29]: https://github.com/misiekhardcore/claude-obsidian/pull/29
[#30]: https://github.com/misiekhardcore/claude-obsidian/pull/30
[#32]: https://github.com/misiekhardcore/claude-obsidian/pull/32
[#33]: https://github.com/misiekhardcore/claude-obsidian/pull/33
[#34]: https://github.com/misiekhardcore/claude-obsidian/issues/34
[#35]: https://github.com/misiekhardcore/claude-obsidian/pull/35
[#37]: https://github.com/misiekhardcore/claude-obsidian/pull/37
[#38]: https://github.com/misiekhardcore/claude-obsidian/pull/38
[#40]: https://github.com/misiekhardcore/claude-obsidian/pull/40
[#42]: https://github.com/misiekhardcore/claude-obsidian/pull/42
[#43]: https://github.com/misiekhardcore/claude-obsidian/pull/43
[#55]: https://github.com/misiekhardcore/claude-obsidian/issues/55
[#56]: https://github.com/misiekhardcore/claude-obsidian/pull/56
