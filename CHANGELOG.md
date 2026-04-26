# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
