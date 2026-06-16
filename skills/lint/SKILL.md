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
1. **Scan**: `cd "${VAULT_ROOT}" && pwd && bash "${CLAUDE_PLUGIN_ROOT}/scripts/lint-scan.sh"` → produces `wiki/meta/lint-data-YYYY-MM-DD.json`. Scope per `${CLAUDE_PLUGIN_ROOT}/_shared/lint-scan-scope.md`.
2. **Audit**: Dispatch `agents/lint.md` with `vault_path=$VAULT_ROOT` and `scope="full"`. Agent runs 16 checks (#1–#2, #6–#16) per `${CLAUDE_PLUGIN_ROOT}/_shared/lint-checks.md` and drafts report.
3. **Review**: Present report (summary + per-section findings) to user. Ask "Auto-fix or review each?" before applying changes.
4. **Rotate**: `bash $CLAUDE_PLUGIN_ROOT/scripts/prune-lint-reports.sh` to keep 3 most recent.
5. **Maintain**: If auto-fixes modified pages, update `wiki/hot.md` per `_shared/hot-cache-protocol.md`.

## Rules
- Show report before any auto-fix. Safe to auto: checks #1, #2, #6, #9, #10. Review first: deletions, contradictions, merges. Never auto-fix trail integrity (#16).
- If auto-fixes modified pages, update hot.md.
- See `${CLAUDE_PLUGIN_ROOT}/_shared/lint-checks.md` for per-check detail + auto-fix policy, `${CLAUDE_PLUGIN_ROOT}/_shared/lint-scan-scope.md` for scanned/excluded folders, `${CLAUDE_PLUGIN_ROOT}/_shared/lint-conventions.md` for style rules.
