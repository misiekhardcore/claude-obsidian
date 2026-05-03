#!/usr/bin/env bash
# prune-lint-reports.sh — keep the most recent N lint artifacts in wiki/meta/.
#
# Each lint run writes two files:
#   wiki/meta/lint-report-YYYY-MM-DD.md   — human-readable report
#   wiki/meta/lint-data-YYYY-MM-DD.json   — canonical machine-readable data
#
# Old artifacts accumulate, clutter wiki/meta/, and inflate git diffs even
# though they're advisory: the dashboard already carries the latest summary and
# each new report subsumes the previous findings. This script prunes everything
# beyond the top KEEP artifacts by ISO date (same KEEP applied to both types).
#
# Usage:
#   prune-lint-reports.sh            # default keep=3
#   prune-lint-reports.sh 5          # keep most-recent 5
#
# Env:
#   CLAUDE_PLUGIN_ROOT — required; resolves the obsidian CLI wrapper.
#
# Exit codes:
#   0 — pruned (or nothing to prune)
#   1 — obsidian CLI error
#   2 — argument error or missing CLAUDE_PLUGIN_ROOT

set -euo pipefail

KEEP="${1:-3}"

if ! [[ "$KEEP" =~ ^[0-9]+$ ]] || [ "$KEEP" -lt 1 ]; then
  echo "prune-lint-reports: <keep> must be a positive integer (got '$KEEP')" >&2
  exit 2
fi

if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  echo "prune-lint-reports: CLAUDE_PLUGIN_ROOT is unset" >&2
  exit 2
fi

CLI="${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh"
SKIP=$((KEEP + 1))

prune_pattern() {
  local pattern="$1"
  # ISO-8601 dates sort lexically; sort -r puts newest first; tail -n +SKIP
  # emits everything past the top KEEP.
  "$CLI" files dir=wiki/meta format=json \
    | jq -r --arg pat "$pattern" '.[] | select(.path | test($pat)) | .path' \
    | sort -r \
    | tail -n "+$SKIP" \
    | while read -r stale; do
        "$CLI" delete path="$stale"
      done
}

prune_pattern '^wiki/meta/lint-report-[0-9]{4}-[0-9]{2}-[0-9]{2}\\.md$'
prune_pattern '^wiki/meta/lint-data-[0-9]{4}-[0-9]{2}-[0-9]{2}\\.json$'
