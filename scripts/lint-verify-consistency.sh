#!/usr/bin/env bash
# lint-verify-consistency.sh — verify lint scan determinism.
#
# Runs lint-scan.sh twice against the current vault and compares the JSON hashes
# (excluding scan_date, which intentionally differs).  Exits 0 when hashes match,
# 1 when they diverge, 2 on argument / dependency error.
#
# Use as a CI gate: if the vault is unchanged between the two runs, the hashes
# must be identical.  Divergence indicates non-determinism in lint-scan.sh.
#
# Usage:
#   CLAUDE_PLUGIN_ROOT=/path/to/plugin lint-verify-consistency.sh
#
# Exit codes:
#   0 — consistent (hashes match)
#   1 — divergent (hashes differ)
#   2 — dependency error or CLAUDE_PLUGIN_ROOT unset

set -euo pipefail

if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  echo "lint-verify: CLAUDE_PLUGIN_ROOT is unset" >&2
  exit 2
fi
command -v jq        >/dev/null 2>&1 || { echo "lint-verify: jq required" >&2;        exit 2; }
command -v sha256sum >/dev/null 2>&1 || { echo "lint-verify: sha256sum required" >&2; exit 2; }

SCAN="${CLAUDE_PLUGIN_ROOT}/scripts/lint-scan.sh"
VAULT="$("${CLAUDE_PLUGIN_ROOT}/scripts/resolve-vault.sh")" || {
  echo "lint-verify: could not resolve vault" >&2; exit 2
}
TODAY=$(date +%F)
DATA_PATH="${VAULT}/wiki/meta/lint-data-${TODAY}.json"

TMP1=$(mktemp)
TMP2=$(mktemp)
trap 'rm -f "$TMP1" "$TMP2"' EXIT

echo "lint-verify: run 1..."
CLAUDE_PLUGIN_ROOT="$CLAUDE_PLUGIN_ROOT" bash "$SCAN" >/dev/null
cp "$DATA_PATH" "$TMP1"

echo "lint-verify: run 2..."
CLAUDE_PLUGIN_ROOT="$CLAUDE_PLUGIN_ROOT" bash "$SCAN" >/dev/null
cp "$DATA_PATH" "$TMP2"

HASH1=$(jq -S 'del(.scan_date)' "$TMP1" | sha256sum | cut -d' ' -f1)
HASH2=$(jq -S 'del(.scan_date)' "$TMP2" | sha256sum | cut -d' ' -f1)

echo "run 1: $HASH1"
echo "run 2: $HASH2"

if [ "$HASH1" = "$HASH2" ]; then
  echo "lint-verify: OK — hashes match"
  exit 0
else
  echo "lint-verify: FAIL — hashes diverge" >&2
  echo "diff (excluding scan_date):" >&2
  diff <(jq -S 'del(.scan_date)' "$TMP1") <(jq -S 'del(.scan_date)' "$TMP2") >&2 || true
  exit 1
fi
