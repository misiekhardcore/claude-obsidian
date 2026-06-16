---
name: lint
description: Wiki health check. Orphans, dead links, frontmatter gaps. Generates canvas maps and Bases dashboards.
allowed-tools: Agent Bash Read
---
# lint

Health check after every 10-15 ingests or weekly. Finds orphans, dead links, frontmatter gaps. Ask before auto-fixing; reports to `wiki/meta/lint-report-YYYY-MM-DD.md`.

## Vault I/O

[Instructions on how to interact with the vault](Skill("vault-ops")).

## Scan Scope

Read `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/scan-scope.md` for folders scanned/excluded and valid wikilink target extensions.

## Agent Dispatch

On user trigger (`/lint`, "lint the wiki", "health check"):
1. Run `cd "${VAULT_ROOT}" && pwd` then `CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" bash "${CLAUDE_PLUGIN_ROOT}/scripts/lint-scan.sh"` (produces `wiki/meta/lint-data-YYYY-MM-DD.json`).
2. Dispatch `agents/lint.md` with `vault_path=$VAULT_ROOT` and `scope="full"` (or specific folder). Agent performs all 16 checks, drafts report to `wiki/meta/lint-report-YYYY-MM-DD.md`.
3. Present report path and summary to user.
4. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/prune-lint-reports.sh"` to prune old artifacts.

Main thread does not run checks — agent owns that work.

## Lint Checks

Lint agent runs checks #1, #2, #6–#16 in order (no checks #3–#5). Read `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/checks.md` for each check's source, logic, and auto-fix policy. Checks #1, #2, #7, #10 read from JSON; others use `obsidian` CLI or page reads.

## Manual Review

Monthly or after new domain burst. Cannot be automated without NLP. Check for: stale claims, missing pages (concepts/entities in 3+ pages without own page), missing cross-references.

## Lint Report Format

Create at `wiki/meta/lint-report-YYYY-MM-DD.md`. Include: Summary (pages scanned, issues found, auto-fixed, needs review), sections per check type, anti-patterns (URL-as-wikilink `[[https://...]]` — separate from dead-link count).

## Naming & Style

Read `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/conventions.md` for filename/folder/tag/wikilink conventions and writing-style checks.

## Bases Dashboard & Canvas Map

Read `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/dashboard.md` and `${CLAUDE_PLUGIN_ROOT}/skills/lint/references/canvas-map.md`.

## Before Auto-Fixing

Show report first; ask "Auto-fix or review each?" Safe: missing frontmatter, stubs, wikilinks. Review first: deletions, contradictions, merges, misplaced entries. Never auto-fix #16 (trail integrity).

## After Lint & Report Rotation

If auto-fixes modified pages: update hot.md per `Skill("hot-cache-protocol")`. Prune old artifacts: `bash $CLAUDE_PLUGIN_ROOT/scripts/prune-lint-reports.sh` (keeps 3 most recent).
