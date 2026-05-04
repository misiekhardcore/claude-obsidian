# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] — 2026-05-03

### Added

- **E2E harness — CI fast tier.** `Dockerfile` and a GitHub Actions workflow that runs the smoke-test suite on every PR, against a pinned Obsidian image (#92).
- **E2E harness — local full tier.** Entrypoint script, expanded assertions, and a `Makefile` so contributors run the same suite locally that CI runs (#94).
- **Lint check #15** — flags index entries placed under the wrong type heading as misplaced (#87).
- **Backlink-aware traversal** in `/query` and `/lint`, with a density check that surfaces over- and under-linked clusters (#78).
- **`/autoresearch` trail page** recording the argument order of each run, so reruns can be replayed and audited (#93).
- **Initial lint report for wiki metadata validation** — programmatic frontmatter pass that feeds the lint dashboard.

### Changed

- **Unified domain hub architecture.** Wiki content is reorganized around domain hubs instead of ad-hoc category folders; closes the long-standing #46 reorganization. Existing pages were migrated in place (#79).
- **Vault housekeeping** — slug-generation bug fix, lint-report rotation, and seed-onboarding refinements (#83).
- **`/save` index insert** is now section-aware: index updates splice into the correct section instead of prepending to the whole file, which had been disturbing surrounding content (#86).
- **`/daily` capture path** uses atomic CLI verbs (`append` / `prepend`) instead of read-modify-write, eliminating bullet loss when concurrent captures land in the same daily note (#103).
- `_seed/FIRST_RUN.md` no longer references the removed `Wiki Map.canvas` (#88).

### Fixed

- **`/lint` dead-link check** is now deterministic — replaced the inline scan with `lint-scan.sh`, which produces stable output across runs (#102).
- **`commands/` directory registered in the plugin manifest** so slash commands appear in Claude Code's menu without depending on auto-discovery quirks (#99).

[Full diff](https://github.com/misiekhardcore/claude-obsidian/compare/v1.0.0...v1.1.0)

## [1.0.0] — 2026-04-29

Closes the CLI migration epic (#48). With this release, **all** vault I/O across every skill and hook routes through the Obsidian CLI; the Local REST API + MCP code path is gone.

### Breaking Changes

- **Obsidian 1.12.7+ is now a hard prerequisite.** The plugin no longer ships any non-CLI vault-access path. Sessions still start when Obsidian is closed (the SessionStart probe is fail-soft), but skills that touch the vault will error until Obsidian is running with the registered vault open.
- **MCP server `obsidian-vault` is fully removed.** No skill, hook, script, or shared reference still calls `mcp__obsidian-vault__*`. Setup docs no longer mention the Local REST API community plugin, the Tray plugin, or the `NODE_TLS_REJECT_UNAUTHORIZED=0` workaround.
- **For external plugin authors:** the `mcp__obsidian-vault__*` tool surface is gone in 1.0.0. Migrate to the `obsidian` CLI via Bash; see `_shared/cli.md` for the empirical contract (exit codes, output formats, escape-hatch policy) and `skills/wiki/references/cli-setup.md` for end-to-end examples (#53).

### Changed

- `_seed/FIRST_RUN.md` no longer instructs new users to install Local REST API or Tray. Templater remains the only required community plugin; CLI registration is the new third step (#53).
- `_shared/capture-pipeline.md` and `skills/notes/SKILL.md` now use `obsidian properties path=<file>` for frontmatter scans (the `properties` verb has no `format=json` support — fix references the empirical contract in `_shared/cli.md` §3) (#53).
- `skills/wiki/references/cli-setup.md` Examples section is filled with end-to-end snippets for ingest, query, save, and the lint primitives surfaced by the CLI (`orphans`, `deadends`, `unresolved`, `backlinks`) (#53).
- `skills/daily/SKILL.md`, `skills/daily-close/SKILL.md`, `skills/braindump/SKILL.md`, and `skills/obsidian-bases/SKILL.md` now route every vault read and write through the `obsidian` CLI. `Write` and `Edit` are dropped from `allowed-tools`; atomic frontmatter rewrites use `obsidian create overwrite=true`; date-matched activity scans use `obsidian properties path=<file>` per candidate (#53).
- `skills/obsidian-markdown/SKILL.md` `allowed-tools` trimmed to `Read` — this is a reference-text-only skill, never writes vault pages (#53).
- `commands/wiki.md` SCAFFOLD step 3 no longer probes for an MCP server; it now checks vault registration via `obsidian list vaults` (#53).
- `_shared/vault-structure.md` solution-page example renamed from `configure-mcp-server` to `register-vault-with-cli` (#53).
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` bumped to `1.0.0` (#53).
- `README.md` and `CLAUDE.md` skill listings now include `daily-close` (shipped in #69 but missed by both inventories) (#53).

### Added

- `commands/daily-close.md` and `commands/braindump.md` — slash-command stub files for `/daily-close` and `/braindump`. Both skills already advertised those triggers; without the command files they only auto-loaded via skill-description match and didn't appear in Claude Code's slash menu (#53).

### Migration

1. Confirm you are on Obsidian 1.12.7 or newer.
2. If you skipped 0.5.0: register your vault with the CLI once — `obsidian register vault=/absolute/path/to/vault`.
3. Optional cleanup of stale background state from older releases:
   ```bash
   pkill -f mcp-obsidian
   ```
   You can also disable or uninstall the Local REST API community plugin if nothing else on your machine uses it.
4. No vault-side migrations required; existing wiki content is read/written unchanged.

### Rollback

If a regression blocks your work, pin the previous release:

```bash
/plugin install claude-obsidian@0.5.1
```

For a fully MCP-based rollback (no CLI dependency at all), pin `0.4.0`, re-enable the Local REST API community plugin, and follow the legacy `mcp-setup.md` (preserved in git history at the `v0.4.0` tag).

## [0.5.1] — 2026-04-27

### Fixed

- **SessionStart and PostCompact hooks** rewritten from prompt-type to command-type, eliminating the `ToolUseContext` error that fired on every session start under recent Claude Code builds (#58).

[Full diff](https://github.com/misiekhardcore/claude-obsidian/compare/v0.5.0...v0.5.1)

## [0.5.0] — 2026-04-26

### Breaking Changes

`query` and `save` now talk to Obsidian through the official Obsidian CLI (1.12.7+) instead of the Local REST API + MCP server. The vault must be open in a running Obsidian desktop instance for these two skills to read or write (#54).

The remaining vault-touching skills (`ingest`, `lint`, `notes`, `canvas`, `obsidian-bases`, `wiki`, `autoresearch`, `defuddle`) keep their existing direct-file / MCP behaviour and will be migrated in follow-up sub-issues. Mixed-mode coexistence is intentional — you do not need to wait for the full migration.

### Added

- `scripts/obsidian-cli.sh` — wrapper that resolves the vault, derives the vault name (`basename`), pre-flights `obsidian version`, and normalizes exit codes. Contract is documented inline in the script's header comment: exit-code table, error patterns, escape-hatch policy, and the documented exception list (#54).
- `scripts/cli-spike.sh` — empirical CLI probe; results pinned in `tests/spike-results/`. Re-run after every Obsidian CLI minor-version bump (#54).
- `tests/cli-smoke.sh` — 15 assertions on wrapper output shape and exit codes against the active vault (#54).
- `tests/fixtures/vault/` — minimal Obsidian vault used by the spike and future skill smoke tests (#54).
- SessionStart hook entry that pre-flights `obsidian version` and emits an actionable warning when Obsidian is missing or stopped (fail-soft — never blocks the session) (#54).
- `hooks/obsidian-cli-rewrite.sh` — PreToolUse hook (matcher: `Bash`) that transparently rewrites raw `obsidian <verb>` invocations to call `scripts/obsidian-cli.sh` instead. RTK-style transparent rewrite via `hookSpecificOutput.updatedInput.command`. Conservative match: first token must be exactly `obsidian`; commands already mentioning `obsidian-cli` are untouched (#54).

### Changed

- `skills/query/SKILL.md` — vault reads now go through `obsidian-cli.sh read path=...`. `Read` is retained for non-vault resources only. `allowed-tools` adds `Bash` (#54).
- `skills/save/SKILL.md` — vault reads, creates, appends, prepends, and overwrites go through the wrapper. `Write` and `Edit` are no longer in `allowed-tools` (the wrapper covers all vault writes) (#54).
- Trimmed wrapper-usage repetition from `query` and `save` SKILL.md — vault I/O conventions live in `CLAUDE.md` and `_shared/`, the skills no longer duplicate them (#59).
- No new `userConfig` keys; the SessionStart version probe is unconditional and fail-soft (#54).

### Fixed

- SessionEnd reflection hook restored on dash-based `/bin/sh`. The 0.4.0 fix used `nohup … & disown`, but `disown` is a bash builtin and dash aborts the script before the reflection runs. Dropping `disown` keeps the subshell detached enough to avoid SessionEnd cancellation while staying POSIX-compatible (#57).

### Migration

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

### Rollback

If a regression blocks your work, pin the previous release:

```bash
/plugin install claude-obsidian@0.4.0
```

The 0.4.0 plugin re-enables the Local REST API + MCP code path. After pinning, you can optionally `pkill -f mcp-obsidian` if a stale MCP server is still running from before the upgrade.

## [0.4.0] — 2026-04-26

### Added
- `bootstrap_read_hot` config key (`always` | `on-demand` | `never`, default `on-demand`) gates `wiki/hot.md` injection at SessionStart and PostCompact, saving ~2–3k tokens/turn for non-wiki sessions (#43, closes #25).

### Fixed
- SessionEnd reflection hook no longer prints `Hook cancelled`. The synchronous `claude -p` subprocess exceeded Claude Code's exit deadline; the hook now detaches via `nohup … & disown` so it returns instantly while the reflection still writes to the daily note (#56, closes #55).

## [0.3.0] — 2026-04-25

### Added
- `/note` skill for inbox capture and triage: verbatim quick-capture, silent auto-match append on overlap, list and process flows for triaging (#42).
- Demo vault seeded on `/wiki init` so new users see a populated structure on first run (#40, closes #34).
- `wiki-lint` now checks `wiki/hot.md` against the 500-word size budget (#38, closes #24).

### Fixed
- Hooks no longer pass `${user_config.vault_path}` directly; the resolver owns vault path resolution (#37).

## [0.2.0] — 2026-04-24

### Added
- Release workflow in CI (#35).
- Cross-skill documentation extracted into `_shared/` for reuse across skills (#30).
- Scheduled lint nudge and passive vault reflection hooks (#19).
- `/wiki init` wired to `setup-vault.sh` with absolute vault path support and `_templates/` (#18, #15).
- `resolve-vault.sh` helper plus hook rewrite to use `${user_config.vault_path}` for vault path resolution (#14).
- 10 skills, 4 commands, and 2 agents migrated from `claude-config/memory` into the plugin (#12).
- `.claude-plugin` manifests with `userConfig` for vault path (#11).
- README install, skills, and vault structure sections (#28, #23).

### Changed
- `/wiki init` logic refactored into `bin/wiki-init.sh` and `bin/copy-templates.sh` (#20).
- `CLAUDE.md` and `AGENTS.md` rewritten for plugin context (#13).

### Fixed
- `resolve-vault.sh` falls back to `settings.local.json` for out-of-session invocations where `${user_config.*}` is unavailable (#33, #32).
- Hooks pass `vault_path` as an argument to `resolve-vault.sh` (#29).
