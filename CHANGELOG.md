# Changelog

All notable changes to claude-obsidian are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

The version bump and release entry will be added in a separate change. Until then, the work below ships under the existing `0.3.0` version. When the release lands, this section gets renamed to its semver heading.

### Breaking Changes (planned)

The plugin will talk to Obsidian through the official Obsidian CLI (1.12.7+) instead of the Local REST API + MCP server combination. Vaults must be open in a running Obsidian desktop instance for converted skills to read or write.

This affects every vault-touching skill once its conversion sub-issue lands. Foundation in this PR covers `query` and `save` only; the remaining skills (`ingest`, `lint`, `notes`, `canvas`, `obsidian-bases`, `wiki`, `autoresearch`, `defuddle`) keep their existing direct-file / MCP behaviour and will be migrated in follow-up sub-issues. Mixed-mode coexistence is intentional — you do not need to wait for the full migration.

### Added

- `scripts/obsidian-cli.sh` — wrapper that resolves the vault, derives the vault name (`basename`), pre-flights `obsidian version`, and normalizes exit codes per the contract in `_shared/cli.md`.
- `_shared/cli.md` — invocation contract, exit-code table, format defaults, error patterns, escape-hatch policy, and the documented exception list.
- `scripts/cli-spike.sh` — empirical CLI probe; results pinned in `tests/spike-results/`. Re-run after every Obsidian CLI minor-version bump.
- `tests/cli-smoke.sh` — 15 assertions on wrapper output shape and exit codes against the active vault.
- `tests/fixtures/vault/` — minimal Obsidian vault used by the spike and future skill smoke tests.
- SessionStart hook entry that pre-flights `obsidian version` and emits an actionable warning when Obsidian is missing or stopped (fail-soft — never blocks the session).

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

These came out of `scripts/cli-spike.sh` and are pinned in `_shared/cli.md`:

- The Obsidian CLI **always returns exit 0**, regardless of success or failure. The wrapper detects errors by inspecting the first line of stdout (`Error: ...` or `Vault not found.`).
- `vault=<name>` accepts a vault **name** (basename), not a path. `vault=/some/path` returns `Vault not found.`
- `orphans`, `deadends`, `tasks`, and `properties` do not accept `format=json`; only `backlinks`, `tags`, `unresolved`, `outline`, `search`, `bookmarks`, and `aliases` do. The format-defaults table in `_shared/cli.md` reflects this.
- Multiline `content="line one\nline two"` round-trips cleanly through `create` + `read`. No `source=/tmp/...` fallback is needed for hot-cache rewrites.

### Rollback (post-release)

If a regression blocks your work, pin the previous release:

```bash
/plugin install claude-obsidian@0.3.0
```

The 0.3.0 plugin re-enables the Local REST API + MCP code path. After pinning, you can optionally `pkill -f mcp-obsidian` if a stale MCP server is still running from before the upgrade.
