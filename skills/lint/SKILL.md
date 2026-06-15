---
name: lint
description: Wiki health check. Orphans, dead links, frontmatter gaps. Generates canvas maps and Bases dashboards.
when_to_use: Run after every 10-15 ingests or weekly. Routes to agents/lint.md for actual checks.
model: opus
effort: medium
user-invocable: true
allowed-tools: Agent Bash Read
---
Health check for wiki orphans, dead links, frontmatter gaps. Ask before auto-fixing.

## I/O
- Input: Vault root path.
- Output: Report at `wiki/meta/lint-report-YYYY-MM-DD.md`.

## Process
1. **Scan**: `cd "${VAULT_ROOT}" && pwd && bash "${CLAUDE_PLUGIN_ROOT}/scripts/lint-scan.sh"` → produces `wiki/meta/lint-data-YYYY-MM-DD.json`.
2. **Audit**: Dispatch `agents/lint.md` with `vault_path=$VAULT_ROOT` and `scope="full"`. Agent runs 16 checks and drafts report.
3. **Review**: Present report to user. Ask "Auto-fix or review each?" before applying changes.
4. **Rotate**: `bash $CLAUDE_PLUGIN_ROOT/scripts/prune-lint-reports.sh` to keep 3 most recent.

## Rules
- Show report before any auto-fix. Safe to auto: missing frontmatter, stubs, wikilinks. Review first: deletions, contradictions, merges.
- Never auto-fix trail integrity (check #16).
- If auto-fixes modified pages, update hot.md per `_shared/hot-cache-protocol.md`.
- See `references/checks.md` for per-check details, `references/scan-scope.md` for folders, `references/conventions.md` for style rules.
